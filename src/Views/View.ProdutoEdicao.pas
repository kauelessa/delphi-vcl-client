unit View.ProdutoEdicao;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons, dxPanel,
  Model.Produto;

type
  TfrmProdutoEdicao = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    lblDescricao: TcxLabel;
    edtDescricao: TcxTextEdit;
    lblPreco: TcxLabel;
    edtPreco: TcxCurrencyEdit;
    lblEstoque: TcxLabel;
    edtEstoque: TcxSpinEdit;
    lblCodigoBarras: TcxLabel;
    edtCodigoBarras: TcxTextEdit;
    lblDicaEstoque: TcxLabel;
    btnCancelar: TcxButton;
    btnSalvar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnSalvarClick(Sender: TObject);
  private
    FId: Integer;
    FOcupado: Boolean;
    procedure DefinirOcupado(AOcupado: Boolean);
  public
    /// AId = 0 cadastra. True = salvou.
    class function Executar(AId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.Variants, Infra.Async, Controller.Produto, View.Estilo;

class function TfrmProdutoEdicao.Executar(AId: Integer): Boolean;
var
  LForm: TfrmProdutoEdicao;
begin
  LForm := TfrmProdutoEdicao.Create(nil);
  try
    LForm.FId := AId;
    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfrmProdutoEdicao.FormCreate(Sender: TObject);
begin
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnSalvar, TFuncaoBotao.Editar);
  EstilizarBotao(btnCancelar, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 14;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_TEXTO;
  lblDicaEstoque.Style.TextColor := COR_TEXTO_SECUNDARIO;
end;

procedure TfrmProdutoEdicao.FormShow(Sender: TObject);
var
  LProduto: TProduto;
begin
  if FId = 0 then
  begin
    lblTitulo.Caption := 'Novo produto';
    edtDescricao.SetFocus;
    Exit;
  end;

  lblTitulo.Caption := 'Editar produto';
  LProduto := nil;
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      LProduto := TProdutoController.Obter(FId);
    end,
    procedure
    begin
      try
        DefinirOcupado(False);
        edtDescricao.Text := LProduto.Descricao;
        edtPreco.Value := LProduto.Preco;
        edtEstoque.Value := LProduto.Estoque;
        edtCodigoBarras.Text := LProduto.CodigoBarras;
        edtDescricao.SetFocus;
      finally
        LProduto.Free;
      end;
    end,
    procedure(E: Exception)
    begin
      DefinirOcupado(False);
      MostrarErro(E);
      ModalResult := mrCancel;
    end);
end;

procedure TfrmProdutoEdicao.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FOcupado;
end;

procedure TfrmProdutoEdicao.DefinirOcupado(AOcupado: Boolean);
begin
  FOcupado := AOcupado;
  btnSalvar.Enabled := not AOcupado;
  btnCancelar.Enabled := not AOcupado;
  if AOcupado then
    Screen.Cursor := crAppStart
  else
    Screen.Cursor := crDefault;
end;

procedure TfrmProdutoEdicao.btnSalvarClick(Sender: TObject);
var
  LProduto: TProduto;
begin
  if FOcupado then
    Exit;
  LProduto := TProduto.Create;
  LProduto.Id := FId;
  LProduto.Descricao := edtDescricao.Text;
  LProduto.Preco := edtPreco.Value;
  LProduto.Estoque := edtEstoque.Value;
  LProduto.CodigoBarras := edtCodigoBarras.Text;
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      TProdutoController.Salvar(LProduto).Free;
    end,
    procedure
    begin
      LProduto.Free;
      DefinirOcupado(False);
      ModalResult := mrOk;
    end,
    procedure(E: Exception)
    begin
      LProduto.Free;
      DefinirOcupado(False);
      MostrarErro(E);
    end);
end;

end.
