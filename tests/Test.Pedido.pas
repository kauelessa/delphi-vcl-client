unit Test.Pedido;

interface

uses
  DUnitX.TestFramework, Infra.Http, Api.Base, Api.Pedido, Model.Produto, Model.PedidoDigitacao,
  Service.Rascunho, Service.Pedido, Test.Fakes;

type
  [TestFixture]
  TTestPedido = class
  private
    FPasta: string;
    FHttp: THttpFake;
    FHttpIntf: IHttpClient;
    FSessao: TSessaoFake;
    FSessaoIntf: ISessaoApi;
    FRascunho: IRascunhoPedido;
    FService: IPedidoService;
    FPedido: TPedidoEmDigitacao;
    function Produto(AId: Integer; const ADescricao: string; APreco: Currency): TProduto;
    procedure Adicionar(AId: Integer; const ADescricao: string; APreco: Currency; AQuantidade: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure AdicionarProduto_Repetido_SomaQuantidade;
    [Test]
    procedure AdicionarProduto_QuantidadeZero_LevantaValidacao;
    [Test]
    procedure AlterarQuantidade_Negativa_LevantaValidacao;
    [Test]
    procedure RemoverItem_TiraDaLista;
    [Test]
    procedure Total_SomaPrecoVezesQuantidade;
    [Test]
    procedure Enviar_MontaCorpoDaApi;
    [Test]
    procedure Enviar_SemCliente_LevantaValidacao;
    [Test]
    procedure Enviar_SemItens_LevantaValidacao;
    [Test]
    procedure Enviar_Sucesso_DescartaRascunho;
    [Test]
    procedure Enviar_422_MantemRascunhoEPropagaMensagem;
    [Test]
    procedure Enviar_401ReloginCancelado_MantemRascunho;
    [Test]
    procedure Rascunho_SalvarECarregar_IdaEVolta;
    [Test]
    procedure Rascunho_ArquivoCorrompido_CarregaNil;
    [Test]
    procedure Rascunho_Inexistente_CarregaNil;
    [Test]
    procedure Listar_ConverteStatusDataEItens;
    [Test]
    procedure Listar_FiltroPorCliente_VaiNaUrl;
    [Test]
    procedure Cancelar_UsaPatch;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.DateUtils, Infra.Excecoes, Model.Pagina, Model.Pedido;

const
  PEDIDO_JSON = '{"id":5,"cliente":{"id":1,"nome":"Maria Souza"},"data":"2026-11-20T10:15:00.000-03:00",' +
    '"status":"ABERTO","valorTotal":829.7,"itens":[' +
    '{"id":1,"produtoId":1,"descricao":"Teclado mecânico","quantidade":2,"precoUnitario":349.9,"valorTotal":699.8},' +
    '{"id":2,"produtoId":2,"descricao":"Mouse sem fio","quantidade":1,"precoUnitario":129.9,"valorTotal":129.9}]}';

procedure TTestPedido.Setup;
begin
  FPasta := TPath.Combine(TPath.GetTempPath, 'vclclient-pedido-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FPasta);
  FHttp := THttpFake.Create;
  FHttpIntf := FHttp;
  FSessao := TSessaoFake.Create;
  FSessaoIntf := FSessao;
  FRascunho := TRascunhoArquivo.Create(TPath.Combine(FPasta, 'rascunho-pedido.json'));
  FService := TPedidoService.Create(TPedidoApi.Create(FHttpIntf, FSessaoIntf), FRascunho);
  FPedido := TPedidoEmDigitacao.Create;
end;

procedure TTestPedido.TearDown;
begin
  FPedido.Free;
  FService := nil;
  FRascunho := nil;
  FSessaoIntf := nil;
  FHttpIntf := nil;
  if TDirectory.Exists(FPasta) then
    TDirectory.Delete(FPasta, True);
end;

function TTestPedido.Produto(AId: Integer; const ADescricao: string; APreco: Currency): TProduto;
begin
  Result := TProduto.Create;
  Result.Id := AId;
  Result.Descricao := ADescricao;
  Result.Preco := APreco;
end;

procedure TTestPedido.Adicionar(AId: Integer; const ADescricao: string; APreco: Currency; AQuantidade: Integer);
var
  LProduto: TProduto;
begin
  LProduto := Produto(AId, ADescricao, APreco);
  try
    FPedido.AdicionarProduto(LProduto, AQuantidade);
  finally
    LProduto.Free;
  end;
end;

procedure TTestPedido.AdicionarProduto_Repetido_SomaQuantidade;
begin
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Adicionar(1, 'Teclado mecânico', 349.90, 3);
  Assert.AreEqual(1, FPedido.Itens.Count);
  Assert.AreEqual(5, FPedido.Itens[0].Quantidade);
end;

procedure TTestPedido.AdicionarProduto_QuantidadeZero_LevantaValidacao;
begin
  Assert.WillRaiseWithMessage(procedure begin Adicionar(1, 'Teclado mecânico', 349.90, 0) end,
    EValidacao, 'A quantidade deve ser maior que zero.');
  Assert.AreEqual(0, FPedido.Itens.Count);
end;

procedure TTestPedido.AlterarQuantidade_Negativa_LevantaValidacao;
begin
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Assert.WillRaise(procedure begin FPedido.AlterarQuantidade(0, -1) end, EValidacao);
  Assert.AreEqual(2, FPedido.Itens[0].Quantidade);
end;

procedure TTestPedido.RemoverItem_TiraDaLista;
begin
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Adicionar(2, 'Mouse sem fio', 129.90, 1);
  FPedido.RemoverItem(0);
  Assert.AreEqual(1, FPedido.Itens.Count);
  Assert.AreEqual(2, FPedido.Itens[0].ProdutoId);
end;

procedure TTestPedido.Total_SomaPrecoVezesQuantidade;
begin
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Adicionar(2, 'Mouse sem fio', 129.90, 1);
  Assert.AreEqual(Currency(829.70), FPedido.Total);
end;

procedure TTestPedido.Enviar_MontaCorpoDaApi;
begin
  FPedido.ClienteId := 1;
  FPedido.ClienteNome := 'Maria Souza';
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Adicionar(2, 'Mouse sem fio', 129.90, 1);
  FHttp.Enfileirar(201, PEDIDO_JSON);
  FService.Enviar(FPedido).Free;
  Assert.AreEqual(Ord(THttpMetodo.Post), Ord(FHttp.Chamadas[0].Metodo));
  Assert.AreEqual('http://api.teste/pedidos', FHttp.Chamadas[0].Url);
  Assert.AreEqual('{"clienteId":1,"itens":[{"produtoId":1,"quantidade":2},{"produtoId":2,"quantidade":1}]}',
    FHttp.Chamadas[0].Corpo);
end;

procedure TTestPedido.Enviar_SemCliente_LevantaValidacao;
begin
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Assert.WillRaiseWithMessage(procedure begin FService.Enviar(FPedido).Free end,
    EValidacao, 'Escolha o cliente.');
  Assert.AreEqual(0, FHttp.Chamadas.Count);
end;

procedure TTestPedido.Enviar_SemItens_LevantaValidacao;
begin
  FPedido.ClienteId := 1;
  Assert.WillRaiseWithMessage(procedure begin FService.Enviar(FPedido).Free end,
    EValidacao, 'Adicione pelo menos um produto.');
end;

procedure TTestPedido.Enviar_Sucesso_DescartaRascunho;
begin
  FPedido.ClienteId := 1;
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  FRascunho.Salvar(FPedido);
  FHttp.Enfileirar(201, PEDIDO_JSON);
  FService.Enviar(FPedido).Free;
  Assert.IsFalse(FRascunho.Existe);
end;

procedure TTestPedido.Enviar_422_MantemRascunhoEPropagaMensagem;
begin
  FPedido.ClienteId := 1;
  Adicionar(2, 'Mouse sem fio', 129.90, 999);
  FRascunho.Salvar(FPedido);
  FHttp.Enfileirar(422, '{"erro":"Estoque insuficiente para o produto Mouse sem fio."}');
  Assert.WillRaiseWithMessage(procedure begin FService.Enviar(FPedido).Free end,
    EApiValidacao, 'Estoque insuficiente para o produto Mouse sem fio.');
  Assert.IsTrue(FRascunho.Existe);
end;

procedure TTestPedido.Enviar_401ReloginCancelado_MantemRascunho;
begin
  FPedido.ClienteId := 1;
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  FRascunho.Salvar(FPedido);
  FSessao.ResultadoRelogar := False;
  FHttp.Enfileirar(401, '{"erro":"Token expirado."}');
  Assert.WillRaise(procedure begin FService.Enviar(FPedido).Free end, EApiNaoAutorizado);
  Assert.IsTrue(FRascunho.Existe);
end;

procedure TTestPedido.Rascunho_SalvarECarregar_IdaEVolta;
var
  LCarregado: TPedidoEmDigitacao;
begin
  FPedido.ClienteId := 1;
  FPedido.ClienteNome := 'Maria Souza';
  Adicionar(1, 'Teclado mecânico', 349.90, 2);
  Adicionar(2, 'Mouse sem fio', 129.90, 1);
  FRascunho.Salvar(FPedido);

  LCarregado := FRascunho.Carregar;
  try
    Assert.IsNotNull(LCarregado);
    Assert.AreEqual(1, LCarregado.ClienteId);
    Assert.AreEqual('Maria Souza', LCarregado.ClienteNome);
    Assert.AreEqual(2, LCarregado.Itens.Count);
    Assert.AreEqual('Teclado mecânico', LCarregado.Itens[0].Descricao);
    Assert.AreEqual(Currency(349.90), LCarregado.Itens[0].PrecoUnitario);
    Assert.AreEqual(2, LCarregado.Itens[0].Quantidade);
  finally
    LCarregado.Free;
  end;
end;

procedure TTestPedido.Rascunho_ArquivoCorrompido_CarregaNil;
begin
  TFile.WriteAllText(TPath.Combine(FPasta, 'rascunho-pedido.json'), '{isso não é json');
  Assert.IsNull(FRascunho.Carregar);
end;

procedure TTestPedido.Rascunho_Inexistente_CarregaNil;
begin
  Assert.IsFalse(FRascunho.Existe);
  Assert.IsNull(FRascunho.Carregar);
end;

procedure TTestPedido.Listar_ConverteStatusDataEItens;
var
  LPagina: TPagina<TPedido>;
begin
  FHttp.Enfileirar(200, '{"dados":[' + PEDIDO_JSON.Replace('"ABERTO"', '"CANCELADO"') +
    '],"pagina":1,"limite":20,"total":1}');
  LPagina := FService.Listar(1, 20, 0);
  try
    Assert.AreEqual('http://api.teste/pedidos?pagina=1&limite=20', FHttp.Chamadas[0].Url);
    Assert.AreEqual(5, LPagina.Dados[0].Id);
    Assert.AreEqual(1, LPagina.Dados[0].ClienteId);
    Assert.AreEqual('Maria Souza', LPagina.Dados[0].ClienteNome);
    Assert.AreEqual(Ord(TStatusPedido.Cancelado), Ord(LPagina.Dados[0].Status));
    Assert.AreEqual(Currency(829.7), LPagina.Dados[0].ValorTotal);
    Assert.AreEqual(2, LPagina.Dados[0].Itens.Count);
    Assert.AreEqual(Currency(699.8), LPagina.Dados[0].Itens[0].ValorTotal);
    Assert.AreEqual(EncodeDateTime(2026, 11, 20, 13, 15, 0, 0),
      TTimeZone.Local.ToUniversalTime(LPagina.Dados[0].Data), OneSecond);
  finally
    LPagina.Free;
  end;
end;

procedure TTestPedido.Listar_FiltroPorCliente_VaiNaUrl;
begin
  FHttp.Enfileirar(200, '{"dados":[],"pagina":1,"limite":20,"total":0}');
  FService.Listar(1, 20, 3).Free;
  Assert.AreEqual('http://api.teste/pedidos?pagina=1&limite=20&clienteId=3', FHttp.Chamadas[0].Url);
end;

procedure TTestPedido.Cancelar_UsaPatch;
var
  LPedido: TPedido;
begin
  FHttp.Enfileirar(200, PEDIDO_JSON.Replace('"ABERTO"', '"CANCELADO"'));
  LPedido := FService.Cancelar(5);
  try
    Assert.AreEqual(Ord(THttpMetodo.Patch), Ord(FHttp.Chamadas[0].Metodo));
    Assert.AreEqual('http://api.teste/pedidos/5/cancelar', FHttp.Chamadas[0].Url);
    Assert.AreEqual(Ord(TStatusPedido.Cancelado), Ord(LPedido.Status));
  finally
    LPedido.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPedido);

end.
