unit Service.Cliente;

interface

uses
  Model.Cliente, Model.Pagina, Api.Cliente;

type
  // CPF/CNPJ, e-mail e duplicidade são validados pela API; aqui só o obrigatório
  IClienteService = interface
    ['{A61F0D38-5C2B-4E97-8B4A-D3E7C1F9B205}']
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
    function Obter(AId: Integer): TCliente;
    function Criar(ACliente: TCliente): TCliente;
    function Atualizar(ACliente: TCliente): TCliente;
    procedure Inativar(AId: Integer);
  end;

  TClienteService = class(TInterfacedObject, IClienteService)
  private
    FApi: IClienteApi;
    procedure Validar(ACliente: TCliente);
  public
    constructor Create(AApi: IClienteApi);
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
    function Obter(AId: Integer): TCliente;
    function Criar(ACliente: TCliente): TCliente;
    function Atualizar(ACliente: TCliente): TCliente;
    procedure Inativar(AId: Integer);
  end;

implementation

uses
  System.SysUtils, Infra.Excecoes;

constructor TClienteService.Create(AApi: IClienteApi);
begin
  inherited Create;
  FApi := AApi;
end;

procedure TClienteService.Validar(ACliente: TCliente);
begin
  if ACliente.Nome.Trim = '' then
    raise EValidacao.Create('Informe o nome.');
  if ACliente.Documento.Trim = '' then
    raise EValidacao.Create('Informe o CPF ou CNPJ.');
end;

function TClienteService.Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
begin
  Result := FApi.Listar(APagina, ALimite, ABusca);
end;

function TClienteService.Obter(AId: Integer): TCliente;
begin
  Result := FApi.Obter(AId);
end;

function TClienteService.Criar(ACliente: TCliente): TCliente;
begin
  Validar(ACliente);
  Result := FApi.Criar(ACliente);
end;

function TClienteService.Atualizar(ACliente: TCliente): TCliente;
begin
  Validar(ACliente);
  Result := FApi.Atualizar(ACliente);
end;

procedure TClienteService.Inativar(AId: Integer);
begin
  FApi.Inativar(AId);
end;

end.
