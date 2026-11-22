unit Api.Auth;

interface

uses
  Infra.Http, Model.Sessao;

type
  IAuthApi = interface
    ['{5A1E9C37-6B2D-4E80-9F3A-C7D4B2E1F068}']
    function Login(const AUrlBase, ALogin, ASenha: string): TTokenAcesso;
  end;

  // não herda TApiBase: o login acontece antes de existir sessão (e um 401 aqui não pede relogin)
  TAuthApi = class(TInterfacedObject, IAuthApi)
  private
    FHttp: IHttpClient;
  public
    constructor Create(AHttp: IHttpClient);
    function Login(const AUrlBase, ALogin, ASenha: string): TTokenAcesso;
  end;

implementation

uses
  System.SysUtils, System.JSON, Infra.Json, Api.Base;

constructor TAuthApi.Create(AHttp: IHttpClient);
begin
  inherited Create;
  FHttp := AHttp;
end;

function TAuthApi.Login(const AUrlBase, ALogin, ASenha: string): TTokenAcesso;
var
  LCorpo, LJson: TJSONObject;
  LResposta: THttpResposta;
begin
  LCorpo := TJSONObject.Create;
  try
    LCorpo.AddPair('login', ALogin).AddPair('senha', ASenha);
    LResposta := FHttp.Executar(THttpMetodo.Post, AUrlBase + '/auth/login', LCorpo.ToJSON, '');
  finally
    LCorpo.Free;
  end;
  TApiBase.VerificarResposta(LResposta);

  LJson := TJSONObject.ParseJSONValue(LResposta.Corpo) as TJSONObject;
  try
    Result.Token := LerTexto(LJson, 'token');
    Result.ExpiraEm := LerDataHora(LJson, 'expiraEm');
  finally
    LJson.Free;
  end;
end;

end.
