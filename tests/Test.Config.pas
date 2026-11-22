unit Test.Config;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestConfig = class
  private
    FPasta: string;
    function CriarIni(const AConteudo: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Carrega_PerfisETimeout;
    [Test]
    procedure SemArquivo_UsaPadroes;
    [Test]
    procedure PerfilPorNome_Inexistente_DevolvePrimeiro;
    [Test]
    procedure LimparLogsAntigos_ApagaSoOsVencidos;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.DateUtils, Infra.Config, Infra.Log;

procedure TTestConfig.Setup;
begin
  FPasta := TPath.Combine(TPath.GetTempPath, 'vclclient-config-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FPasta);
end;

procedure TTestConfig.TearDown;
begin
  if TDirectory.Exists(FPasta) then
    TDirectory.Delete(FPasta, True);
end;

function TTestConfig.CriarIni(const AConteudo: string): string;
begin
  Result := TPath.Combine(FPasta, 'config.ini');
  TFile.WriteAllText(Result, AConteudo, TEncoding.UTF8);
end;

procedure TTestConfig.Carrega_PerfisETimeout;
var
  LConfig: TConfig;
begin
  LConfig := TConfig.Create(CriarIni(
    '[Api]'#13#10'Perfis=Local,Servidor'#13#10'TimeoutSegundos=15'#13#10 +
    '[Perfil.Local]'#13#10'Url=http://localhost:9000'#13#10 +
    '[Perfil.Servidor]'#13#10'Url=http://servidor.exemplo.com.br:9000'#13#10 +
    '[Log]'#13#10'Http=0'#13#10'RetencaoDias=10'#13#10));
  try
    Assert.AreEqual(2, Length(LConfig.Perfis));
    Assert.AreEqual('Servidor', LConfig.Perfis[1].Nome);
    Assert.AreEqual('http://servidor.exemplo.com.br:9000', LConfig.Perfis[1].Url);
    Assert.AreEqual(15000, LConfig.TimeoutMs);
    Assert.IsFalse(LConfig.LogHttp);
    Assert.AreEqual(10, LConfig.RetencaoLogDias);
  finally
    LConfig.Free;
  end;
end;

procedure TTestConfig.SemArquivo_UsaPadroes;
var
  LConfig: TConfig;
begin
  LConfig := TConfig.Create(TPath.Combine(FPasta, 'nao-existe.ini'));
  try
    Assert.AreEqual(1, Length(LConfig.Perfis));
    Assert.AreEqual('Local', LConfig.Perfis[0].Nome);
    Assert.AreEqual('http://localhost:9000', LConfig.Perfis[0].Url);
    Assert.AreEqual(15000, LConfig.TimeoutMs);
    Assert.AreEqual(30000, LConfig.IntervaloHealthMs);
    Assert.IsTrue(LConfig.LogHttp);
    Assert.AreEqual(30, LConfig.RetencaoLogDias);
  finally
    LConfig.Free;
  end;
end;

procedure TTestConfig.PerfilPorNome_Inexistente_DevolvePrimeiro;
var
  LConfig: TConfig;
begin
  LConfig := TConfig.Create(TPath.Combine(FPasta, 'nao-existe.ini'));
  try
    Assert.AreEqual('Local', LConfig.PerfilPorNome('NaoExiste').Nome);
  finally
    LConfig.Free;
  end;
end;

procedure TTestConfig.LimparLogsAntigos_ApagaSoOsVencidos;
var
  LNovo, LVelho, LVelhoHttp: string;
begin
  TDirectory.CreateDirectory(TPath.Combine(FPasta, 'http'));
  LNovo := TPath.Combine(FPasta, 'novo.log');
  LVelho := TPath.Combine(FPasta, 'velho.log');
  LVelhoHttp := TPath.Combine(TPath.Combine(FPasta, 'http'), 'velho.log');
  TFile.WriteAllText(LNovo, 'x');
  TFile.WriteAllText(LVelho, 'x');
  TFile.WriteAllText(LVelhoHttp, 'x');
  TFile.SetLastWriteTime(LVelho, IncDay(Now, -40));
  TFile.SetLastWriteTime(LVelhoHttp, IncDay(Now, -40));

  LimparLogsAntigos(FPasta, 30);

  Assert.IsTrue(TFile.Exists(LNovo));
  Assert.IsFalse(TFile.Exists(LVelho));
  Assert.IsFalse(TFile.Exists(LVelhoHttp));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfig);

end.
