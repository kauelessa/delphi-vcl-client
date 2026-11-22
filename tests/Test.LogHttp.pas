unit Test.LogHttp;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestLogHttp = class
  private
    FPasta: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Mascarar_SenhaDoLogin;
    [Test]
    procedure Mascarar_TokenDaResposta;
    [Test]
    procedure Mascarar_ChavesAninhadasEMaiusculas;
    [Test]
    procedure Mascarar_TextoQueNaoEJson_PassaIntacto;
    [Test]
    procedure Mascarar_Vazio;
    [Test]
    procedure Registrar_GravaArquivoDoDiaSemSegredos;
    [Test]
    procedure Registrar_Desligado_NaoCriaArquivo;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Infra.LogHttp;

procedure TTestLogHttp.Setup;
begin
  FPasta := TPath.Combine(TPath.GetTempPath, 'vclclient-loghttp-' + TGUID.NewGuid.ToString);
end;

procedure TTestLogHttp.TearDown;
begin
  if TDirectory.Exists(FPasta) then
    TDirectory.Delete(FPasta, True);
end;

procedure TTestLogHttp.Mascarar_SenhaDoLogin;
begin
  Assert.AreEqual('{"login":"admin","senha":"***"}', MascararSegredos('{"login":"admin","senha":"admin123"}'));
end;

procedure TTestLogHttp.Mascarar_TokenDaResposta;
begin
  Assert.AreEqual('{"token":"***","tipo":"Bearer"}', MascararSegredos('{"token":"eyJhb.x.y","tipo":"Bearer"}'));
end;

procedure TTestLogHttp.Mascarar_ChavesAninhadasEMaiusculas;
begin
  Assert.AreEqual('{"usuario":{"Senha":"***"},"lista":[{"TOKEN":"***","id":1}]}',
    MascararSegredos('{"usuario":{"Senha":"x"},"lista":[{"TOKEN":"y","id":1}]}'));
end;

procedure TTestLogHttp.Mascarar_TextoQueNaoEJson_PassaIntacto;
begin
  Assert.AreEqual('nao e json', MascararSegredos('nao e json'));
end;

procedure TTestLogHttp.Mascarar_Vazio;
begin
  Assert.AreEqual('', MascararSegredos(''));
end;

procedure TTestLogHttp.Registrar_GravaArquivoDoDiaSemSegredos;
var
  LLog: ILogHttp;
  LArquivo, LConteudo: string;
begin
  LLog := TLogHttpArquivo.Create(FPasta, True);
  LLog.Registrar('POST', 'http://localhost:9000/auth/login', 200, 35,
    '{"login":"admin","senha":"admin123"}', '{"token":"eyJhb.x.y","tipo":"Bearer"}');

  LArquivo := TPath.Combine(TPath.Combine(FPasta, 'http'), FormatDateTime('yyyy-mm-dd', Date) + '.log');
  Assert.IsTrue(TFile.Exists(LArquivo), 'arquivo do dia não foi criado');
  LConteudo := TFile.ReadAllText(LArquivo, TEncoding.UTF8);
  Assert.Contains(LConteudo, 'POST http://localhost:9000/auth/login');
  Assert.Contains(LConteudo, '200');
  Assert.DoesNotContain(LConteudo, 'admin123');
  Assert.DoesNotContain(LConteudo, 'eyJhb');
end;

procedure TTestLogHttp.Registrar_Desligado_NaoCriaArquivo;
var
  LLog: ILogHttp;
begin
  LLog := TLogHttpArquivo.Create(FPasta, False);
  LLog.Registrar('GET', 'http://localhost:9000/health', 200, 3, '', '{"status":"ok"}');
  Assert.IsFalse(TDirectory.Exists(TPath.Combine(FPasta, 'http')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLogHttp);

end.
