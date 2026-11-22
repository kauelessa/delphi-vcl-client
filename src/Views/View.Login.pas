unit View.Login;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCheckBox, Vcl.Menus, Vcl.StdCtrls, cxButtons, dxPanel,
  Controller.Login;

type
  TfrmLogin = class(TForm)
    pnlCartao: TdxPanel;
    lblTitulo: TcxLabel;
    lblSubtitulo: TcxLabel;
    lblPerfil: TcxLabel;
    cbPerfil: TcxComboBox;
    lblUsuario: TcxLabel;
    edtUsuario: TcxTextEdit;
    lblSenha: TcxLabel;
    edtSenha: TcxTextEdit;
    chkLembrarUsuario: TcxCheckBox;
    chkLembrarSenha: TcxCheckBox;
    lblErro: TcxLabel;
    btnEntrar: TcxButton;
    btnSair: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnEntrarClick(Sender: TObject);
    procedure chkLembrarUsuarioPropertiesChange(Sender: TObject);
  private
    FController: TLoginController;
    FEntrando: Boolean;
    procedure DefinirOcupado(AOcupado: Boolean);
    procedure MostrarErro(const AMensagem: string);
  public
    /// Mostra o login. True = entrou; False = usuário desistiu.
    class function Executar: Boolean;
  end;

implementation

{$R *.dfm}

uses
  Infra.Config, Infra.Async, Service.Sessao, View.Estilo;

class function TfrmLogin.Executar: Boolean;
var
  LForm: TfrmLogin;
begin
  LForm := TfrmLogin.Create(nil);
  try
    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
var
  LPerfil: TPerfilApi;
  LLembradas: TCredenciaisLembradas;
begin
  FController := TLoginController.Create;
  ArredondarCartao(pnlCartao);
  EstilizarBotao(btnEntrar, TFuncaoBotao.Novo);
  EstilizarBotao(btnSair, TFuncaoBotao.Neutro);
  lblTitulo.Style.Font.Size := 20;
  lblTitulo.Style.Font.Style := [fsBold];
  lblTitulo.Style.TextColor := COR_MARCA;
  lblSubtitulo.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblErro.Style.TextColor := COR_ERRO;
  lblErro.Caption := '';

  for LPerfil in FController.Perfis do
    cbPerfil.Properties.Items.Add(Format('%s  (%s)', [LPerfil.Nome, LPerfil.Url]));
  cbPerfil.ItemIndex := FController.IndicePerfilLembrado;

  LLembradas := FController.Lembradas;
  edtUsuario.Text := LLembradas.Usuario;
  edtSenha.Text := LLembradas.Senha;
  chkLembrarUsuario.Checked := LLembradas.LembrarUsuario;
  chkLembrarSenha.Checked := LLembradas.LembrarSenha;
  chkLembrarUsuarioPropertiesChange(nil);
end;

procedure TfrmLogin.FormDestroy(Sender: TObject);
begin
  FController.Free;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  if edtUsuario.Text = '' then
    edtUsuario.SetFocus
  else if edtSenha.Text = '' then
    edtSenha.SetFocus
  else
    btnEntrar.SetFocus;
end;

procedure TfrmLogin.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // não fecha com a chamada em andamento: o retorno dela usaria o form já liberado
  CanClose := not FEntrando;
end;

procedure TfrmLogin.chkLembrarUsuarioPropertiesChange(Sender: TObject);
begin
  chkLembrarSenha.Enabled := chkLembrarUsuario.Checked;
  if not chkLembrarUsuario.Checked then
    chkLembrarSenha.Checked := False;
end;

procedure TfrmLogin.DefinirOcupado(AOcupado: Boolean);
begin
  FEntrando := AOcupado;
  btnEntrar.Enabled := not AOcupado;
  btnSair.Enabled := not AOcupado;
  cbPerfil.Enabled := not AOcupado;
  edtUsuario.Enabled := not AOcupado;
  edtSenha.Enabled := not AOcupado;
  if AOcupado then
  begin
    btnEntrar.Caption := 'Entrando...';
    Screen.Cursor := crAppStart;
  end
  else
  begin
    btnEntrar.Caption := 'Entrar';
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmLogin.MostrarErro(const AMensagem: string);
begin
  lblErro.Caption := AMensagem;
end;

procedure TfrmLogin.btnEntrarClick(Sender: TObject);
var
  LPerfil: Integer;
  LUsuario, LSenha: string;
  LLembrarUsuario, LLembrarSenha: Boolean;
begin
  if FEntrando then
    Exit;
  // copia o que está na tela antes de sair da thread principal
  LPerfil := cbPerfil.ItemIndex;
  LUsuario := edtUsuario.Text;
  LSenha := edtSenha.Text;
  LLembrarUsuario := chkLembrarUsuario.Checked;
  LLembrarSenha := chkLembrarSenha.Checked;
  MostrarErro('');
  DefinirOcupado(True);
  ExecutarAsync(
    procedure
    begin
      FController.Entrar(LPerfil, LUsuario, LSenha, LLembrarUsuario, LLembrarSenha);
    end,
    procedure
    begin
      DefinirOcupado(False);
      ModalResult := mrOk;
    end,
    procedure(E: Exception)
    begin
      DefinirOcupado(False);
      MostrarErro(E.Message);
      edtSenha.SetFocus;
      edtSenha.SelectAll;
    end);
end;

end.
