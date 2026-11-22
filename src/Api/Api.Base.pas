unit Api.Base;

{
  Base das classes Api.*: monta a URL a partir do perfil da sessão, anexa o
  token e traduz o status HTTP + o campo "erro" do JSON da API em exceções de
  Infra.Excecoes, que as telas sabem mostrar.

  Token expirado (401): pede à sessão um novo login (Relogar) e repete a
  chamada UMA vez. Se o relogin for cancelado, ou a API devolver 401 de novo,
  a exceção sobe normalmente.
}

interface

uses
  System.SysUtils, System.JSON, Infra.Http, Model.Pagina;

type
  ISessaoApi = interface
    ['{8D2F6B10-3C4E-4A9B-B1E7-6F0A2D5C8E93}']
    function UrlBase: string;
    function Token: string;
    /// Pede a senha de novo e renova o token. False = usuário cancelou.
    function Relogar: Boolean;
  end;

  TApiBase = class(TInterfacedObject)
  private
    FHttp: IHttpClient;
    FSessao: ISessaoApi;
  protected
    /// Devolve o corpo da resposta 2xx; demais status viram exceção.
    function Enviar(AMetodo: THttpMetodo; const ARota: string; const ACorpo: string = ''): string;
    /// Como Enviar, mas devolve o corpo cru (imagens).
    function EnviarBinario(AMetodo: THttpMetodo; const ARota: string): TBytes;
    /// Converte { dados, pagina, limite, total } usando AConverter para cada item de "dados".
    function LerPagina<T: class>(const AJson: string; const AConverter: TFunc<TJSONObject, T>): TPagina<T>;
    /// Rota de listagem: "/recurso?pagina=1&limite=20" + "&<nome>=<valor>" quando o valor não é vazio.
    function RotaPaginada(const ARecurso: string; APagina, ALimite: Integer;
      const AParametro: string = ''; const AValor: string = ''): string;
    property Http: IHttpClient read FHttp;
    property Sessao: ISessaoApi read FSessao;
  public
    constructor Create(AHttp: IHttpClient; ASessao: ISessaoApi);
    class procedure VerificarResposta(const AResposta: THttpResposta); static;
    /// Codifica um valor de parâmetro de URL (RFC 3986): só A-Z a-z 0-9 - _ . ~ passam direto.
    class function ParametroUrl(const AValor: string): string; static;
  end;

implementation

uses
  Infra.Json, Infra.Excecoes;

constructor TApiBase.Create(AHttp: IHttpClient; ASessao: ISessaoApi);
begin
  inherited Create;
  FHttp := AHttp;
  FSessao := ASessao;
end;

function MensagemDeErro(const AResposta: THttpResposta): string;
var
  LJson: TJSONValue;
begin
  Result := '';
  LJson := TJSONObject.ParseJSONValue(AResposta.Corpo);
  try
    if LJson is TJSONObject then
      TJSONObject(LJson).TryGetValue<string>('erro', Result);
  finally
    LJson.Free;
  end;
  if Result.Trim.IsEmpty then
    Result := Format('A API respondeu HTTP %d sem detalhes.', [AResposta.Status]);
end;

class procedure TApiBase.VerificarResposta(const AResposta: THttpResposta);
begin
  case AResposta.Status of
    200..299:
      Exit;
    // 409: regra de negócio contra o estado atual (ex.: pedido faturado não pode ser cancelado)
    400, 409, 422:
      raise EApiValidacao.Create(MensagemDeErro(AResposta), AResposta.Status);
    401:
      raise EApiNaoAutorizado.Create(MensagemDeErro(AResposta), AResposta.Status);
    404:
      raise EApiNaoEncontrado.Create(MensagemDeErro(AResposta), AResposta.Status);
  else
    // 500 e companhia: o detalhe técnico fica no log da API, não na tela
    raise EApiIndisponivel.Create(Format('A API encontrou um erro inesperado (HTTP %d). ' +
      'Tente novamente; se persistir, veja o log da API.', [AResposta.Status]), AResposta.Status);
  end;
end;

class function TApiBase.ParametroUrl(const AValor: string): string;
var
  LByte: Byte;
begin
  Result := '';
  for LByte in TEncoding.UTF8.GetBytes(AValor) do
    if CharInSet(Char(LByte), ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~']) then
      Result := Result + Char(LByte)
    else
      Result := Result + '%' + IntToHex(LByte, 2);
end;

function TApiBase.RotaPaginada(const ARecurso: string; APagina, ALimite: Integer;
  const AParametro, AValor: string): string;
begin
  Result := Format('%s?pagina=%d&limite=%d', [ARecurso, APagina, ALimite]);
  if (AParametro <> '') and (AValor.Trim <> '') then
    Result := Result + '&' + AParametro + '=' + ParametroUrl(AValor.Trim);
end;

function TApiBase.LerPagina<T>(const AJson: string; const AConverter: TFunc<TJSONObject, T>): TPagina<T>;
var
  LJson: TJSONObject;
  LDados: TJSONArray;
  LItem: TJSONValue;
begin
  Result := TPagina<T>.Create;
  try
    LJson := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
    try
      Result.Pagina := LerInteiro(LJson, 'pagina');
      Result.Limite := LerInteiro(LJson, 'limite');
      Result.Total := LerInteiro(LJson, 'total');
      if LJson.TryGetValue<TJSONArray>('dados', LDados) then
        for LItem in LDados do
          Result.Dados.Add(AConverter(LItem as TJSONObject));
    finally
      LJson.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TApiBase.Enviar(AMetodo: THttpMetodo; const ARota, ACorpo: string): string;
var
  LResposta: THttpResposta;
begin
  LResposta := FHttp.Executar(AMetodo, FSessao.UrlBase + ARota, ACorpo, FSessao.Token);
  if (LResposta.Status = 401) and FSessao.Relogar then
    LResposta := FHttp.Executar(AMetodo, FSessao.UrlBase + ARota, ACorpo, FSessao.Token);
  VerificarResposta(LResposta);
  Result := LResposta.Corpo;
end;

function TApiBase.EnviarBinario(AMetodo: THttpMetodo; const ARota: string): TBytes;
var
  LResposta: THttpResposta;
begin
  LResposta := FHttp.Executar(AMetodo, FSessao.UrlBase + ARota, '', FSessao.Token);
  if (LResposta.Status = 401) and FSessao.Relogar then
    LResposta := FHttp.Executar(AMetodo, FSessao.UrlBase + ARota, '', FSessao.Token);
  VerificarResposta(LResposta);
  Result := LResposta.Bytes;
end;

end.
