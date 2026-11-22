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
    // PNG não é UTF-8 válido: ler como texto levantava EEncodingError e a assinatura nunca chegava
    [Test]
    procedure CorpoComoTexto_Png_NaoLevantaEFicaVazio;
    [Test]
    procedure CorpoComoTexto_JsonUtf8_Decodifica;
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

procedure TTestHttp.CorpoComoTexto_Png_NaoLevantaEFicaVazio;
const
  PNG: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(PNG));
  Move(PNG[0], LBytes[0], Length(PNG));
  Assert.AreEqual('', CorpoComoTexto(LBytes, 'image/png'));
end;

procedure TTestHttp.CorpoComoTexto_JsonUtf8_Decodifica;
begin
  Assert.AreEqual('{"erro":"Pedido não encontrado."}',
    CorpoComoTexto(TEncoding.UTF8.GetBytes('{"erro":"Pedido não encontrado."}'), 'application/json; charset=utf-8'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestHttp);

end.
