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
    procedure Listar_ConverteCamposDoApp;
    [Test]
    procedure Listar_PedidoSemCamposNovos_FicaVazio;
    [Test]
    procedure LerAssinatura_DevolveBytesDoPng;
    [Test]
    procedure LerAssinatura_404_DevolveVazio;
    [Test]
    procedure UrlMapa_UsaPontoDecimalComRegionalPtBr;
    [Test]
    procedure Cancelar_UsaPatch;
    [Test]
    procedure Cancelar_EnviaCorpoJsonVazio;
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

procedure TTestPedido.Listar_ConverteCamposDoApp;
const
  CHAVE = '35261111222333000181550010000001231000001230';
var
  LPagina: TPagina<TPedido>;
  P: TPedido;
begin
  FHttp.Enfileirar(200, '{"dados":[' + PEDIDO_JSON.Replace('"status":"ABERTO"',
    '"status":"ABERTO","origem":"APP","observacao":"Entregar pela manhã","temAssinatura":true,' +
    '"vendedor":{"id":2,"nome":"Ana Vendedora"},' +
    '"nota":{"numero":123,"serie":1,"chave":"' + CHAVE + '","autorizadaEm":"2026-11-22T14:05:00-03:00"},' +
    '"localizacao":{"latitude":-23.5505,"longitude":-46.6333,"precisao":9}') +
    '],"pagina":1,"limite":20,"total":1}');
  LPagina := FService.Listar(1, 20, 0);
  try
    P := LPagina.Dados[0];
    Assert.AreEqual('App', P.OrigemDescricao);
    Assert.AreEqual('Ana Vendedora', P.VendedorNome);
    Assert.AreEqual('123/1', P.NotaDescricao);
    Assert.AreEqual(123, P.NotaNumero);
    Assert.AreEqual(CHAVE, P.NotaChave);
    Assert.IsTrue(P.TemLocalizacao);
    Assert.AreEqual(-23.5505, P.Latitude, 0.000001);
    Assert.AreEqual(-46.6333, P.Longitude, 0.000001);
    Assert.AreEqual(9.0, P.Precisao, 0.000001);
    Assert.IsTrue(P.TemAssinatura);
    Assert.AreEqual('Entregar pela manhã', P.Observacao);
  finally
    LPagina.Free;
  end;
end;

procedure TTestPedido.Listar_PedidoSemCamposNovos_FicaVazio;
var
  LPagina: TPagina<TPedido>;
  P: TPedido;
begin
  // pedido como a API devolvia antes do app (e com null nos objetos que o app preenche)
  FHttp.Enfileirar(200, '{"dados":[' + PEDIDO_JSON + ',' +
    PEDIDO_JSON.Replace('"id":5,', '"id":6,"vendedor":null,"nota":null,"localizacao":null,"origem":"API",') +
    '],"pagina":1,"limite":20,"total":2}');
  LPagina := FService.Listar(1, 20, 0);
  try
    for P in LPagina.Dados do
    begin
      Assert.AreEqual('API', P.OrigemDescricao);
      Assert.AreEqual('', P.VendedorNome);
      Assert.AreEqual('', P.NotaDescricao);
      Assert.IsFalse(P.TemLocalizacao);
      Assert.IsFalse(P.TemAssinatura);
    end;
  finally
    LPagina.Free;
  end;
end;

procedure TTestPedido.LerAssinatura_DevolveBytesDoPng;
const
  PNG_8_BYTES: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
var
  LEsperado, LBytes: TBytes;
begin
  SetLength(LEsperado, Length(PNG_8_BYTES));
  Move(PNG_8_BYTES[0], LEsperado[0], Length(PNG_8_BYTES));
  FHttp.EnfileirarBytes(200, LEsperado, 'image/png');
  LBytes := FService.LerAssinatura(7);
  Assert.AreEqual(Ord(THttpMetodo.Get), Ord(FHttp.Chamadas[0].Metodo));
  Assert.AreEqual('http://api.teste/pedidos/7/assinatura', FHttp.Chamadas[0].Url);
  Assert.AreEqual(Length(LEsperado), Length(LBytes));
  Assert.IsTrue(CompareMem(@LEsperado[0], @LBytes[0], Length(LEsperado)), 'bytes diferentes');
end;

procedure TTestPedido.LerAssinatura_404_DevolveVazio;
begin
  FHttp.Enfileirar(404, '{"erro":"Pedido sem assinatura."}');
  Assert.AreEqual(0, Integer(Length(FService.LerAssinatura(7))));
end;

procedure TTestPedido.UrlMapa_UsaPontoDecimalComRegionalPtBr;
var
  LSeparador: Char;
begin
  LSeparador := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := ',';
  try
    Assert.AreEqual('https://www.openstreetmap.org/?mlat=-23.550500&mlon=-46.633300#map=17/-23.550500/-46.633300',
      UrlMapa(-23.5505, -46.6333));
  finally
    FormatSettings.DecimalSeparator := LSeparador;
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

procedure TTestPedido.Cancelar_EnviaCorpoJsonVazio;
begin
  // o middleware JSON da API (Jhonson) recusa PATCH sem corpo com 400 "Corpo da requisição vazio"
  FHttp.Enfileirar(200, PEDIDO_JSON.Replace('"ABERTO"', '"CANCELADO"'));
  FService.Cancelar(5).Free;
  Assert.AreEqual('{}', FHttp.Chamadas[0].Corpo);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPedido);

end.
