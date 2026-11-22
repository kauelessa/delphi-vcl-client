unit Controller.Principal;

interface

uses
  Vcl.Forms, Service.Sessao;

type
  TPrincipalController = class
  public
    function DescricaoSessao: string;
    function Usuario: string;
    /// Chamada de rede: rodar fora da thread principal. Nunca levanta exceção.
    function ApiOnline: Boolean;
    function IntervaloHealthMs: Integer;
    procedure RegistrarRelogin(APedirSenha: TPedirSenha);
    procedure RegistrarErro(const AMensagem: string);
    procedure SalvarJanela(AForm: TForm);
    procedure RestaurarJanela(AForm: TForm);
  end;

implementation

uses
  System.SysUtils, System.Types, Vcl.Controls, Infra.Config, Infra.Log, Infra.Preferencias,
  Controller.Fabrica;

const
  SECAO_JANELA = 'Janela';

function TPrincipalController.DescricaoSessao: string;
begin
  Result := Format('%s  ·  %s (%s)', [TFabrica.Sessao.Usuario, TFabrica.Sessao.Perfil.Nome,
    TFabrica.Sessao.Perfil.Url]);
end;

function TPrincipalController.Usuario: string;
begin
  Result := TFabrica.Sessao.Usuario;
end;

function TPrincipalController.ApiOnline: Boolean;
begin
  Result := TFabrica.Health.Online(TFabrica.Sessao.UrlBase);
end;

function TPrincipalController.IntervaloHealthMs: Integer;
begin
  Result := Config.IntervaloHealthMs;
end;

procedure TPrincipalController.RegistrarRelogin(APedirSenha: TPedirSenha);
begin
  TFabrica.Sessao.DefinirPedirSenha(APedirSenha);
end;

procedure TPrincipalController.RegistrarErro(const AMensagem: string);
begin
  Log.Erro(AMensagem);
end;

procedure TPrincipalController.SalvarJanela(AForm: TForm);
begin
  Preferencias.Gravar(SECAO_JANELA, 'Maximizada', BoolToStr(AForm.WindowState = wsMaximized, True));
  if AForm.WindowState = wsNormal then
    Preferencias.Gravar(SECAO_JANELA, 'Posicao',
      Format('%d,%d,%d,%d', [AForm.Left, AForm.Top, AForm.Width, AForm.Height]));
end;

procedure TPrincipalController.RestaurarJanela(AForm: TForm);
var
  LPartes: TArray<string>;
  LRect: TRect;
begin
  LPartes := Preferencias.Ler(SECAO_JANELA, 'Posicao', '').Split([',']);
  if Length(LPartes) = 4 then
  begin
    LRect := Rect(StrToIntDef(LPartes[0], 0), StrToIntDef(LPartes[1], 0), 0, 0);
    LRect.Width := StrToIntDef(LPartes[2], AForm.Width);
    LRect.Height := StrToIntDef(LPartes[3], AForm.Height);
    // só restaura se a janela continuar visível num monitor (ex.: segundo monitor desligado)
    if Screen.MonitorFromRect(LRect, mdNull) <> nil then
    begin
      AForm.Position := poDesigned;
      AForm.BoundsRect := LRect;
    end;
  end;
  if StrToBoolDef(Preferencias.Ler(SECAO_JANELA, 'Maximizada', 'False'), False) then
    AForm.WindowState := wsMaximized;
end;

end.
