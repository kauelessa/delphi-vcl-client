unit Test.Dpapi;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestDpapi = class
  public
    [Test]
    procedure ProtegerEDesproteger_IdaEVolta;
    [Test]
    procedure Proteger_NaoGuardaTextoPuro;
    [Test]
    procedure Desproteger_Lixo_DevolveVazio;
    [Test]
    procedure ProtegerEDesproteger_Acentos;
  end;

implementation

uses
  System.SysUtils, Infra.Dpapi;

procedure TTestDpapi.ProtegerEDesproteger_IdaEVolta;
begin
  Assert.AreEqual('admin123', Desproteger(Proteger('admin123')));
end;

procedure TTestDpapi.Proteger_NaoGuardaTextoPuro;
var
  LCifrado: string;
begin
  LCifrado := Proteger('admin123');
  Assert.AreNotEqual('admin123', LCifrado);
  Assert.DoesNotContain(LCifrado, 'admin123');
end;

procedure TTestDpapi.Desproteger_Lixo_DevolveVazio;
begin
  Assert.AreEqual('', Desproteger('lixo-que-nao-e-base64'));
  Assert.AreEqual('', Desproteger(''));
end;

procedure TTestDpapi.ProtegerEDesproteger_Acentos;
begin
  Assert.AreEqual('Senha@Ção1', Desproteger(Proteger('Senha@Ção1')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDpapi);

end.
