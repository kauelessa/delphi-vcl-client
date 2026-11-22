unit Test.Sessao;

interface

uses
  DUnitX.TestFramework, Infra.Config, Infra.Preferencias, Api.Auth, Service.Sessao, Test.Fakes;

type
  [TestFixture]
  TTestSessao = class
  private
    FPasta: string;
    FHttp: THttpFake;
    FPreferencias: TPreferenciasUsuario;
    FSessao: ISessaoService;
    FSenhasDigitadas: TArray<string>; // respostas do diálogo de relogin, em ordem; acabou = cancelou
    FVezesPerguntou: Integer;
    function Perfil: TPerfilApi;
    procedure EnfileirarLoginOk(const AToken: string);
    function ArquivoPreferencias: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Entrar_GuardaTokenEUrl;
    [Test]
    procedure Entrar_EnviaLoginESenhaNoCorpo;
    [Test]
    procedure Entrar_LembrarUsuarioESenha_GravaSenhaCifrada;
    [Test]
    procedure Entrar_SemLembrarSenha_ApagaSenhaAnterior;
    [Test]
    procedure Entrar_SemLembrarNada_NaoGravaUsuario;
    [Test]
    procedure Entrar_401_LevantaNaoAutorizadoComMensagemDaApi;
    [Test]
    procedure Relogar_PedirSenhaCancelado_RetornaFalse;
    [Test]
    procedure Relogar_SenhaCerta_TrocaToken;
    [Test]
    procedure Relogar_SenhaErradaDepoisCerta_PerguntaDeNovo;
    [Test]
    procedure Health_200_Online;
    [Test]
    procedure Health_SemResposta_Offline;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Infra.Http, Infra.Excecoes, Api.Health;

procedure TTestSessao.Setup;
var
  LAuth: IAuthApi;
begin
  FPasta := TPath.Combine(TPath.GetTempPath, 'vclclient-sessao-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FPasta);
  FHttp := THttpFake.Create;
  LAuth := TAuthApi.Create(FHttp);
  FPreferencias := TPreferenciasUsuario.Create(ArquivoPreferencias);
  FSessao := TSessaoService.Create(LAuth, FPreferencias);
  FVezesPerguntou := 0;
  FSenhasDigitadas := [];
  FSessao.DefinirPedirSenha(
    function(const AUsuario: string; out ASenha: string): Boolean
    begin
      Result := FVezesPerguntou < Length(FSenhasDigitadas);
      if Result then
        ASenha := FSenhasDigitadas[FVezesPerguntou];
      Inc(FVezesPerguntou);
    end);
end;

procedure TTestSessao.TearDown;
begin
  FSessao := nil;
  FPreferencias.Free;
  if TDirectory.Exists(FPasta) then
    TDirectory.Delete(FPasta, True);
end;

function TTestSessao.ArquivoPreferencias: string;
begin
  Result := TPath.Combine(FPasta, 'usuario.ini');
end;

function TTestSessao.Perfil: TPerfilApi;
begin
  Result.Nome := 'Local';
  Result.Url := 'http://api.teste';
end;

procedure TTestSessao.EnfileirarLoginOk(const AToken: string);
begin
  FHttp.Enfileirar(200, '{"token":"' + AToken + '","tipo":"Bearer","expiraEm":"2026-11-20T22:30:00.000-03:00"}');
end;

procedure TTestSessao.Entrar_GuardaTokenEUrl;
begin
  EnfileirarLoginOk('eyJ.abc');
  FSessao.Entrar(Perfil, 'admin', 'admin123', False, False);
  Assert.AreEqual('eyJ.abc', FSessao.Token);
  Assert.AreEqual('http://api.teste', FSessao.UrlBase);
  Assert.AreEqual('admin', FSessao.Usuario);
  Assert.AreEqual('http://api.teste/auth/login', FHttp.Chamadas[0].Url);
  Assert.AreEqual('', FHttp.Chamadas[0].Token);
end;

procedure TTestSessao.Entrar_EnviaLoginESenhaNoCorpo;
begin
  EnfileirarLoginOk('t');
  FSessao.Entrar(Perfil, 'admin', 'admin123', False, False);
  Assert.AreEqual('{"login":"admin","senha":"admin123"}', FHttp.Chamadas[0].Corpo);
  Assert.AreEqual(Ord(THttpMetodo.Post), Ord(FHttp.Chamadas[0].Metodo));
end;

procedure TTestSessao.Entrar_LembrarUsuarioESenha_GravaSenhaCifrada;
var
  LConteudo: string;
  LLembradas: TCredenciaisLembradas;
begin
  EnfileirarLoginOk('t');
  FSessao.Entrar(Perfil, 'admin', 'admin123', True, True);

  LConteudo := TFile.ReadAllText(ArquivoPreferencias);
  Assert.Contains(LConteudo, 'Usuario=admin');
  Assert.DoesNotContain(LConteudo, 'admin123');

  LLembradas := FSessao.Lembradas;
  Assert.AreEqual('admin', LLembradas.Usuario);
  Assert.AreEqual('admin123', LLembradas.Senha);
  Assert.AreEqual('Local', LLembradas.Perfil);
  Assert.IsTrue(LLembradas.LembrarUsuario);
  Assert.IsTrue(LLembradas.LembrarSenha);
end;

procedure TTestSessao.Entrar_SemLembrarSenha_ApagaSenhaAnterior;
begin
  EnfileirarLoginOk('t');
  FSessao.Entrar(Perfil, 'admin', 'admin123', True, True);
  EnfileirarLoginOk('t');
  FSessao.Entrar(Perfil, 'admin', 'admin123', True, False);

  Assert.AreEqual('', FPreferencias.Ler('Login', 'Senha', ''));
  Assert.AreEqual('', FSessao.Lembradas.Senha);
  Assert.IsFalse(FSessao.Lembradas.LembrarSenha);
  Assert.AreEqual('admin', FSessao.Lembradas.Usuario);
end;

procedure TTestSessao.Entrar_SemLembrarNada_NaoGravaUsuario;
begin
  EnfileirarLoginOk('t');
  FSessao.Entrar(Perfil, 'admin', 'admin123', False, False);
  Assert.AreEqual('', FSessao.Lembradas.Usuario);
  Assert.IsFalse(FSessao.Lembradas.LembrarUsuario);
end;

procedure TTestSessao.Entrar_401_LevantaNaoAutorizadoComMensagemDaApi;
begin
  FHttp.Enfileirar(401, '{"erro":"Login ou senha inválidos."}');
  Assert.WillRaiseWithMessage(
    procedure begin FSessao.Entrar(Perfil, 'admin', 'errada', False, False) end,
    EApiNaoAutorizado, 'Login ou senha inválidos.');
  Assert.AreEqual('', FSessao.Token);
end;

procedure TTestSessao.Relogar_PedirSenhaCancelado_RetornaFalse;
begin
  EnfileirarLoginOk('velho');
  FSessao.Entrar(Perfil, 'admin', 'admin123', False, False);
  FSenhasDigitadas := [];
  Assert.IsFalse(FSessao.Relogar);
  Assert.AreEqual(1, FHttp.Chamadas.Count); // não tentou logar sem senha
end;

procedure TTestSessao.Relogar_SenhaCerta_TrocaToken;
begin
  EnfileirarLoginOk('velho');
  FSessao.Entrar(Perfil, 'admin', 'admin123', False, False);
  FSenhasDigitadas := ['admin123'];
  EnfileirarLoginOk('novo');
  Assert.IsTrue(FSessao.Relogar);
  Assert.AreEqual('novo', FSessao.Token);
end;

procedure TTestSessao.Relogar_SenhaErradaDepoisCerta_PerguntaDeNovo;
begin
  EnfileirarLoginOk('velho');
  FSessao.Entrar(Perfil, 'admin', 'admin123', False, False);
  FSenhasDigitadas := ['errada', 'admin123'];
  FHttp.Enfileirar(401, '{"erro":"Login ou senha inválidos."}');
  EnfileirarLoginOk('novo');
  Assert.IsTrue(FSessao.Relogar);
  Assert.AreEqual(2, FVezesPerguntou);
  Assert.AreEqual('novo', FSessao.Token);
end;

procedure TTestSessao.Health_200_Online;
var
  LHealth: IHealthApi;
begin
  FHttp.Enfileirar(200, '{"status":"ok"}');
  LHealth := THealthApi.Create(FHttp);
  Assert.IsTrue(LHealth.Online('http://api.teste'));
  Assert.AreEqual('http://api.teste/health', FHttp.Chamadas[0].Url);
end;

procedure TTestSessao.Health_SemResposta_Offline;
var
  LHealth: IHealthApi;
begin
  // fila vazia: o fake levanta exceção, como a rede fora do ar
  LHealth := THealthApi.Create(FHttp);
  Assert.IsFalse(LHealth.Online('http://api.teste'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSessao);

end.
