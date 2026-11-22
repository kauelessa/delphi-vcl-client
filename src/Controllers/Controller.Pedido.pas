unit Controller.Pedido;

// Listar/Obter/Cancelar/Enviar fazem chamada de rede: a tela as roda com ExecutarAsync.
// Sem estado (métodos de classe): a tela pode ser fechada no meio da chamada sem problema.

interface

uses
  System.SysUtils, Model.Pedido, Model.Pagina, Model.PedidoDigitacao;

type
  TPedidoController = class
  public
    class function Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>; static;
    class function Obter(AId: Integer): TPedido; static;
    class function Cancelar(AId: Integer): TPedido; static;
    class function LerAssinatura(AId: Integer): TBytes; static;
    /// Sucesso apaga o rascunho; erro mantém.
    class function Enviar(APedido: TPedidoEmDigitacao): TPedido; static;
    // rascunho em disco (rápido, pode rodar na thread principal)
    class function ExisteRascunho: Boolean; static;
    /// nil se não houver. O objeto é do chamador.
    class function CarregarRascunho: TPedidoEmDigitacao; static;
    class procedure SalvarRascunho(APedido: TPedidoEmDigitacao); static;
    class procedure DescartarRascunho; static;
  end;

implementation

uses
  Controller.Fabrica;

class function TPedidoController.Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>;
begin
  Result := TFabrica.Pedidos.Listar(APagina, ALimite, AClienteId);
end;

class function TPedidoController.Obter(AId: Integer): TPedido;
begin
  Result := TFabrica.Pedidos.Obter(AId);
end;

class function TPedidoController.Cancelar(AId: Integer): TPedido;
begin
  Result := TFabrica.Pedidos.Cancelar(AId);
end;

class function TPedidoController.LerAssinatura(AId: Integer): TBytes;
begin
  Result := TFabrica.Pedidos.LerAssinatura(AId);
end;

class function TPedidoController.Enviar(APedido: TPedidoEmDigitacao): TPedido;
begin
  Result := TFabrica.Pedidos.Enviar(APedido);
end;

class function TPedidoController.ExisteRascunho: Boolean;
begin
  Result := TFabrica.Pedidos.Rascunho.Existe;
end;

class function TPedidoController.CarregarRascunho: TPedidoEmDigitacao;
begin
  Result := TFabrica.Pedidos.Rascunho.Carregar;
end;

class procedure TPedidoController.SalvarRascunho(APedido: TPedidoEmDigitacao);
begin
  TFabrica.Pedidos.Rascunho.Salvar(APedido);
end;

class procedure TPedidoController.DescartarRascunho;
begin
  TFabrica.Pedidos.Rascunho.Descartar;
end;

end.
