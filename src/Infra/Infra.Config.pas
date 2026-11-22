unit Infra.Config;

{
  Leitura do config.ini (ao lado do executável, não versionado). Sem o arquivo,
  o cliente funciona com um perfil "Local" apontando para http://localhost:9000.
}

interface

type
  TPerfilApi = record
    Nome: string;
    Url: string;
  end;

  TConfig = class
  private
    FPerfis: TArray<TPerfilApi>;
    FTimeoutMs: Integer;
    FIntervaloHealthMs: Integer;
    FPastaLog: string;
    FLogHttp: Boolean;
    FRetencaoLogDias: Integer;
  public
    constructor Create(const AArquivo: string);
    function PerfilPorNome(const ANome: string): TPerfilApi;
    property Perfis: TArray<TPerfilApi> read FPerfis;
    property TimeoutMs: Integer read FTimeoutMs;
    property IntervaloHealthMs: Integer read FIntervaloHealthMs;
    property PastaLog: string read FPastaLog;
    property LogHttp: Boolean read FLogHttp;
    property RetencaoLogDias: Integer read FRetencaoLogDias;
  end;

/// Configuração do executável (config.ini ao lado dele), carregada na primeira chamada.
function Config: TConfig;

implementation

uses
  System.SysUtils, System.IniFiles, System.IOUtils;

const
  URL_PADRAO = 'http://localhost:9000';

var
  GConfig: TConfig;

function Config: TConfig;
begin
  if GConfig = nil then
    GConfig := TConfig.Create(TPath.Combine(ExtractFilePath(ParamStr(0)), 'config.ini'));
  Result := GConfig;
end;

function CaminhoAbsoluto(const ACaminho: string): string;
begin
  if ACaminho.IsEmpty or TPath.IsPathRooted(ACaminho) then
    Result := ACaminho
  else
    Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), ACaminho));
end;

{ TConfig }

constructor TConfig.Create(const AArquivo: string);
var
  LIni: TMemIniFile;
  LNomes: TArray<string>;
  LNome: string;
  LPerfil: TPerfilApi;
begin
  inherited Create;
  LIni := TMemIniFile.Create(AArquivo, TEncoding.UTF8);
  try
    LNomes := LIni.ReadString('Api', 'Perfis', '').Split([','], TStringSplitOptions.ExcludeEmpty);
    for LNome in LNomes do
    begin
      LPerfil.Nome := Trim(LNome);
      LPerfil.Url := LIni.ReadString('Perfil.' + LPerfil.Nome, 'Url', '').Trim.TrimRight(['/']);
      if LPerfil.Url <> '' then
        FPerfis := FPerfis + [LPerfil];
    end;
    if Length(FPerfis) = 0 then
    begin
      LPerfil.Nome := 'Local';
      LPerfil.Url := URL_PADRAO;
      FPerfis := [LPerfil];
    end;

    FTimeoutMs := LIni.ReadInteger('Api', 'TimeoutSegundos', 15) * 1000;
    FIntervaloHealthMs := LIni.ReadInteger('Health', 'IntervaloSegundos', 30) * 1000;
    FPastaLog := CaminhoAbsoluto(LIni.ReadString('Log', 'Pasta', '.\logs'));
    FLogHttp := LIni.ReadBool('Log', 'Http', True);
    FRetencaoLogDias := LIni.ReadInteger('Log', 'RetencaoDias', 30);
  finally
    LIni.Free;
  end;
end;

function TConfig.PerfilPorNome(const ANome: string): TPerfilApi;
var
  LPerfil: TPerfilApi;
begin
  for LPerfil in FPerfis do
    if SameText(LPerfil.Nome, ANome) then
      Exit(LPerfil);
  Result := FPerfis[0];
end;

initialization

finalization
  FreeAndNil(GConfig);

end.
