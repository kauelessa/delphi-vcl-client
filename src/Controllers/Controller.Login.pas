unit Controller.Login;

interface

uses
  Infra.Config, Service.Sessao;

type
  TLoginController = class
  public
    function Perfis: TArray<TPerfilApi>;
    function Lembradas: TCredenciaisLembradas;
    /// Índice do perfil lembrado (ou 0).
    function IndicePerfilLembrado: Integer;
    /// Chamada de rede: rodar fora da thread principal.
    procedure Entrar(AIndicePerfil: Integer; const AUsuario, ASenha: string;
      ALembrarUsuario, ALembrarSenha: Boolean);
  end;

implementation

uses
  System.SysUtils, Infra.Excecoes, Controller.Fabrica;

function TLoginController.Perfis: TArray<TPerfilApi>;
begin
  Result := Config.Perfis;
end;

function TLoginController.Lembradas: TCredenciaisLembradas;
begin
  Result := TFabrica.Sessao.Lembradas;
end;

function TLoginController.IndicePerfilLembrado: Integer;
var
  I: Integer;
  LNome: string;
begin
  LNome := Lembradas.Perfil;
  for I := 0 to High(Config.Perfis) do
    if SameText(Config.Perfis[I].Nome, LNome) then
      Exit(I);
  Result := 0;
end;

procedure TLoginController.Entrar(AIndicePerfil: Integer; const AUsuario, ASenha: string;
  ALembrarUsuario, ALembrarSenha: Boolean);
begin
  if AUsuario.Trim = '' then
    raise EValidacao.Create('Informe o usuário.');
  if ASenha = '' then
    raise EValidacao.Create('Informe a senha.');
  TFabrica.Sessao.Entrar(Config.Perfis[AIndicePerfil], AUsuario.Trim, ASenha, ALembrarUsuario, ALembrarSenha);
end;

end.
