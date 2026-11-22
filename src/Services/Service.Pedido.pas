unit Service.Pedido;

interface

uses
  System.SysUtils, Model.Pedido, Model.Pagina, Model.PedidoDigitacao, Api.Pedido, Service.Rascunho;

type
  IPedidoService = interface
    ['{6C1A8D53-E2F7-4B90-A5C4-3D9B7E1F2A86}']
    function Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
    function Obter(AId: Integer): TPedido;
    function Cancelar(AId: Integer): TPedido;
    function LerAssinatura(AId: Integer): TBytes;
    /// Envia à API. Sucesso descarta o rascunho; erro (inclusive relogin cancelado) mantém.
    function Enviar(APedido: TPedidoEmDigitacao): TPedido;
    function Rascunho: IRascunhoPedido;
  end;

  TPedidoService = class(TInterfacedObject, IPedidoService)
  private
    FApi: IPedidoApi;
    FRascunho: IRascunhoPedido;
  public
    constructor Create(AApi: IPedidoApi; ARascunho: IRascunhoPedido);
    function Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
    function Obter(AId: Integer): TPedido;
    function Cancelar(AId: Integer): TPedido;
    function LerAssinatura(AId: Integer): TBytes;
    function Enviar(APedido: TPedidoEmDigitacao): TPedido;
    function Rascunho: IRascunhoPedido;
  end;

implementation

uses
  Infra.Excecoes;

constructor TPedidoService.Create(AApi: IPedidoApi; ARascunho: IRascunhoPedido);
begin
  inherited Create;
  FApi := AApi;
  FRascunho := ARascunho;
end;

function TPedidoService.Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
begin
  Result := FApi.Listar(APagina, ALimite, AClienteId);
end;

function TPedidoService.Obter(AId: Integer): TPedido;
begin
  Result := FApi.Obter(AId);
end;

function TPedidoService.Cancelar(AId: Integer): TPedido;
begin
  Result := FApi.Cancelar(AId);
end;

function TPedidoService.LerAssinatura(AId: Integer): TBytes;
begin
  Result := FApi.LerAssinatura(AId);
end;

function TPedidoService.Enviar(APedido: TPedidoEmDigitacao): TPedido;
var
  LItens: TArray<TItemNovo>;
  I: Integer;
begin
  if APedido.ClienteId <= 0 then
    raise EValidacao.Create('Escolha o cliente.');
  if APedido.Itens.Count = 0 then
    raise EValidacao.Create('Adicione pelo menos um produto.');

  SetLength(LItens, APedido.Itens.Count);
  for I := 0 to APedido.Itens.Count - 1 do
  begin
    LItens[I].ProdutoId := APedido.Itens[I].ProdutoId;
    LItens[I].Quantidade := APedido.Itens[I].Quantidade;
  end;

  Result := FApi.Criar(APedido.ClienteId, LItens);
  FRascunho.Descartar;
end;

function TPedidoService.Rascunho: IRascunhoPedido;
begin
  Result := FRascunho;
end;

end.
