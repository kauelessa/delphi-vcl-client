unit View.Relogin;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel,
  cxTextEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons, dxPanel;

type
  TfrmRelogin = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    lblMensagem: TcxLabel;
    edtSenha: TcxTextEdit;
    btnCancelar: TcxButton;
    btnContinuar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    /// Diálogo modal de sessão expirada. False = cancelou.
    class function PedirSenha(const AUsuario: string; out ASenha: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  View.Estilo;

class function TfrmRelogin.PedirSenha(const AUsuario: string; out ASenha: string): Boolean;
var
  LForm: TfrmRelogin;
begin
  LForm := TfrmRelogin.Create(nil);
  try
    LForm.lblMensagem.Caption := Format('Sua sessão expirou. Digite a senha de %s para continuar ' +
      'de onde parou.', [AUsuario]);
    Result := LForm.ShowModal = mrOk;
    if Result then
      ASenha := LForm.edtSenha.Text;
  finally
    LForm.Free;
  end;
end;

procedure TfrmRelogin.FormCreate(Sender: TObject);
begin
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnContinuar, TFuncaoBotao.Novo);
  EstilizarBotao(btnCancelar, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 14;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_TEXTO;
  lblMensagem.Style.TextColor := COR_TEXTO_SECUNDARIO;
end;

procedure TfrmRelogin.FormShow(Sender: TObject);
begin
  edtSenha.SetFocus;
end;

end.
