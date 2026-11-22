unit Controller.Fabrica;

// Monta os services com as implementações reais (HTTP de verdade, logs em arquivo).

interface

uses
  Api.Health, Service.Sessao, Service.Cliente, Service.Produto, Service.Pedido;

type
  TFabrica = class
  public
    class function Sessao: ISessaoService; static;
    class function Clientes: IClienteService; static;
    class function Produtos: IProdutoService; static;
    class function Pedidos: IPedidoService; static;
    class function Health: IHealthApi; static;
  end;

implementation

uses
  Infra.Config, Infra.Http, Infra.LogHttp, Infra.Preferencias, Api.Auth, Api.Cliente,
  Api.Produto, Api.Pedido, Service.Rascunho;

var
  GHttp: IHttpClient;
  GSessao: ISessaoService;

function Http: IHttpClient;
begin
  // o adaptador não guarda estado (cria um THTTPClient por chamada), então um só serve para tudo
  if GHttp = nil then
    GHttp := TNetHttpClientAdapter.Create(Config.TimeoutMs, TLogHttpArquivo.Create(Config.PastaLog, Config.LogHttp));
  Result := GHttp;
end;

class function TFabrica.Sessao: ISessaoService;
begin
  if GSessao = nil then
    GSessao := TSessaoService.Create(TAuthApi.Create(Http), Preferencias);
  Result := GSessao;
end;

class function TFabrica.Clientes: IClienteService;
begin
  Result := TClienteService.Create(TClienteApi.Create(Http, Sessao));
end;

class function TFabrica.Produtos: IProdutoService;
begin
  Result := TProdutoService.Create(TProdutoApi.Create(Http, Sessao));
end;

class function TFabrica.Pedidos: IPedidoService;
begin
  Result := TPedidoService.Create(TPedidoApi.Create(Http, Sessao), TRascunhoArquivo.Create(ArquivoRascunhoPadrao));
end;

class function TFabrica.Health: IHealthApi;
begin
  Result := THealthApi.Create(Http);
end;

initialization

finalization
  GSessao := nil;
  GHttp := nil;

end.
