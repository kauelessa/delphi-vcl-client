unit View.Principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, System.UITypes, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxButtons,
  dxPanel, dxStatusBar, Controller.Principal;

type
  {$SCOPEDENUMS ON}
  TAba = (Pedidos, Clientes, Produtos);
  {$SCOPEDENUMS OFF}

  TfrmPrincipal = class(TForm)
    pnlTopo: TdxPanel;
    lblMarca: TcxLabel;
    btnAbaPedidos: TcxButton;
    btnAbaClientes: TcxButton;
    btnAbaProdutos: TcxButton;
    lblUsuario: TcxLabel;
    pnlConteudo: TdxPanel;
    pnlCartao: TdxPanel;
    sbPrincipal: TdxStatusBar;
    tmrHealth: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAbaClick(Sender: TObject);
    procedure tmrHealthTimer(Sender: TObject);
  private
    FController: TPrincipalController;
    FTela: TCustomFrame;
    FVerificandoHealth: Boolean;
    procedure TratarExcecao(Sender: TObject; E: Exception);
    procedure AtualizarHealth(AOnline: Boolean);
    procedure SelecionarAbaAtual(AAba: TAba);
  public
    procedure AbrirAba(AAba: TAba);
    procedure AbrirTela(AClasse: TCustomFrameClass);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

uses
  Infra.Async, Infra.Excecoes, View.Estilo, View.Relogin, View.ListaBase, View.Clientes, View.Produtos;

const
  PAINEL_SESSAO = 0;
  PAINEL_API = 1;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FController := TPrincipalController.Create;
  Application.OnException := TratarExcecao;
  FController.RegistrarRelogin(TfrmRelogin.PedirSenha);

  ArredondarCartao(pnlCartao);
  lblMarca.Style.Font.Size := 16;
  lblMarca.Style.Font.Style := [fsBold];
  lblMarca.Style.TextColor := COR_MARCA;
  lblUsuario.Style.TextColor := COR_TEXTO_SECUNDARIO;
  EstilizarBotao(btnAbaPedidos, TFuncaoBotao.Aba);
  EstilizarBotao(btnAbaClientes, TFuncaoBotao.Aba);
  EstilizarBotao(btnAbaProdutos, TFuncaoBotao.Aba);

  lblUsuario.Caption := FController.Usuario;
  sbPrincipal.Panels[PAINEL_SESSAO].Text := FController.DescricaoSessao;
  sbPrincipal.Panels[PAINEL_API].Text := '● verificando a API...';
  tmrHealth.Interval := FController.IntervaloHealthMs;
  FController.RestaurarJanela(Self);
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  Application.OnException := nil;
  FController.RegistrarRelogin(nil);
  FController.Free;
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  AbrirAba(TAba.Pedidos);
  tmrHealthTimer(nil);
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrHealth.Enabled := False;
  FController.SalvarJanela(Self);
end;

procedure TfrmPrincipal.SelecionarAbaAtual(AAba: TAba);
begin
  SelecionarAba(btnAbaPedidos, AAba = TAba.Pedidos);
  SelecionarAba(btnAbaClientes, AAba = TAba.Clientes);
  SelecionarAba(btnAbaProdutos, AAba = TAba.Produtos);
end;

procedure TfrmPrincipal.AbrirAba(AAba: TAba);
begin
  SelecionarAbaAtual(AAba);
  case AAba of
    TAba.Clientes: AbrirTela(TfraClientes);
    TAba.Produtos: AbrirTela(TfraProdutos);
  else
    AbrirTela(nil); // pedidos entram na próxima etapa
  end;
end;

procedure TfrmPrincipal.AbrirTela(AClasse: TCustomFrameClass);
begin
  FreeAndNil(FTela);
  if AClasse = nil then
    Exit;
  FTela := AClasse.Create(Self);
  FTela.Parent := pnlCartao;
  FTela.Align := alClient;
  if FTela is TfraListaBase then
    TfraListaBase(FTela).Carregar(1);
end;

procedure TfrmPrincipal.btnAbaClick(Sender: TObject);
begin
  if Sender = btnAbaPedidos then
    AbrirAba(TAba.Pedidos)
  else if Sender = btnAbaClientes then
    AbrirAba(TAba.Clientes)
  else
    AbrirAba(TAba.Produtos);
end;

procedure TfrmPrincipal.tmrHealthTimer(Sender: TObject);
var
  LOnline: Boolean;
begin
  if FVerificandoHealth then
    Exit;
  FVerificandoHealth := True;
  ExecutarAsync(
    procedure
    begin
      LOnline := FController.ApiOnline;
    end,
    procedure
    begin
      FVerificandoHealth := False;
      AtualizarHealth(LOnline);
    end,
    procedure(E: Exception)
    begin
      FVerificandoHealth := False;
      AtualizarHealth(False);
    end);
end;

procedure TfrmPrincipal.AtualizarHealth(AOnline: Boolean);
begin
  if AOnline then
    sbPrincipal.Panels[PAINEL_API].Text := '● API online'
  else
    sbPrincipal.Panels[PAINEL_API].Text := '● API fora do ar';
end;

procedure TfrmPrincipal.TratarExcecao(Sender: TObject; E: Exception);
begin
  // regra violada ou recurso inexistente: aviso; API fora do ar: aviso + log; resto: erro + log
  if (E is EValidacao) or (E is EApiValidacao) or (E is EApiNaoEncontrado) or (E is EApiNaoAutorizado) then
    MessageDlg(E.Message, mtWarning, [mbOK], 0)
  else if E is EApiIndisponivel then
  begin
    FController.RegistrarErro(E.ClassName + ': ' + E.Message);
    MessageDlg(E.Message, mtWarning, [mbOK], 0);
  end
  else
  begin
    FController.RegistrarErro(E.ClassName + ': ' + E.Message);
    MessageDlg('Ocorreu um erro inesperado:' + sLineBreak + sLineBreak + E.Message, mtError, [mbOK], 0);
  end;
end;

end.
