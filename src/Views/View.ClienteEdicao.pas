unit View.ClienteEdicao;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel,
  cxTextEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons, dxPanel, Model.Cliente;

type
  TfrmClienteEdicao = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    lblNome: TcxLabel;
    edtNome: TcxTextEdit;
    lblDocumento: TcxLabel;
    edtDocumento: TcxTextEdit;
    lblEmail: TcxLabel;
    edtEmail: TcxTextEdit;
    lblTelefone: TcxLabel;
    edtTelefone: TcxTextEdit;
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
    procedure Preencher(ACliente: TCliente);
  public
    /// AId = 0 cadastra. True = salvou.
    class function Executar(AId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  Infra.Async, Controller.Cliente, View.Estilo;

class function TfrmClienteEdicao.Executar(AId: Integer): Boolean;
var
  LForm: TfrmClienteEdicao;
begin
  LForm := TfrmClienteEdicao.Create(nil);
  try
    LForm.FId := AId;
    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfrmClienteEdicao.FormCreate(Sender: TObject);
begin
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnSalvar, TFuncaoBotao.Editar);
  EstilizarBotao(btnCancelar, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 14;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_TEXTO;
end;

procedure TfrmClienteEdicao.FormShow(Sender: TObject);
var
  LCliente: TCliente;
begin
  if FId = 0 then
  begin
    lblTitulo.Caption := 'Novo cliente';
    edtNome.SetFocus;
    Exit;
  end;

  lblTitulo.Caption := 'Editar cliente';
  LCliente := nil;
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      LCliente := TClienteController.Obter(FId);
    end,
    procedure
    begin
      try
        DefinirOcupado(False);
        Preencher(LCliente);
        edtNome.SetFocus;
      finally
        LCliente.Free;
      end;
    end,
    procedure(E: Exception)
    begin
      DefinirOcupado(False);
      MostrarErro(E);
      ModalResult := mrCancel;
    end);
end;

procedure TfrmClienteEdicao.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // com chamada em andamento o form não pode ser liberado: o retorno usaria os campos
  CanClose := not FOcupado;
end;

procedure TfrmClienteEdicao.Preencher(ACliente: TCliente);
begin
  edtNome.Text := ACliente.Nome;
  edtDocumento.Text := ACliente.DocumentoFormatado;
  edtEmail.Text := ACliente.Email;
  edtTelefone.Text := ACliente.Telefone;
end;

procedure TfrmClienteEdicao.DefinirOcupado(AOcupado: Boolean);
begin
  FOcupado := AOcupado;
  btnSalvar.Enabled := not AOcupado;
  btnCancelar.Enabled := not AOcupado;
  if AOcupado then
    Screen.Cursor := crAppStart
  else
    Screen.Cursor := crDefault;
end;

procedure TfrmClienteEdicao.btnSalvarClick(Sender: TObject);
var
  LCliente: TCliente;
begin
  if FOcupado then
    Exit;
  LCliente := TCliente.Create;
  LCliente.Id := FId;
  LCliente.Nome := edtNome.Text;
  LCliente.Documento := edtDocumento.Text; // a API normaliza (tira pontos, traço e barra)
  LCliente.Email := edtEmail.Text;
  LCliente.Telefone := edtTelefone.Text;
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      TClienteController.Salvar(LCliente).Free;
    end,
    procedure
    begin
      LCliente.Free;
      DefinirOcupado(False);
      ModalResult := mrOk;
    end,
    procedure(E: Exception)
    begin
      LCliente.Free;
      DefinirOcupado(False);
      MostrarErro(E);
    end);
end;

end.
