unit Test.Fakes;

interface

uses
  System.Generics.Collections, Infra.Http, Api.Base;

type
  THttpChamada = record
    Metodo: THttpMetodo;
    Url: string;
    Corpo: string;
    Token: string;
  end;

  // responde o que foi enfileirado, na ordem, e guarda cada chamada recebida
  THttpFake = class(TInterfacedObject, IHttpClient)
  private
    FRespostas: TQueue<THttpResposta>;
    FChamadas: TList<THttpChamada>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enfileirar(AStatus: Integer; const ACorpo: string);
    function Executar(AMetodo: THttpMetodo; const AUrl, ACorpo, AToken: string): THttpResposta;
    property Chamadas: TList<THttpChamada> read FChamadas;
  end;

  TSessaoFake = class(TInterfacedObject, ISessaoApi)
  private
    FToken: string;
    FResultadoRelogar: Boolean;
    FTokenAposRelogar: string;
    FVezesRelogar: Integer;
  public
    constructor Create;
    function UrlBase: string;
    function Token: string;
    function Relogar: Boolean;
    property TokenAtual: string read FToken write FToken;
    property ResultadoRelogar: Boolean read FResultadoRelogar write FResultadoRelogar;
    property TokenAposRelogar: string read FTokenAposRelogar write FTokenAposRelogar;
    property VezesRelogar: Integer read FVezesRelogar;
  end;

implementation

uses
  System.SysUtils;

{ THttpFake }

constructor THttpFake.Create;
begin
  inherited;
  FRespostas := TQueue<THttpResposta>.Create;
  FChamadas := TList<THttpChamada>.Create;
end;

destructor THttpFake.Destroy;
begin
  FChamadas.Free;
  FRespostas.Free;
  inherited;
end;

procedure THttpFake.Enfileirar(AStatus: Integer; const ACorpo: string);
var
  LResposta: THttpResposta;
begin
  LResposta.Status := AStatus;
  LResposta.Corpo := ACorpo;
  FRespostas.Enqueue(LResposta);
end;

function THttpFake.Executar(AMetodo: THttpMetodo; const AUrl, ACorpo, AToken: string): THttpResposta;
var
  LChamada: THttpChamada;
begin
  LChamada.Metodo := AMetodo;
  LChamada.Url := AUrl;
  LChamada.Corpo := ACorpo;
  LChamada.Token := AToken;
  FChamadas.Add(LChamada);
  if FRespostas.Count = 0 then
    raise Exception.Create('THttpFake: nenhuma resposta enfileirada para ' + AUrl);
  Result := FRespostas.Dequeue;
end;

{ TSessaoFake }

constructor TSessaoFake.Create;
begin
  inherited;
  FToken := 'token-teste';
  FTokenAposRelogar := 'novo';
end;

function TSessaoFake.UrlBase: string;
begin
  Result := 'http://api.teste';
end;

function TSessaoFake.Token: string;
begin
  Result := FToken;
end;

function TSessaoFake.Relogar: Boolean;
begin
  Inc(FVezesRelogar);
  Result := FResultadoRelogar;
  if Result then
    FToken := FTokenAposRelogar;
end;

end.
