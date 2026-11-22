unit Infra.Http;

{
  Única unit do cliente que fala HTTP. Envia e recebe JSON em UTF-8, anexa o
  token no cabeçalho Authorization e registra cada chamada no log HTTP.

  Status de erro (4xx/5xx) não levanta exceção aqui: quem sabe o que cada
  status significa é a camada Api (Api.Base). Aqui só vira exceção a falta de
  resposta (servidor fora do ar, timeout, DNS), como EApiIndisponivel.
}

interface

uses
  System.SysUtils, Infra.LogHttp;

type
  {$SCOPEDENUMS ON}
  THttpMetodo = (Get, Post, Put, Patch, Delete);
  {$SCOPEDENUMS OFF}

  THttpResposta = record
    Status: Integer;
    Corpo: string;          // Bytes lidos como UTF-8
    Bytes: TBytes;          // corpo cru (imagens)
    TipoConteudo: string;   // Content-Type da resposta
  end;

  IHttpClient = interface
    ['{2C6A9E41-7B3D-4F05-A8D2-5E1F0B7C9D84}']
    /// AToken vazio = sem cabeçalho Authorization. ACorpo vazio = sem corpo.
    function Executar(AMetodo: THttpMetodo; const AUrl, ACorpo, AToken: string): THttpResposta;
  end;

  TNetHttpClientAdapter = class(TInterfacedObject, IHttpClient)
  private
    FTimeoutMs: Integer;
    FLogHttp: ILogHttp;
  public
    constructor Create(ATimeoutMs: Integer; ALogHttp: ILogHttp);
    function Executar(AMetodo: THttpMetodo; const AUrl, ACorpo, AToken: string): THttpResposta;
  end;

/// Corpo como texto UTF-8 quando é JSON/texto (ou sem tipo); binário (PNG...) fica ''.
function CorpoComoTexto(const ABytes: TBytes; const ATipo: string): string;

const
  NOMES_METODO: array[THttpMetodo] of string = ('GET', 'POST', 'PUT', 'PATCH', 'DELETE');

implementation

uses
  System.Classes, System.Diagnostics, System.Net.HttpClient,
  System.Net.URLClient, System.NetConsts, Infra.Excecoes;

const
  MSG_INDISPONIVEL = 'Não foi possível falar com a API. Confira se ela está no ar e o endereço do perfil.';

function CorpoComoTexto(const ABytes: TBytes; const ATipo: string): string;
begin
  Result := '';
  if (ATipo <> '') and not ATipo.Contains('json') and not ATipo.StartsWith('text') then
    Exit;
  try
    Result := TEncoding.UTF8.GetString(ABytes);
  except
    on EEncodingError do
      Result := ''; // o TEncoding.UTF8 do Delphi levanta exceção em byte inválido
  end;
end;

// PNG no log só atrapalha: imagem vira "<N bytes, image/png>"
function CorpoParaLog(const AResposta: THttpResposta): string;
begin
  if (AResposta.Corpo = '') and (Length(AResposta.Bytes) > 0) then
    Result := Format('<%d bytes, %s>', [Length(AResposta.Bytes), AResposta.TipoConteudo])
  else
    Result := AResposta.Corpo;
end;

constructor TNetHttpClientAdapter.Create(ATimeoutMs: Integer; ALogHttp: ILogHttp);
begin
  inherited Create;
  FTimeoutMs := ATimeoutMs;
  FLogHttp := ALogHttp;
end;

function TNetHttpClientAdapter.Executar(AMetodo: THttpMetodo; const AUrl, ACorpo,
  AToken: string): THttpResposta;
var
  LHttp: THTTPClient;
  LCorpo: TStringStream;
  LResposta: IHTTPResponse;
  LCabecalhos: TNetHeaders;
  LTempo: TStopwatch;
  LStream: TStream;
begin
  // um THTTPClient por chamada: as chamadas rodam em threads diferentes
  LHttp := THTTPClient.Create;
  LCorpo := nil;
  try
    LHttp.ConnectionTimeout := FTimeoutMs;
    LHttp.ResponseTimeout := FTimeoutMs;
    LHttp.Accept := 'application/json';
    LHttp.ContentType := 'application/json; charset=utf-8';
    if AToken <> '' then
      LCabecalhos := [TNetHeader.Create('Authorization', 'Bearer ' + AToken)];
    if ACorpo <> '' then
      LCorpo := TStringStream.Create(ACorpo, TEncoding.UTF8);

    LTempo := TStopwatch.StartNew;
    try
      case AMetodo of
        THttpMetodo.Get:    LResposta := LHttp.Get(AUrl, nil, LCabecalhos);
        THttpMetodo.Post:   LResposta := LHttp.Post(AUrl, LCorpo, nil, LCabecalhos);
        THttpMetodo.Put:    LResposta := LHttp.Put(AUrl, LCorpo, nil, LCabecalhos);
        THttpMetodo.Patch:  LResposta := LHttp.Patch(AUrl, LCorpo, nil, LCabecalhos);
        THttpMetodo.Delete: LResposta := LHttp.Delete(AUrl, nil, LCabecalhos);
      end;
    except
      on E: ENetException do
      begin
        if FLogHttp <> nil then
          FLogHttp.Registrar(NOMES_METODO[AMetodo], AUrl, 0, LTempo.ElapsedMilliseconds, ACorpo,
            E.ClassName + ': ' + E.Message);
        raise EApiIndisponivel.Create(MSG_INDISPONIVEL);
      end;
    end;

    Result.Status := LResposta.StatusCode;
    Result.TipoConteudo := LResposta.HeaderValue['Content-Type'];
    LStream := LResposta.ContentStream;
    LStream.Position := 0;
    SetLength(Result.Bytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(Result.Bytes[0], LStream.Size);
    Result.Corpo := CorpoComoTexto(Result.Bytes, Result.TipoConteudo);
    if FLogHttp <> nil then
      FLogHttp.Registrar(NOMES_METODO[AMetodo], AUrl, Result.Status, LTempo.ElapsedMilliseconds,
        ACorpo, CorpoParaLog(Result));
  finally
    LCorpo.Free;
    LHttp.Free;
  end;
end;

end.
