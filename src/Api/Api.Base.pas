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
  Infra.Http;

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
    property Http: IHttpClient read FHttp;
    property Sessao: ISessaoApi read FSessao;
  public
    constructor Create(AHttp: IHttpClient; ASessao: ISessaoApi);
    class procedure VerificarResposta(const AResposta: THttpResposta); static;
  end;

implementation

uses
  System.SysUtils, System.JSON, Infra.Excecoes;

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
    400, 422:
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

end.
