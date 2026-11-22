unit Api.Health;

interface

uses
  Infra.Http;

type
  IHealthApi = interface
    ['{E4C2A8F1-0B7D-4D36-8E5C-9A1F3B6D2C47}']
    /// Nunca levanta exceção: qualquer problema conta como offline.
    function Online(const AUrlBase: string): Boolean;
  end;

  THealthApi = class(TInterfacedObject, IHealthApi)
  private
    FHttp: IHttpClient;
  public
    constructor Create(AHttp: IHttpClient);
    function Online(const AUrlBase: string): Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor THealthApi.Create(AHttp: IHttpClient);
begin
  inherited Create;
  FHttp := AHttp;
end;

function THealthApi.Online(const AUrlBase: string): Boolean;
begin
  try
    Result := FHttp.Executar(THttpMetodo.Get, AUrlBase + '/health', '', '').Status = 200;
  except
    Result := False;
  end;
end;

end.
