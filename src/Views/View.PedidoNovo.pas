unit View.PedidoNovo;

{
  Montagem do pedido: cliente, produtos e quantidades, com total ao vivo.
  Cada alteração vai para o rascunho em disco; se o programa fechar ou a API
  cair, o pedido volta na próxima vez que esta tela abrir.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Menus, Vcl.StdCtrls, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxGridCustomTableView, cxGridTableView, cxGridCustomView,
  cxClasses, cxGridLevel, cxGrid, cxLabel, cxTextEdit, cxMaskEdit, cxSpinEdit, cxButtons,
  cxCurrencyEdit, dxPanel, Model.PedidoDigitacao;

type
  TfrmPedidoNovo = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    lblClienteTitulo: TcxLabel;
    lblCliente: TcxLabel;
    btnEscolherCliente: TcxButton;
    lblQuantidade: TcxLabel;
    edtQuantidade: TcxSpinEdit;
    btnAdicionarProduto: TcxButton;
    btnAlterarQuantidade: TcxButton;
    grdItens: TcxGrid;
    tvItens: TcxGridTableView;
    colProduto: TcxGridColumn;
    colQuantidade: TcxGridColumn;
    colPreco: TcxGridColumn;
    colTotal: TcxGridColumn;
    lvItens: TcxGridLevel;
    btnRemover: TcxButton;
    lblTotal: TcxLabel;
    btnFechar: TcxButton;
    btnEnviar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnEscolherClienteClick(Sender: TObject);
    procedure btnAdicionarProdutoClick(Sender: TObject);
    procedure btnAlterarQuantidadeClick(Sender: TObject);
    procedure btnRemoverClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure tvItensFocusedRecordChanged(Sender: TcxCustomGridTableView; APrevFocusedRecord,
      AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
  private
    FPedido: TPedidoEmDigitacao;
    FOcupado: Boolean;
    procedure OferecerRascunho;
    procedure Alterou;
    procedure Atualizar;
    procedure AtualizarBotoes;
    procedure DefinirOcupado(AOcupado: Boolean);
  public
    /// True = enviou um pedido.
    class function Executar: Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes, Vcl.Dialogs, Model.Pedido, Model.Cliente, Model.Produto, Infra.Async,
  Controller.Pedido, View.Estilo, View.Seletor;

class function TfrmPedidoNovo.Executar: Boolean;
var
  LForm: TfrmPedidoNovo;
begin
  LForm := TfrmPedidoNovo.Create(nil);
  try
    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfrmPedidoNovo.FormCreate(Sender: TObject);
begin
  FPedido := TPedidoEmDigitacao.Create;
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnEnviar, TFuncaoBotao.Novo);
  EstilizarBotao(btnEscolherCliente, TFuncaoBotao.Neutro);
  EstilizarBotao(btnAdicionarProduto, TFuncaoBotao.Editar);
  EstilizarBotao(btnAlterarQuantidade, TFuncaoBotao.Neutro);
  EstilizarBotao(btnRemover, TFuncaoBotao.Perigo);
  EstilizarBotao(btnFechar, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 14;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_TEXTO;
  lblClienteTitulo.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblQuantidade.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblCliente.Style.Font.Style := [fsBold];
  lblTotal.Style.Font.Size := 13;
  lblTotal.Style.Font.Style := [fsBold];
  lblTotal.Style.TextColor := COR_MARCA;
end;

procedure TfrmPedidoNovo.FormDestroy(Sender: TObject);
begin
  FPedido.Free;
end;

procedure TfrmPedidoNovo.FormShow(Sender: TObject);
begin
  OferecerRascunho;
  Atualizar;
end;

procedure TfrmPedidoNovo.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // fechar não perde nada: o rascunho continua salvo para a próxima vez
  CanClose := not FOcupado;
end;

procedure TfrmPedidoNovo.OferecerRascunho;
var
  LRascunho: TPedidoEmDigitacao;
  LCliente: string;
begin
  if not TPedidoController.ExisteRascunho then
    Exit;
  LRascunho := TPedidoController.CarregarRascunho;
  if LRascunho = nil then
  begin
    TPedidoController.DescartarRascunho; // arquivo ilegível não serve para nada
    Exit;
  end;

  if LRascunho.ClienteNome <> '' then
    LCliente := LRascunho.ClienteNome
  else
    LCliente := 'cliente ainda não escolhido';
  if MessageDlg(Format('Há um pedido não enviado (%s, %d item(ns)). Continuar de onde parou?',
    [LCliente, LRascunho.Itens.Count]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FPedido.Free;
    FPedido := LRascunho;
  end
  else
  begin
    LRascunho.Free;
    TPedidoController.DescartarRascunho;
  end;
end;

procedure TfrmPedidoNovo.Alterou;
begin
  if (FPedido.ClienteId = 0) and (FPedido.Itens.Count = 0) then
    TPedidoController.DescartarRascunho
  else
    TPedidoController.SalvarRascunho(FPedido);
  Atualizar;
end;

procedure TfrmPedidoNovo.Atualizar;
var
  I, LFoco: Integer;
  LItem: TItemDigitado;
begin
  if FPedido.ClienteId = 0 then
    lblCliente.Caption := 'Nenhum cliente escolhido'
  else
    lblCliente.Caption := FPedido.ClienteNome;

  LFoco := tvItens.DataController.FocusedRecordIndex;
  tvItens.BeginUpdate;
  try
    tvItens.DataController.RecordCount := FPedido.Itens.Count;
    for I := 0 to FPedido.Itens.Count - 1 do
    begin
      LItem := FPedido.Itens[I];
      tvItens.DataController.Values[I, colProduto.Index] := LItem.Descricao;
      tvItens.DataController.Values[I, colQuantidade.Index] := LItem.Quantidade;
      tvItens.DataController.Values[I, colPreco.Index] := LItem.PrecoUnitario;
      tvItens.DataController.Values[I, colTotal.Index] := LItem.PrecoUnitario * LItem.Quantidade;
    end;
  finally
    tvItens.EndUpdate;
  end;
  if (LFoco >= 0) and (LFoco < FPedido.Itens.Count) then
    tvItens.DataController.FocusedRecordIndex := LFoco;

  lblTotal.Caption := 'Total: ' + FormatCurr('R$ ,0.00', FPedido.Total);
  AtualizarBotoes;
end;

procedure TfrmPedidoNovo.AtualizarBotoes;
var
  LTemItem: Boolean;
begin
  LTemItem := tvItens.DataController.FocusedRecordIndex >= 0;
  btnEscolherCliente.Enabled := not FOcupado;
  btnAdicionarProduto.Enabled := not FOcupado;
  btnAlterarQuantidade.Enabled := not FOcupado and LTemItem;
  btnRemover.Enabled := not FOcupado and LTemItem;
  btnFechar.Enabled := not FOcupado;
  btnEnviar.Enabled := not FOcupado and (FPedido.ClienteId > 0) and (FPedido.Itens.Count > 0);
end;

procedure TfrmPedidoNovo.DefinirOcupado(AOcupado: Boolean);
begin
  FOcupado := AOcupado;
  if AOcupado then
  begin
    btnEnviar.Caption := 'Enviando...';
    Screen.Cursor := crAppStart;
  end
  else
  begin
    btnEnviar.Caption := 'Enviar pedido';
    Screen.Cursor := crDefault;
  end;
  AtualizarBotoes;
end;

procedure TfrmPedidoNovo.tvItensFocusedRecordChanged(Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  LIndice: Integer;
begin
  LIndice := tvItens.DataController.FocusedRecordIndex;
  // quantidade do item focado vai para o campo, pronta para ser alterada
  if (LIndice >= 0) and (LIndice < FPedido.Itens.Count) then
    edtQuantidade.Value := FPedido.Itens[LIndice].Quantidade;
  AtualizarBotoes;
end;

procedure TfrmPedidoNovo.btnEscolherClienteClick(Sender: TObject);
var
  LCliente: TCliente;
begin
  if not TfrmSeletor.EscolherCliente(LCliente) then
    Exit;
  try
    FPedido.ClienteId := LCliente.Id;
    FPedido.ClienteNome := LCliente.Nome;
  finally
    LCliente.Free;
  end;
  Alterou;
end;

procedure TfrmPedidoNovo.btnAdicionarProdutoClick(Sender: TObject);
var
  LProduto: TProduto;
begin
  if not TfrmSeletor.EscolherProduto(LProduto) then
    Exit;
  try
    FPedido.AdicionarProduto(LProduto, edtQuantidade.Value);
  finally
    LProduto.Free;
  end;
  Alterou;
end;

procedure TfrmPedidoNovo.btnAlterarQuantidadeClick(Sender: TObject);
var
  LIndice: Integer;
begin
  LIndice := tvItens.DataController.FocusedRecordIndex;
  if LIndice < 0 then
    Exit;
  FPedido.AlterarQuantidade(LIndice, edtQuantidade.Value);
  Alterou;
end;

procedure TfrmPedidoNovo.btnRemoverClick(Sender: TObject);
var
  LIndice: Integer;
begin
  LIndice := tvItens.DataController.FocusedRecordIndex;
  if LIndice < 0 then
    Exit;
  FPedido.RemoverItem(LIndice);
  Alterou;
end;

procedure TfrmPedidoNovo.btnEnviarClick(Sender: TObject);
var
  LCriado: TPedido;
begin
  if FOcupado then
    Exit;
  LCriado := nil;
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      LCriado := TPedidoController.Enviar(FPedido);
    end,
    procedure
    begin
      try
        DefinirOcupado(False);
        MessageDlg(Format('Pedido Nº %d criado. Total: %s.', [LCriado.Id,
          FormatCurr('R$ ,0.00', LCriado.ValorTotal)]), mtInformation, [mbOK], 0);
      finally
        LCriado.Free;
      end;
      ModalResult := mrOk;
    end,
    procedure(E: Exception)
    begin
      // o rascunho continua salvo: dá para corrigir (ex.: quantidade acima do estoque) e reenviar
      DefinirOcupado(False);
      MostrarErro(E);
    end);
end;

end.
