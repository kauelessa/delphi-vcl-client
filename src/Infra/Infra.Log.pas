unit Infra.Log;

{
  Log da aplicação em arquivo texto, um por dia (logs\AAAA-MM-DD.log).
  A escrita é protegida por TMonitor porque as chamadas à API rodam fora da
  thread principal e também registram erros.
}

interface

type
  TNivelLog = (Info, Aviso, Erro);

  ILog = interface
    ['{4E0B7C2A-9D51-4F3B-8A6E-2C1D7F9B3A10}']
    procedure Registrar(ANivel: TNivelLog; const AMensagem: string);
    procedure Info(const AMensagem: string);
    procedure Erro(const AMensagem: string);
  end;

  TLogArquivo = class(TInterfacedObject, ILog)
  private
    FPasta: string;
    FTrava: TObject;
  public
    constructor Create(const APasta: string);
    destructor Destroy; override;
    procedure Registrar(ANivel: TNivelLog; const AMensagem: string);
    procedure Info(const AMensagem: string);
    procedure Erro(const AMensagem: string);
  end;

function Log: ILog;

/// Apaga os .log (da pasta e das subpastas) modificados há mais de ADias.
procedure LimparLogsAntigos(const APasta: string; ADias: Integer);

implementation

uses
  System.SysUtils, System.IOUtils, System.DateUtils, Infra.Config;

const
  NOMES_NIVEL: array[TNivelLog] of string = ('INFO', 'AVISO', 'ERRO');

var
  GLog: ILog;

function Log: ILog;
begin
  if GLog = nil then
    GLog := TLogArquivo.Create(Config.PastaLog);
  Result := GLog;
end;

procedure LimparLogsAntigos(const APasta: string; ADias: Integer);
var
  LArquivo: string;
  LLimite: TDateTime;
begin
  if (ADias <= 0) or not TDirectory.Exists(APasta) then
    Exit;
  LLimite := IncDay(Now, -ADias);
  for LArquivo in TDirectory.GetFiles(APasta, '*.log', TSearchOption.soAllDirectories) do
    if TFile.GetLastWriteTime(LArquivo) < LLimite then
    try
      TFile.Delete(LArquivo);
    except
      // arquivo aberto em outro programa: tenta de novo na próxima abertura
    end;
end;

{ TLogArquivo }

constructor TLogArquivo.Create(const APasta: string);
begin
  inherited Create;
  FPasta := APasta;
  FTrava := TObject.Create;
end;

destructor TLogArquivo.Destroy;
begin
  FTrava.Free;
  inherited;
end;

procedure TLogArquivo.Registrar(ANivel: TNivelLog; const AMensagem: string);
var
  LLinha: string;
begin
  LLinha := Format('%s [%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
    NOMES_NIVEL[ANivel], AMensagem]) + sLineBreak;

  TMonitor.Enter(FTrava);
  try
    try
      ForceDirectories(FPasta);
      TFile.AppendAllText(TPath.Combine(FPasta, FormatDateTime('yyyy-mm-dd', Date) + '.log'),
        LLinha, TEncoding.UTF8);
    except
      // falha ao gravar log não pode derrubar a tela
    end;
  finally
    TMonitor.Exit(FTrava);
  end;
end;

procedure TLogArquivo.Info(const AMensagem: string);
begin
  Registrar(TNivelLog.Info, AMensagem);
end;

procedure TLogArquivo.Erro(const AMensagem: string);
begin
  Registrar(TNivelLog.Erro, AMensagem);
end;

initialization

finalization
  GLog := nil;

end.
