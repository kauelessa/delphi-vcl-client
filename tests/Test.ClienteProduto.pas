unit Test.ClienteProduto;

interface

uses
  System.SysUtils, DUnitX.TestFramework, Infra.Http, Api.Base, Api.Cliente, Api.Produto,
  Service.Cliente, Service.Produto, Test.Fakes;

type
  [TestFixture]
  TTestClienteProduto = class
  private
    FHttp: THttpFake;
    FHttpIntf: IHttpClient;
    FSessao: ISessaoApi;
    FClientes: IClienteApi;
    FProdutos: IProdutoApi;
    FFormatoOriginal: TFormatSettings;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Listar_ConvertePagina;
    [Test]
    procedure Listar_BuscaComAcentoESimbolo_CodificaNaUrl;
    [Test]
    procedure Listar_SemBusca_NaoEnviaParametro;
    [Test]
    procedure Obter_ConverteCliente;
    [Test]
    procedure Criar_EnviaCorpoEDevolveComId;
    [Test]
    procedure Atualizar_UsaPutComId;
    [Test]
    procedure Inativar_ChamaDelete;
    [Test]
    procedure Produto_Criar_PrecoComVirgulaRegional_EnviaPonto;
    [Test]
    procedure Produto_Listar_ConvertePrecoEEstoque;
    [Test]
    procedure Service_ClienteSemNome_NaoChamaApi;
    [Test]
    procedure Service_ClienteSemDocumento_LevantaValidacao;
    [Test]
    procedure Service_ProdutoSemDescricao_LevantaValidacao;
    [Test]
    procedure Pagina_TotalPaginas;
  end;

implementation

uses
  Infra.Excecoes, Model.Pagina, Model.Cliente, Model.Produto;

procedure TTestClienteProduto.Setup;
begin
  FHttp := THttpFake.Create;
  FHttpIntf := FHttp;
  FSessao := TSessaoFake.Create;
  FClientes := TClienteApi.Create(FHttpIntf, FSessao);
  FProdutos := TProdutoApi.Create(FHttpIntf, FSessao);
  FFormatoOriginal := FormatSettings;
end;

procedure TTestClienteProduto.TearDown;
begin
  FormatSettings := FFormatoOriginal;
  FClientes := nil;
  FProdutos := nil;
  FSessao := nil;
  FHttpIntf := nil;
end;

procedure TTestClienteProduto.Listar_ConvertePagina;
var
  LPagina: TPagina<TCliente>;
begin
  FHttp.Enfileirar(200, '{"dados":[{"id":1,"nome":"Maria Souza","documento":"52998224725",' +
    '"email":"maria@exemplo.com","telefone":""}],"pagina":2,"limite":20,"total":21}');
  LPagina := FClientes.Listar(2, 20, '');
  try
    Assert.AreEqual(1, LPagina.Dados.Count);
    Assert.AreEqual(2, LPagina.Pagina);
    Assert.AreEqual(20, LPagina.Limite);
    Assert.AreEqual(21, LPagina.Total);
    Assert.AreEqual(2, LPagina.TotalPaginas);
    Assert.AreEqual(1, LPagina.Dados[0].Id);
    Assert.AreEqual('Maria Souza', LPagina.Dados[0].Nome);
    Assert.AreEqual('52998224725', LPagina.Dados[0].Documento);
    Assert.AreEqual('maria@exemplo.com', LPagina.Dados[0].Email);
  finally
    LPagina.Free;
  end;
end;

procedure TTestClienteProduto.Listar_BuscaComAcentoESimbolo_CodificaNaUrl;
begin
  FHttp.Enfileirar(200, '{"dados":[],"pagina":1,"limite":20,"total":0}');
  FClientes.Listar(1, 20, 'São Paulo & Cia').Free;
  Assert.AreEqual('http://api.teste/clientes?pagina=1&limite=20&busca=S%C3%A3o%20Paulo%20%26%20Cia',
    FHttp.Chamadas[0].Url);
end;

procedure TTestClienteProduto.Listar_SemBusca_NaoEnviaParametro;
begin
  FHttp.Enfileirar(200, '{"dados":[],"pagina":1,"limite":20,"total":0}');
  FClientes.Listar(1, 20, '  ').Free;
  Assert.AreEqual('http://api.teste/clientes?pagina=1&limite=20', FHttp.Chamadas[0].Url);
end;

procedure TTestClienteProduto.Obter_ConverteCliente;
var
  LCliente: TCliente;
begin
  FHttp.Enfileirar(200, '{"id":3,"nome":"Ana Prado","documento":"39053344705","email":null,"telefone":"11912345678"}');
  LCliente := FClientes.Obter(3);
  try
    Assert.AreEqual('http://api.teste/clientes/3', FHttp.Chamadas[0].Url);
    Assert.AreEqual('Ana Prado', LCliente.Nome);
    Assert.AreEqual('', LCliente.Email);
    Assert.AreEqual('11912345678', LCliente.Telefone);
  finally
    LCliente.Free;
  end;
end;

procedure TTestClienteProduto.Criar_EnviaCorpoEDevolveComId;
var
  LNovo, LCriado: TCliente;
begin
  FHttp.Enfileirar(201, '{"id":7,"nome":"Ana","documento":"39053344705","email":"","telefone":""}');
  LNovo := TCliente.Create;
  try
    LNovo.Nome := 'Ana';
    LNovo.Documento := '39053344705';
    LCriado := FClientes.Criar(LNovo);
    try
      Assert.AreEqual(7, LCriado.Id);
      Assert.AreEqual(Ord(THttpMetodo.Post), Ord(FHttp.Chamadas[0].Metodo));
      Assert.AreEqual('http://api.teste/clientes', FHttp.Chamadas[0].Url);
      Assert.AreEqual('{"nome":"Ana","documento":"39053344705"}', FHttp.Chamadas[0].Corpo);
    finally
      LCriado.Free;
    end;
  finally
    LNovo.Free;
  end;
end;

procedure TTestClienteProduto.Atualizar_UsaPutComId;
var
  LCliente: TCliente;
begin
  FHttp.Enfileirar(200, '{"id":5,"nome":"Ana","documento":"39053344705","email":"ana@exemplo.com","telefone":""}');
  LCliente := TCliente.Create;
  try
    LCliente.Id := 5;
    LCliente.Nome := 'Ana';
    LCliente.Documento := '39053344705';
    LCliente.Email := 'ana@exemplo.com';
    FClientes.Atualizar(LCliente).Free;
    Assert.AreEqual(Ord(THttpMetodo.Put), Ord(FHttp.Chamadas[0].Metodo));
    Assert.AreEqual('http://api.teste/clientes/5', FHttp.Chamadas[0].Url);
    Assert.Contains(FHttp.Chamadas[0].Corpo, '"email":"ana@exemplo.com"');
  finally
    LCliente.Free;
  end;
end;

procedure TTestClienteProduto.Inativar_ChamaDelete;
begin
  FHttp.Enfileirar(204, '');
  FClientes.Inativar(3);
  Assert.AreEqual(Ord(THttpMetodo.Delete), Ord(FHttp.Chamadas[0].Metodo));
  Assert.AreEqual('http://api.teste/clientes/3', FHttp.Chamadas[0].Url);
end;

procedure TTestClienteProduto.Produto_Criar_PrecoComVirgulaRegional_EnviaPonto;
var
  LProduto: TProduto;
begin
  FormatSettings.DecimalSeparator := ',';
  FHttp.Enfileirar(201, '{"id":9,"descricao":"Headset gamer USB","preco":279.9,"estoque":25}');
  LProduto := TProduto.Create;
  try
    LProduto.Descricao := 'Headset gamer USB';
    LProduto.Preco := 279.90;
    LProduto.Estoque := 25;
    FProdutos.Criar(LProduto).Free;
    Assert.AreEqual('{"descricao":"Headset gamer USB","preco":279.9,"estoque":25}', FHttp.Chamadas[0].Corpo);
  finally
    LProduto.Free;
  end;
end;

procedure TTestClienteProduto.Produto_Listar_ConvertePrecoEEstoque;
var
  LPagina: TPagina<TProduto>;
begin
  FHttp.Enfileirar(200, '{"dados":[{"id":1,"descricao":"Teclado mecânico","preco":349.9,"estoque":15}],' +
    '"pagina":1,"limite":20,"total":1}');
  LPagina := FProdutos.Listar(1, 20, 'mecânico');
  try
    Assert.AreEqual('http://api.teste/produtos?pagina=1&limite=20&busca=mec%C3%A2nico', FHttp.Chamadas[0].Url);
    Assert.AreEqual('Teclado mecânico', LPagina.Dados[0].Descricao);
    Assert.AreEqual(Currency(349.9), LPagina.Dados[0].Preco);
    Assert.AreEqual(15, LPagina.Dados[0].Estoque);
  finally
    LPagina.Free;
  end;
end;

procedure TTestClienteProduto.Service_ClienteSemNome_NaoChamaApi;
var
  LService: IClienteService;
  LCliente: TCliente;
begin
  LService := TClienteService.Create(FClientes);
  LCliente := TCliente.Create;
  try
    LCliente.Documento := '39053344705';
    Assert.WillRaiseWithMessage(procedure begin LService.Criar(LCliente).Free end,
      EValidacao, 'Informe o nome.');
    Assert.AreEqual(0, FHttp.Chamadas.Count);
  finally
    LCliente.Free;
  end;
end;

procedure TTestClienteProduto.Service_ClienteSemDocumento_LevantaValidacao;
var
  LService: IClienteService;
  LCliente: TCliente;
begin
  LService := TClienteService.Create(FClientes);
  LCliente := TCliente.Create;
  try
    LCliente.Nome := 'Ana';
    Assert.WillRaiseWithMessage(procedure begin LService.Atualizar(LCliente).Free end,
      EValidacao, 'Informe o CPF ou CNPJ.');
  finally
    LCliente.Free;
  end;
end;

procedure TTestClienteProduto.Service_ProdutoSemDescricao_LevantaValidacao;
var
  LService: IProdutoService;
  LProduto: TProduto;
begin
  LService := TProdutoService.Create(FProdutos);
  LProduto := TProduto.Create;
  try
    LProduto.Descricao := '   ';
    Assert.WillRaiseWithMessage(procedure begin LService.Criar(LProduto).Free end,
      EValidacao, 'Informe a descrição.');
    Assert.AreEqual(0, FHttp.Chamadas.Count);
  finally
    LProduto.Free;
  end;
end;

procedure TTestClienteProduto.Pagina_TotalPaginas;
var
  LPagina: TPagina<TCliente>;
begin
  LPagina := TPagina<TCliente>.Create;
  try
    LPagina.Limite := 20;
    LPagina.Total := 0;
    Assert.AreEqual(1, LPagina.TotalPaginas);
    LPagina.Total := 40;
    Assert.AreEqual(2, LPagina.TotalPaginas);
    LPagina.Total := 41;
    Assert.AreEqual(3, LPagina.TotalPaginas);
  finally
    LPagina.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestClienteProduto);

end.
