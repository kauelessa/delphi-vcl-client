unit Service.Sessao;

interface

uses
  Infra.Config, Infra.Preferencias, Api.Base, Api.Auth;

type
  TCredenciaisLembradas = record
    Usuario: string;
    Senha: string;
    Perfil: string;
    LembrarUsuario: Boolean;
    LembrarSenha: Boolean;
  end;

  // a tela de relogin; False = usuário cancelou
  TPedirSenha = reference to function(const AUsuario: string; out ASenha: string): Boolean;

  ISessaoService = interface(ISessaoApi)
    ['{0F6D3B92-8A4C-4E17-B5D0-2C9E7A1F4B68}']
    procedure Entrar(const APerfil: TPerfilApi; const AUsuario, ASenha: string;
      ALembrarUsuario, ALembrarSenha: Boolean);
    function Lembradas: TCredenciaisLembradas;
    function Usuario: string;
    function Perfil: TPerfilApi;
    procedure DefinirPedirSenha(AFunc: TPedirSenha);
    procedure Sair;
  end;

  TSessaoService = class(TInterfacedObject, ISessaoService, ISessaoApi)
  private
    FAuth: IAuthApi;
    FPreferencias: TPreferenciasUsuario;
    FPerfil: TPerfilApi;
    FUsuario: string;
    FToken: string;
    FPedirSenha: TPedirSenha;
    function PerguntarSenha(out ASenha: string): Boolean;
  public
    constructor Create(AAuth: IAuthApi; APreferencias: TPreferenciasUsuario);
    // ISessaoApi
    function UrlBase: string;
    function Token: string;
    function Relogar: Boolean;
    // ISessaoService
    procedure Entrar(const APerfil: TPerfilApi; const AUsuario, ASenha: string;
      ALembrarUsuario, ALembrarSenha: Boolean);
    function Lembradas: TCredenciaisLembradas;
    function Usuario: string;
    function Perfil: TPerfilApi;
    procedure DefinirPedirSenha(AFunc: TPedirSenha);
    procedure Sair;
  end;

implementation

uses
  System.SysUtils, System.Classes, Infra.Dpapi, Infra.Excecoes;

const
  SECAO = 'Login';

constructor TSessaoService.Create(AAuth: IAuthApi; APreferencias: TPreferenciasUsuario);
begin
  inherited Create;
  FAuth := AAuth;
  FPreferencias := APreferencias;
end;

function TSessaoService.UrlBase: string;
begin
  Result := FPerfil.Url;
end;

function TSessaoService.Token: string;
begin
  Result := FToken;
end;

function TSessaoService.Usuario: string;
begin
  Result := FUsuario;
end;

function TSessaoService.Perfil: TPerfilApi;
begin
  Result := FPerfil;
end;

procedure TSessaoService.DefinirPedirSenha(AFunc: TPedirSenha);
begin
  FPedirSenha := AFunc;
end;

procedure TSessaoService.Entrar(const APerfil: TPerfilApi; const AUsuario, ASenha: string;
  ALembrarUsuario, ALembrarSenha: Boolean);
begin
  FToken := FAuth.Login(APerfil.Url, AUsuario, ASenha).Token;
  FPerfil := APerfil;
  FUsuario := AUsuario;

  FPreferencias.Gravar(SECAO, 'Perfil', APerfil.Nome);
  if ALembrarUsuario then
    FPreferencias.Gravar(SECAO, 'Usuario', AUsuario)
  else
    FPreferencias.Apagar(SECAO, 'Usuario');
  // senha só faz sentido junto com o usuário
  if ALembrarUsuario and ALembrarSenha then
    FPreferencias.Gravar(SECAO, 'Senha', Proteger(ASenha))
  else
    FPreferencias.Apagar(SECAO, 'Senha');
end;

function TSessaoService.Lembradas: TCredenciaisLembradas;
begin
  Result.Usuario := FPreferencias.Ler(SECAO, 'Usuario', '');
  Result.Senha := Desproteger(FPreferencias.Ler(SECAO, 'Senha', ''));
  Result.Perfil := FPreferencias.Ler(SECAO, 'Perfil', '');
  Result.LembrarUsuario := Result.Usuario <> '';
  Result.LembrarSenha := Result.Senha <> '';
end;

function TSessaoService.PerguntarSenha(out ASenha: string): Boolean;
var
  LSenha: string;
  LOk: Boolean;
begin
  if not Assigned(FPedirSenha) then
    Exit(False);
  // as chamadas à API rodam fora da thread principal; o diálogo precisa dela
  if TThread.CurrentThread.ThreadID = MainThreadID then
    LOk := FPedirSenha(FUsuario, LSenha)
  else
    TThread.Synchronize(nil,
      procedure
      begin
        LOk := FPedirSenha(FUsuario, LSenha);
      end);
  ASenha := LSenha;
  Result := LOk;
end;

function TSessaoService.Relogar: Boolean;
var
  LSenha: string;
begin
  while PerguntarSenha(LSenha) do
  try
    FToken := FAuth.Login(FPerfil.Url, FUsuario, LSenha).Token;
    Exit(True);
  except
    on EApiNaoAutorizado do
      ; // senha errada: pergunta de novo
  end;
  Result := False;
end;

procedure TSessaoService.Sair;
begin
  FToken := '';
end;

end.
