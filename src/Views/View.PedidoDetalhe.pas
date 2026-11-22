unit View.PedidoDetalhe;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Menus, Vcl.StdCtrls, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxGridCustomTableView, cxGridTableView, cxGridCustomView,
  cxClasses, cxGridLevel, cxGrid, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit, dxPanel, cxImage,
  dxGDIPlusClasses, Infra.Async, Model.Pedido;

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
    lblVendedor: TcxLabel;
    lblOrigem: TcxLabel;
    lblNota: TcxLabel;
    lblLocal: TcxLabel;
    btnMapa: TcxButton;
    lblAssinatura: TcxLabel;
    imgAssinatura: TcxImage;
    lblObservacao: TcxLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMapaClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FId: Integer;
    FOcupado: Boolean;
    FVida: ISinalVida;
    FUrlMapa: string;
    procedure Exibir(APedido: TPedido);
    procedure ExibirDadosDoApp(APedido: TPedido);
    procedure CarregarAssinatura;
  public
    class procedure Mostrar(AId: Integer);
  end;

implementation

{$R *.dfm}

uses
  System.Types, Winapi.ShellAPI, Controller.Pedido, View.Estilo;

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
  lblVendedor.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblOrigem.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblNota.Style.Font.Style := [fsBold];
  lblLocal.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblAssinatura.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblObservacao.Style.TextColor := COR_TEXTO_SECUNDARIO;
  EstilizarBotao(btnMapa, TFuncaoBotao.Neutro);
  imgAssinatura.Properties.PopupMenuLayout.MenuItems := [];
  FVida := NovoSinalVida;
end;

procedure TfrmPedidoDetalhe.FormDestroy(Sender: TObject);
begin
  // a assinatura pode chegar depois que a tela fechou
  FVida.Desativar;
end;

procedure TfrmPedidoDetalhe.btnMapaClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(FUrlMapa), nil, nil, SW_SHOWNORMAL);
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
  lblVendedor.Caption := '';
  lblOrigem.Caption := '';
  lblNota.Caption := '';
  lblLocal.Caption := '';
  lblObservacao.Caption := '';
  btnMapa.Visible := False;
  imgAssinatura.Visible := False;
  lblAssinatura.Visible := False;
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
  ExibirDadosDoApp(APedido);

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

procedure TfrmPedidoDetalhe.ExibirDadosDoApp(APedido: TPedido);
begin
  if APedido.VendedorNome <> '' then
    lblVendedor.Caption := 'Vendedor: ' + APedido.VendedorNome;
  lblOrigem.Caption := 'Origem: ' + APedido.OrigemDescricao;

  if APedido.NotaNumero > 0 then
  begin
    lblNota.Caption := 'Faturado na NF-e ' + APedido.NotaDescricao;
    lblNota.Style.TextColor := COR_SUCESSO;
  end
  else
  begin
    lblNota.Caption := 'Ainda não faturado';
    lblNota.Style.TextColor := COR_TEXTO_SECUNDARIO;
  end;

  if APedido.TemLocalizacao then
  begin
    // ponto decimal: com vírgula, "-23,55, -46,63" fica ilegível
    lblLocal.Caption := Format('Local: %.6f, %.6f (±%.0f m)',
      [APedido.Latitude, APedido.Longitude, APedido.Precisao], TFormatSettings.Invariant);
    FUrlMapa := UrlMapa(APedido.Latitude, APedido.Longitude);
    btnMapa.Visible := True;
  end
  else
    lblLocal.Caption := 'Sem localização';

  if APedido.Observacao <> '' then
    lblObservacao.Caption := 'Obs.: ' + APedido.Observacao;

  lblAssinatura.Visible := True;
  if APedido.TemAssinatura then
  begin
    lblAssinatura.Caption := 'Carregando assinatura...';
    CarregarAssinatura;
  end
  else
    lblAssinatura.Caption := 'Sem assinatura';
end;

procedure TfrmPedidoDetalhe.CarregarAssinatura;
var
  LVida: ISinalVida;
  LId: Integer;
  LBytes: TBytes;
begin
  LVida := FVida;
  LId := FId;
  ExecutarAsync(
    procedure
    begin
      LBytes := TPedidoController.LerAssinatura(LId);
    end,
    procedure
    var
      LStream: TBytesStream;
      LImagem: TdxSmartImage;
    begin
      if not LVida.Ativo then
        Exit;
      if Length(LBytes) = 0 then
      begin
        lblAssinatura.Caption := 'Sem assinatura';
        Exit;
      end;
      LStream := TBytesStream.Create(LBytes);
      LImagem := TdxSmartImage.Create;
      try
        try
          LImagem.LoadFromStream(LStream);
          imgAssinatura.Picture.Graphic := LImagem;
          imgAssinatura.Visible := True;
          lblAssinatura.Caption := 'Assinatura do cliente';
        except
          // PNG corrompido não merece diálogo de erro
          lblAssinatura.Caption := 'Assinatura indisponível';
        end;
      finally
        LImagem.Free;
        LStream.Free;
      end;
    end,
    procedure(E: Exception)
    begin
      if LVida.Ativo then
        lblAssinatura.Caption := 'Assinatura indisponível';
    end);
end;

end.
