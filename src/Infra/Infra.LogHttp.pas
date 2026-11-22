unit Infra.LogHttp;

{
  Log das chamadas à API: método, URL, status, tempo e os JSONs de envio e de
  resposta, num arquivo por dia (logs\http\AAAA-MM-DD.log).

  Segurança: tudo que entra aqui passa por MascararSegredos, que troca o valor
  das chaves "senha", "token" e "password" por "***" em qualquer nível do JSON.
  O cabeçalho Authorization nunca é recebido por esta unit, então não tem como
  vazar para o arquivo.
}

interface

type
  ILogHttp = interface
    ['{B7E3D1F0-5A2C-4C8E-9F16-0D4A8E2B6C35}']
    procedure Registrar(const AMetodo, AUrl: string; AStatus, AMilissegundos: Integer;
      const AEnvio, AResposta: string);
  end;

  TLogHttpArquivo = class(TInterfacedObject, ILogHttp)
  private
    FPasta: string;
    FAtivo: Boolean;
    FTrava: TObject;
  public
    /// APasta é a pasta de logs da aplicação; o arquivo vai para a subpasta "http".
    constructor Create(const APasta: string; AAtivo: Boolean);
    destructor Destroy; override;
    procedure Registrar(const AMetodo, AUrl: string; AStatus, AMilissegundos: Integer;
      const AEnvio, AResposta: string);
  end;

/// Devolve o JSON com senha/token trocados por "***". Texto que não é JSON volta intacto.
function MascararSegredos(const AJson: string): string;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

const
  MASCARA = '***';

function ChaveSecreta(const ANome: string): Boolean;
begin
  Result := SameText(ANome, 'senha') or SameText(ANome, 'token') or SameText(ANome, 'password');
end;

procedure Mascarar(AValor: TJSONValue);
var
  LPar: TJSONPair;
  LItem: TJSONValue;
begin
  if AValor is TJSONObject then
  begin
    for LPar in TJSONObject(AValor) do
      if ChaveSecreta(LPar.JsonString.Value) then
        LPar.JsonValue := TJSONString.Create(MASCARA) // o par libera o valor antigo
      else
        Mascarar(LPar.JsonValue);
  end
  else if AValor is TJSONArray then
    for LItem in TJSONArray(AValor) do
      Mascarar(LItem);
end;

function MascararSegredos(const AJson: string): string;
var
  LValor: TJSONValue;
begin
  if AJson.Trim.IsEmpty then
    Exit(AJson);
  LValor := TJSONObject.ParseJSONValue(AJson);
  if LValor = nil then
    Exit(AJson);
  try
    Mascarar(LValor);
    Result := LValor.ToJSON;
  finally
    LValor.Free;
  end;
end;

{ TLogHttpArquivo }

constructor TLogHttpArquivo.Create(const APasta: string; AAtivo: Boolean);
begin
  inherited Create;
  FPasta := TPath.Combine(APasta, 'http');
  FAtivo := AAtivo;
  FTrava := TObject.Create;
end;

destructor TLogHttpArquivo.Destroy;
begin
  FTrava.Free;
  inherited;
end;

procedure TLogHttpArquivo.Registrar(const AMetodo, AUrl: string; AStatus, AMilissegundos: Integer;
  const AEnvio, AResposta: string);
var
  LTexto: string;
begin
  if not FAtivo then
    Exit;

  LTexto := Format('%s %s %s -> %d (%d ms)', [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
    AMetodo, AUrl, AStatus, AMilissegundos]) + sLineBreak;
  if AEnvio <> '' then
    LTexto := LTexto + '  envio:    ' + MascararSegredos(AEnvio) + sLineBreak;
  if AResposta <> '' then
    LTexto := LTexto + '  resposta: ' + MascararSegredos(AResposta) + sLineBreak;

  TMonitor.Enter(FTrava);
  try
    try
      ForceDirectories(FPasta);
      TFile.AppendAllText(TPath.Combine(FPasta, FormatDateTime('yyyy-mm-dd', Date) + '.log'),
        LTexto, TEncoding.UTF8);
    except
      // log é auxiliar; nunca derruba a chamada
    end;
  finally
    TMonitor.Exit(FTrava);
  end;
end;

end.
