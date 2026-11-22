unit Model.Pedido;

interface

uses
  System.Generics.Collections;

type
  {$SCOPEDENUMS ON}
  TStatusPedido = (Aberto, Cancelado);
  {$SCOPEDENUMS OFF}

  TStatusPedidoHelper = record helper for TStatusPedido
    class function DoTexto(const ATexto: string): TStatusPedido; static;
    function Descricao: string;
  end;

  TItemPedido = class
  public
    Id: Integer;
    ProdutoId: Integer;
    Descricao: string;
    Quantidade: Integer;
    PrecoUnitario: Currency;
    ValorTotal: Currency;
  end;

  TPedido = class
  private
    FItens: TObjectList<TItemPedido>;
  public
    Id: Integer;
    ClienteId: Integer;
    ClienteNome: string;
    Data: TDateTime;
    Status: TStatusPedido;
    ValorTotal: Currency;
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TItemPedido> read FItens;
  end;

  // item enviado no POST /pedidos
  TItemNovo = record
    ProdutoId: Integer;
    Quantidade: Integer;
  end;

implementation

uses
  System.SysUtils;

{ TStatusPedidoHelper }

class function TStatusPedidoHelper.DoTexto(const ATexto: string): TStatusPedido;
begin
  if SameText(ATexto, 'CANCELADO') then
    Result := TStatusPedido.Cancelado
  else
    Result := TStatusPedido.Aberto;
end;

function TStatusPedidoHelper.Descricao: string;
begin
  case Self of
    TStatusPedido.Cancelado: Result := 'CANCELADO';
  else
    Result := 'ABERTO';
  end;
end;

{ TPedido }

constructor TPedido.Create;
begin
  inherited Create;
  FItens := TObjectList<TItemPedido>.Create(True);
end;

destructor TPedido.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
