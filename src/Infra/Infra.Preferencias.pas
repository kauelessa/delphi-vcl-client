unit Infra.Preferencias;

// Preferências do usuário do Windows: %APPDATA%\DelphiVclClient\usuario.ini

interface

uses
  System.IniFiles;

type
  TPreferenciasUsuario = class
  private
    FIni: TMemIniFile;
  public
    constructor Create(const AArquivo: string);
    destructor Destroy; override;
    function Ler(const ASecao, AChave, APadrao: string): string;
    procedure Gravar(const ASecao, AChave, AValor: string);
    procedure Apagar(const ASecao, AChave: string);
  end;

/// Pasta dos arquivos do usuário (preferências, layout dos grids, rascunho), criada se faltar.
function PastaUsuario: string;
function Preferencias: TPreferenciasUsuario;

implementation

uses
  System.SysUtils, System.IOUtils;

var
  GPreferencias: TPreferenciasUsuario;

function PastaUsuario: string;
begin
  Result := TPath.Combine(TPath.GetHomePath, 'DelphiVclClient'); // GetHomePath = %APPDATA% no Windows
  ForceDirectories(Result);
end;

function Preferencias: TPreferenciasUsuario;
begin
  if GPreferencias = nil then
    GPreferencias := TPreferenciasUsuario.Create(TPath.Combine(PastaUsuario, 'usuario.ini'));
  Result := GPreferencias;
end;

{ TPreferenciasUsuario }

constructor TPreferenciasUsuario.Create(const AArquivo: string);
begin
  inherited Create;
  ForceDirectories(ExtractFilePath(AArquivo));
  FIni := TMemIniFile.Create(AArquivo, TEncoding.UTF8);
end;

destructor TPreferenciasUsuario.Destroy;
begin
  FIni.Free;
  inherited;
end;

function TPreferenciasUsuario.Ler(const ASecao, AChave, APadrao: string): string;
begin
  Result := FIni.ReadString(ASecao, AChave, APadrao);
end;

procedure TPreferenciasUsuario.Gravar(const ASecao, AChave, AValor: string);
begin
  FIni.WriteString(ASecao, AChave, AValor);
  FIni.UpdateFile;
end;

procedure TPreferenciasUsuario.Apagar(const ASecao, AChave: string);
begin
  FIni.DeleteKey(ASecao, AChave);
  FIni.UpdateFile;
end;

initialization

finalization
  FreeAndNil(GPreferencias);

end.
