unit View.PedidoDetalhe;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Menus, Vcl.StdCtrls, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxGridCustomTableView, cxGridTableView, cxGridCustomView,
  cxClasses, cxGridLevel, cxGrid, cxLabel, cxButtons, cxCurrencyEdit, dxPanel, Model.Pedido;

type
  TfrmPedidoDetalhe = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    lblCliente: TcxLabel;
    lblData: TcxLabel;
    lblStatus: TcxLabel;
    grdItens: TcxGrid;
    tvItens: TcxGridTableView;
    colProduto: TcxGridColumn;
    colQuantidade: TcxGridColumn;
    colPreco: TcxGridColumn;
    colTotal: TcxGridColumn;
    lvItens: TcxGridLevel;
    lblTotal: TcxLabel;
    btnFechar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FId: Integer;
    FOcupado: Boolean;
    procedure Exibir(APedido: TPedido);
  public
    class procedure Mostrar(AId: Integer);
  end;

implementation

{$R *.dfm}

uses
  Infra.Async, Controller.Pedido, View.Estilo;

class procedure TfrmPedidoDetalhe.Mostrar(AId: Integer);
var
  LForm: TfrmPedidoDetalhe;
begin
  LForm := TfrmPedidoDetalhe.Create(nil);
  try
    LForm.FId := AId;
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TfrmPedidoDetalhe.FormCreate(Sender: TObject);
begin
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnFechar, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 14;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_TEXTO;
  lblCliente.Style.TextColor := COR_TEXTO;
  lblData.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblStatus.Style.Font.Style := [fsBold];
  lblTotal.Style.Font.Size := 12;
  lblTotal.Style.Font.Style := [fsBold];
  lblTotal.Style.TextColor := COR_TEXTO;
end;

procedure TfrmPedidoDetalhe.FormShow(Sender: TObject);
var
  LPedido: TPedido;
begin
  lblTitulo.Caption := Format('Pedido Nº %d', [FId]);
  lblCliente.Caption := 'Carregando...';
  lblData.Caption := '';
  lblStatus.Caption := '';
  lblTotal.Caption := '';
  LPedido := nil;
  FOcupado := True;
  ExecutarAsync(
    procedure
    begin
      LPedido := TPedidoController.Obter(FId);
    end,
    procedure
    begin
      FOcupado := False;
      try
        Exibir(LPedido);
      finally
        LPedido.Free;
      end;
    end,
    procedure(E: Exception)
    begin
      FOcupado := False;
      MostrarErro(E);
      ModalResult := mrCancel;
    end);
end;

procedure TfrmPedidoDetalhe.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FOcupado;
end;

procedure TfrmPedidoDetalhe.Exibir(APedido: TPedido);
var
  I: Integer;
  LItem: TItemPedido;
begin
  lblCliente.Caption := APedido.ClienteNome;
  lblData.Caption := FormatDateTime('dd/mm/yyyy "às" hh:nn', APedido.Data);
  lblStatus.Caption := APedido.Status.Descricao;
  if APedido.Status = TStatusPedido.Aberto then
    lblStatus.Style.TextColor := COR_SUCESSO
  else
    lblStatus.Style.TextColor := COR_ERRO;
  lblTotal.Caption := 'Total: ' + FormatCurr('R$ ,0.00', APedido.ValorTotal);

  tvItens.BeginUpdate;
  try
    tvItens.DataController.RecordCount := APedido.Itens.Count;
    for I := 0 to APedido.Itens.Count - 1 do
    begin
      LItem := APedido.Itens[I];
      tvItens.DataController.Values[I, colProduto.Index] := LItem.Descricao;
      tvItens.DataController.Values[I, colQuantidade.Index] := LItem.Quantidade;
      tvItens.DataController.Values[I, colPreco.Index] := LItem.PrecoUnitario;
      tvItens.DataController.Values[I, colTotal.Index] := LItem.ValorTotal;
    end;
  finally
    tvItens.EndUpdate;
  end;
end;

end.
