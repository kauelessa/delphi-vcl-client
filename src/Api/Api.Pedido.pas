unit Api.Pedido;

interface

uses
  Model.Pedido, Model.Pagina, Api.Base;

type
  // objetos devolvidos são do chamador (libere com Free)
  IPedidoApi = interface
    ['{93D7B1E4-6A0C-4F25-8C3B-E5A1D7F2C946}']
    /// AClienteId = 0 lista de todos os clientes.
    function Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
    function Obter(AId: Integer): TPedido;
    function Criar(AClienteId: Integer; const AItens: TArray<TItemNovo>): TPedido;
    function Cancelar(AId: Integer): TPedido;
  end;

  TPedidoApi = class(TApiBase, IPedidoApi)
  public
    function Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
    function Obter(AId: Integer): TPedido;
    function Criar(AClienteId: Integer; const AItens: TArray<TItemNovo>): TPedido;
    function Cancelar(AId: Integer): TPedido;
  end;

implementation

uses
  System.SysUtils, System.JSON, Infra.Http, Infra.Json;

function PedidoDeJson(AJson: TJSONObject): TPedido;
var
  LCliente: TJSONObject;
  LItens: TJSONArray;
  LValor: TJSONValue;
  LJsonItem: TJSONObject;
  LItem: TItemPedido;
begin
  Result := TPedido.Create;
  try
    Result.Id := LerInteiro(AJson, 'id');
    if AJson.TryGetValue<TJSONObject>('cliente', LCliente) then
    begin
      Result.ClienteId := LerInteiro(LCliente, 'id');
      Result.ClienteNome := LerTexto(LCliente, 'nome');
    end;
    Result.Data := LerDataHora(AJson, 'data');
    Result.Status := TStatusPedido.DoTexto(LerTexto(AJson, 'status'));
    Result.ValorTotal := LerCurrency(AJson, 'valorTotal');
    if AJson.TryGetValue<TJSONArray>('itens', LItens) then
      for LValor in LItens do
      begin
        LJsonItem := LValor as TJSONObject;
        LItem := TItemPedido.Create;
        Result.Itens.Add(LItem);
        LItem.Id := LerInteiro(LJsonItem, 'id');
        LItem.ProdutoId := LerInteiro(LJsonItem, 'produtoId');
        LItem.Descricao := LerTexto(LJsonItem, 'descricao');
        LItem.Quantidade := LerInteiro(LJsonItem, 'quantidade');
        LItem.PrecoUnitario := LerCurrency(LJsonItem, 'precoUnitario');
        LItem.ValorTotal := LerCurrency(LJsonItem, 'valorTotal');
      end;
  except
    Result.Free;
    raise;
  end;
end;

function PedidoDoTexto(const AJson: string): TPedido;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := PedidoDeJson(LJson);
  finally
    LJson.Free;
  end;
end;

function TPedidoApi.Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
var
  LCliente: string;
begin
  if AClienteId > 0 then
    LCliente := AClienteId.ToString
  else
    LCliente := '';
  Result := LerPagina<TPedido>(
    Enviar(THttpMetodo.Get, RotaPaginada('/pedidos', APagina, ALimite, 'clienteId', LCliente)),
    PedidoDeJson);
end;

function TPedidoApi.Obter(AId: Integer): TPedido;
begin
  Result := PedidoDoTexto(Enviar(THttpMetodo.Get, '/pedidos/' + AId.ToString));
end;

function TPedidoApi.Criar(AClienteId: Integer; const AItens: TArray<TItemNovo>): TPedido;
var
  LJson: TJSONObject;
  LItens: TJSONArray;
  LItem: TItemNovo;
  LCorpo: string;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('clienteId', TJSONNumber.Create(AClienteId));
    LItens := TJSONArray.Create;
    LJson.AddPair('itens', LItens);
    for LItem in AItens do
      LItens.AddElement(TJSONObject.Create
        .AddPair('produtoId', TJSONNumber.Create(LItem.ProdutoId))
        .AddPair('quantidade', TJSONNumber.Create(LItem.Quantidade)));
    LCorpo := LJson.ToJSON;
  finally
    LJson.Free;
  end;
  Result := PedidoDoTexto(Enviar(THttpMetodo.Post, '/pedidos', LCorpo));
end;

function TPedidoApi.Cancelar(AId: Integer): TPedido;
begin
  // corpo "{}" porque o middleware JSON da API recusa PATCH com corpo vazio (400)
  Result := PedidoDoTexto(Enviar(THttpMetodo.Patch, '/pedidos/' + AId.ToString + '/cancelar', '{}'));
end;

end.
