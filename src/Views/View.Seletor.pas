unit View.Seletor;

{
  Diálogo para escolher um cliente ou um produto, com busca na API. Mostra os
  primeiros 50 resultados da busca; se houver mais, pede para refinar o texto
  (escolher entre centenas de linhas não ajuda ninguém a achar o certo).
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, dxDateRanges, dxScrollbarAnnotations, cxGridCustomTableView,
  cxGridTableView, cxGridCustomView, cxClasses, cxGridLevel, cxGrid, cxLabel, cxTextEdit,
  cxButtons, dxPanel, Model.Cliente, Model.Produto;

type
  {$SCOPEDENUMS ON}
  TModoSeletor = (Cliente, Produto);
  {$SCOPEDENUMS OFF}

  TfrmSeletor = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    edtBusca: TcxTextEdit;
    grdItens: TcxGrid;
    tvItens: TcxGridTableView;
    lvItens: TcxGridLevel;
    lblInfo: TcxLabel;
    btnCancelar: TcxButton;
    btnEscolher: TcxButton;
    tmrBusca: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtBuscaPropertiesChange(Sender: TObject);
    procedure edtBuscaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure tvItensDblClick(Sender: TObject);
    procedure btnEscolherClick(Sender: TObject);
  private
    FModo: TModoSeletor;
    FResultado: TObject; // TPagina<TCliente> ou TPagina<TProduto> da última busca
    FEscolhido: TObject;
    FOcupado: Boolean;
    procedure CriarColunas;
    procedure Buscar;
    procedure Exibir;
    procedure DefinirOcupado(AOcupado: Boolean);
    class function Escolher(AModo: TModoSeletor): TObject; static;
  public
    /// True = escolheu; o objeto devolvido é do chamador.
    class function EscolherCliente(out ACliente: TCliente): Boolean; static;
    class function EscolherProduto(out AProduto: TProduto): Boolean; static;
  end;

implementation

{$R *.dfm}

uses
  cxCurrencyEdit, Model.Pagina, Infra.Async, Controller.Cliente, Controller.Produto, View.Estilo;

const
  LIMITE = 50;

class function TfrmSeletor.Escolher(AModo: TModoSeletor): TObject;
var
  LForm: TfrmSeletor;
begin
  Result := nil;
  LForm := TfrmSeletor.Create(nil);
  try
    LForm.FModo := AModo;
    LForm.CriarColunas;
    if LForm.ShowModal = mrOk then
    begin
      Result := LForm.FEscolhido;
      LForm.FEscolhido := nil;
    end;
  finally
    LForm.Free;
  end;
end;

class function TfrmSeletor.EscolherCliente(out ACliente: TCliente): Boolean;
begin
  ACliente := TCliente(Escolher(TModoSeletor.Cliente));
  Result := ACliente <> nil;
end;

class function TfrmSeletor.EscolherProduto(out AProduto: TProduto): Boolean;
begin
  AProduto := TProduto(Escolher(TModoSeletor.Produto));
  Result := AProduto <> nil;
end;

procedure TfrmSeletor.FormCreate(Sender: TObject);
begin
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnEscolher, TFuncaoBotao.Novo);
  EstilizarBotao(btnCancelar, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 14;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_TEXTO;
  lblInfo.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblInfo.Caption := '';
end;

procedure TfrmSeletor.FormDestroy(Sender: TObject);
begin
  FResultado.Free;
  FEscolhido.Free;
end;

procedure TfrmSeletor.CriarColunas;

  procedure Coluna(const ATitulo: string; ALargura: Integer; const ATipo: string = 'String');
  var
    LColuna: TcxGridColumn;
  begin
    LColuna := tvItens.CreateColumn;
    LColuna.Caption := ATitulo;
    LColuna.Width := ALargura;
    LColuna.DataBinding.ValueType := ATipo;
    if ATipo = 'Currency' then
    begin
      LColuna.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(LColuna.Properties).DisplayFormat := 'R$ ,0.00';
    end;
  end;

begin
  if FModo = TModoSeletor.Cliente then
  begin
    Caption := 'Escolher cliente';
    lblTitulo.Caption := 'Escolher cliente';
    edtBusca.TextHint := 'Nome ou CPF/CNPJ';
    Coluna('Nome', 300);
    Coluna('CPF/CNPJ', 160);
  end
  else
  begin
    Caption := 'Escolher produto';
    lblTitulo.Caption := 'Escolher produto';
    edtBusca.TextHint := 'Descrição do produto';
    Coluna('Descrição', 280);
    Coluna('Preço', 100, 'Currency');
    Coluna('Estoque', 80, 'Integer');
  end;
end;

procedure TfrmSeletor.FormShow(Sender: TObject);
begin
  edtBusca.SetFocus;
  Buscar;
end;

procedure TfrmSeletor.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FOcupado;
end;

procedure TfrmSeletor.DefinirOcupado(AOcupado: Boolean);
begin
  FOcupado := AOcupado;
  btnEscolher.Enabled := not AOcupado;
  btnCancelar.Enabled := not AOcupado;
  if AOcupado then
  begin
    lblInfo.Caption := 'Buscando...';
    Screen.Cursor := crAppStart;
  end
  else
    Screen.Cursor := crDefault;
end;

procedure TfrmSeletor.Buscar;
var
  LBusca: string;
  LModo: TModoSeletor;
  LNovo: TObject;
begin
  if FOcupado then
    Exit;
  LBusca := edtBusca.Text;
  LModo := FModo;
  LNovo := nil;
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      if LModo = TModoSeletor.Cliente then
        LNovo := TClienteController.Listar(1, LIMITE, LBusca)
      else
        LNovo := TProdutoController.Listar(1, LIMITE, LBusca);
    end,
    procedure
    begin
      DefinirOcupado(False);
      FResultado.Free;
      FResultado := LNovo;
      Exibir;
    end,
    procedure(E: Exception)
    begin
      DefinirOcupado(False);
      lblInfo.Caption := '';
      MostrarErro(E);
    end);
end;

procedure TfrmSeletor.Exibir;
var
  I, LQuantidade, LTotal: Integer;
  LClientes: TPagina<TCliente>;
  LProdutos: TPagina<TProduto>;
begin
  tvItens.BeginUpdate;
  try
    if FModo = TModoSeletor.Cliente then
    begin
      LClientes := FResultado as TPagina<TCliente>;
      LQuantidade := LClientes.Dados.Count;
      LTotal := LClientes.Total;
      tvItens.DataController.RecordCount := LQuantidade;
      for I := 0 to LQuantidade - 1 do
      begin
        tvItens.DataController.Values[I, 0] := LClientes.Dados[I].Nome;
        tvItens.DataController.Values[I, 1] := LClientes.Dados[I].DocumentoFormatado;
      end;
    end
    else
    begin
      LProdutos := FResultado as TPagina<TProduto>;
      LQuantidade := LProdutos.Dados.Count;
      LTotal := LProdutos.Total;
      tvItens.DataController.RecordCount := LQuantidade;
      for I := 0 to LQuantidade - 1 do
      begin
        tvItens.DataController.Values[I, 0] := LProdutos.Dados[I].Descricao;
        tvItens.DataController.Values[I, 1] := LProdutos.Dados[I].Preco;
        tvItens.DataController.Values[I, 2] := LProdutos.Dados[I].Estoque;
      end;
    end;
  finally
    tvItens.EndUpdate;
  end;
  if LQuantidade > 0 then
    tvItens.DataController.FocusedRecordIndex := 0;
  if LTotal > LQuantidade then
    lblInfo.Caption := Format('Mostrando %d de %d. Refine a busca para encontrar os outros.', [LQuantidade, LTotal])
  else if LTotal = 1 then
    lblInfo.Caption := '1 encontrado'
  else
    lblInfo.Caption := Format('%d encontrados', [LTotal]);
end;

procedure TfrmSeletor.edtBuscaPropertiesChange(Sender: TObject);
begin
  tmrBusca.Enabled := False;
  tmrBusca.Enabled := True;
end;

procedure TfrmSeletor.edtBuscaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        if tmrBusca.Enabled then
          tmrBuscaTimer(nil)
        else
          btnEscolherClick(nil);
      end;
    VK_DOWN:
      begin
        Key := 0;
        grdItens.SetFocus;
      end;
  end;
end;

procedure TfrmSeletor.tmrBuscaTimer(Sender: TObject);
begin
  tmrBusca.Enabled := False;
  Buscar;
end;

procedure TfrmSeletor.tvItensDblClick(Sender: TObject);
begin
  btnEscolherClick(nil);
end;

procedure TfrmSeletor.btnEscolherClick(Sender: TObject);
var
  LIndice: Integer;
begin
  if FOcupado or (FResultado = nil) then
    Exit;
  LIndice := tvItens.DataController.FocusedRecordIndex;
  if LIndice < 0 then
    Exit;
  // tira o item da página (que é dona dele) e entrega ao chamador
  if FModo = TModoSeletor.Cliente then
    FEscolhido := (FResultado as TPagina<TCliente>).Dados.Extract((FResultado as TPagina<TCliente>).Dados[LIndice])
  else
    FEscolhido := (FResultado as TPagina<TProduto>).Dados.Extract((FResultado as TPagina<TProduto>).Dados[LIndice]);
  ModalResult := mrOk;
end;

end.
