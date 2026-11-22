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
    // o que o app Força de Vendas e o emissor gravam no pedido
    Origem: string; // 'API' ou 'APP', como vem da API
    VendedorNome: string;
    Observacao: string;
    TemAssinatura: Boolean;
    NotaNumero: Integer; // 0 = ainda não faturado
    NotaSerie: Integer;
    NotaChave: string;
    NotaAutorizadaEm: TDateTime;
    TemLocalizacao: Boolean;
    Latitude: Double;
    Longitude: Double;
    Precisao: Double; // metros
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TItemPedido> read FItens;
    function OrigemDescricao: string;
    function NotaDescricao: string;
  end;

  // item enviado no POST /pedidos
  TItemNovo = record
    ProdutoId: Integer;
    Quantidade: Integer;
  end;

/// Link do OpenStreetMap com um marcador no ponto (sempre com ponto decimal).
function UrlMapa(ALatitude, ALongitude: Double): string;

implementation

uses
  System.SysUtils;

function UrlMapa(ALatitude, ALongitude: Double): string;
begin
  Result := Format('https://www.openstreetmap.org/?mlat=%.6f&mlon=%.6f#map=17/%.6f/%.6f',
    [ALatitude, ALongitude, ALatitude, ALongitude], TFormatSettings.Invariant);
end;

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

function TPedido.OrigemDescricao: string;
begin
  if SameText(Origem, 'APP') then
    Result := 'App'
  else
    Result := 'API';
end;

function TPedido.NotaDescricao: string;
begin
  if NotaNumero = 0 then
    Result := ''
  else
    Result := Format('%d/%d', [NotaNumero, NotaSerie]);
end;

end.
