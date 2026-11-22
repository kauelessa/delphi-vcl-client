unit Test.Http;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestHttp = class
  public
    // API fora do ar: precisa virar EApiIndisponivel com mensagem amigável, não erro de rede cru
    [Test]
    procedure Executar_ServidorInacessivel_LevantaApiIndisponivel;
  end;

implementation

uses
  System.SysUtils, Infra.Http, Infra.Excecoes;

procedure TTestHttp.Executar_ServidorInacessivel_LevantaApiIndisponivel;
var
  LCliente: IHttpClient;
begin
  LCliente := TNetHttpClientAdapter.Create(2000, nil);
  Assert.WillRaiseWithMessage(
    procedure
    begin
      LCliente.Executar(THttpMetodo.Get, 'http://127.0.0.1:1/health', '', '');
    end,
    EApiIndisponivel,
    'Não foi possível falar com a API. Confira se ela está no ar e o endereço do perfil.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestHttp);

end.
