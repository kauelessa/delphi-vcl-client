unit Test.ApiBase;

interface

uses
  DUnitX.TestFramework, Infra.Http, Api.Base, Test.Fakes;

type
  // expõe o Enviar protegido só para o teste
  TApiTeste = class(TApiBase)
  public
    function Chamar(const ARota: string): string;
  end;

  [TestFixture]
  TTestApiBase = class
  private
    FHttp: THttpFake;
    FHttpIntf: IHttpClient;
    FSessao: TSessaoFake;
    FSessaoIntf: ISessaoApi;
    FApi: TApiTeste;
    function Resposta(AStatus: Integer; const ACorpo: string): THttpResposta;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Verificar_422_ValidacaoComMensagemDaApi;
    [Test]
    procedure Verificar_400_Validacao;
    // pedido faturado não pode ser cancelado: a API diz por quê (409), não é "erro inesperado"
    [Test]
    procedure Verificar_409_ValidacaoComMensagemDaApi;
    [Test]
    procedure Verificar_404_NaoEncontrado;
    [Test]
    procedure Verificar_401_NaoAutorizado;
    [Test]
    procedure Verificar_500_IndisponivelComStatus;
    [Test]
    procedure Verificar_502Html_MensagemComStatusSemErroDeParse;
    [Test]
    procedure Verificar_422SemCorpo_MensagemSemDetalhes;
    [Test]
    procedure Verificar_200_NaoLevanta;
    [Test]
    procedure Enviar_MontaUrlEToken;
    [Test]
    procedure Enviar_401EReloginOk_RepeteComTokenNovo;
    [Test]
    procedure Enviar_401EReloginCancelado_LevantaNaoAutorizado;
    [Test]
    procedure Enviar_401DuasVezes_NaoEntraEmLaco;
  end;

implementation

uses
  System.SysUtils, Infra.Excecoes;

function TApiTeste.Chamar(const ARota: string): string;
begin
  Result := Enviar(THttpMetodo.Get, ARota);
end;

procedure TTestApiBase.Setup;
begin
  FHttp := THttpFake.Create;
  FHttpIntf := FHttp;
  FSessao := TSessaoFake.Create;
  FSessaoIntf := FSessao;
  FApi := TApiTeste.Create(FHttpIntf, FSessaoIntf);
end;

procedure TTestApiBase.TearDown;
begin
  FApi.Free;
  FSessaoIntf := nil;
  FHttpIntf := nil;
end;

function TTestApiBase.Resposta(AStatus: Integer; const ACorpo: string): THttpResposta;
begin
  Result.Status := AStatus;
  Result.Corpo := ACorpo;
end;

procedure TTestApiBase.Verificar_422_ValidacaoComMensagemDaApi;
begin
  Assert.WillRaiseWithMessage(
    procedure begin TApiBase.VerificarResposta(Resposta(422, '{"erro":"Estoque insuficiente"}')) end,
    EApiValidacao, 'Estoque insuficiente');
end;

procedure TTestApiBase.Verificar_409_ValidacaoComMensagemDaApi;
begin
  Assert.WillRaiseWithMessage(
    procedure begin TApiBase.VerificarResposta(Resposta(409, '{"erro":"Pedido faturado na NF-e 1287; cancele a nota primeiro."}')) end,
    EApiValidacao, 'Pedido faturado na NF-e 1287; cancele a nota primeiro.');
end;

procedure TTestApiBase.Verificar_400_Validacao;
begin
  Assert.WillRaise(
    procedure begin TApiBase.VerificarResposta(Resposta(400, '{"erro":"JSON inválido"}')) end,
    EApiValidacao);
end;

procedure TTestApiBase.Verificar_404_NaoEncontrado;
begin
  Assert.WillRaiseWithMessage(
    procedure begin TApiBase.VerificarResposta(Resposta(404, '{"erro":"Cliente não encontrado."}')) end,
    EApiNaoEncontrado, 'Cliente não encontrado.');
end;

procedure TTestApiBase.Verificar_401_NaoAutorizado;
begin
  Assert.WillRaise(
    procedure begin TApiBase.VerificarResposta(Resposta(401, '{"erro":"Token expirado."}')) end,
    EApiNaoAutorizado);
end;

procedure TTestApiBase.Verificar_500_IndisponivelComStatus;
begin
  Assert.WillRaiseWithMessage(
    procedure begin TApiBase.VerificarResposta(Resposta(500, '{"erro":"x"}')) end,
    EApiIndisponivel,
    'A API encontrou um erro inesperado (HTTP 500). Tente novamente; se persistir, veja o log da API.');
end;

procedure TTestApiBase.Verificar_502Html_MensagemComStatusSemErroDeParse;
begin
  Assert.WillRaiseWithMessage(
    procedure begin TApiBase.VerificarResposta(Resposta(502, '<html>Bad Gateway</html>')) end,
    EApiIndisponivel,
    'A API encontrou um erro inesperado (HTTP 502). Tente novamente; se persistir, veja o log da API.');
end;

procedure TTestApiBase.Verificar_422SemCorpo_MensagemSemDetalhes;
begin
  Assert.WillRaiseWithMessage(
    procedure begin TApiBase.VerificarResposta(Resposta(422, '')) end,
    EApiValidacao, 'A API respondeu HTTP 422 sem detalhes.');
end;

procedure TTestApiBase.Verificar_200_NaoLevanta;
begin
  Assert.WillNotRaise(
    procedure begin TApiBase.VerificarResposta(Resposta(200, '{"status":"ok"}')) end);
end;

procedure TTestApiBase.Enviar_MontaUrlEToken;
begin
  FHttp.Enfileirar(200, '{"ok":true}');
  Assert.AreEqual('{"ok":true}', FApi.Chamar('/clientes/1'));
  Assert.AreEqual('http://api.teste/clientes/1', FHttp.Chamadas[0].Url);
  Assert.AreEqual('token-teste', FHttp.Chamadas[0].Token);
end;

procedure TTestApiBase.Enviar_401EReloginOk_RepeteComTokenNovo;
begin
  FHttp.Enfileirar(401, '{"erro":"Token expirado."}');
  FHttp.Enfileirar(200, '{"ok":true}');
  FSessao.ResultadoRelogar := True;

  Assert.AreEqual('{"ok":true}', FApi.Chamar('/clientes'));
  Assert.AreEqual(2, FHttp.Chamadas.Count);
  Assert.AreEqual('novo', FHttp.Chamadas[1].Token);
  Assert.AreEqual(1, FSessao.VezesRelogar);
end;

procedure TTestApiBase.Enviar_401EReloginCancelado_LevantaNaoAutorizado;
begin
  FHttp.Enfileirar(401, '{"erro":"Token expirado."}');
  FSessao.ResultadoRelogar := False;

  Assert.WillRaise(procedure begin FApi.Chamar('/clientes') end, EApiNaoAutorizado);
  Assert.AreEqual(1, FHttp.Chamadas.Count);
end;

procedure TTestApiBase.Enviar_401DuasVezes_NaoEntraEmLaco;
begin
  FHttp.Enfileirar(401, '{"erro":"Token expirado."}');
  FHttp.Enfileirar(401, '{"erro":"Token expirado."}');
  FSessao.ResultadoRelogar := True;

  Assert.WillRaise(procedure begin FApi.Chamar('/clientes') end, EApiNaoAutorizado);
  Assert.AreEqual(1, FSessao.VezesRelogar);
  Assert.AreEqual(2, FHttp.Chamadas.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestApiBase);

end.
