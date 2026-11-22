unit Service.Produto;

interface

uses
  Model.Produto, Model.Pagina, Api.Produto;

type
  // preço > 0 e estoque não negativo são regras da API; aqui só o obrigatório
  IProdutoService = interface
    ['{F38C6A1D-9E5B-4072-A4D8-1B7E3C9F5A60}']
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
    function Obter(AId: Integer): TProduto;
    function Criar(AProduto: TProduto): TProduto;
    function Atualizar(AProduto: TProduto): TProduto;
    procedure Inativar(AId: Integer);
  end;

  TProdutoService = class(TInterfacedObject, IProdutoService)
  private
    FApi: IProdutoApi;
    procedure Validar(AProduto: TProduto);
  public
    constructor Create(AApi: IProdutoApi);
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
    function Obter(AId: Integer): TProduto;
    function Criar(AProduto: TProduto): TProduto;
    function Atualizar(AProduto: TProduto): TProduto;
    procedure Inativar(AId: Integer);
  end;

implementation

uses
  System.SysUtils, Infra.Excecoes;

constructor TProdutoService.Create(AApi: IProdutoApi);
begin
  inherited Create;
  FApi := AApi;
end;

procedure TProdutoService.Validar(AProduto: TProduto);
begin
  if AProduto.Descricao.Trim = '' then
    raise EValidacao.Create('Informe a descrição.');
end;

function TProdutoService.Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
begin
  Result := FApi.Listar(APagina, ALimite, ABusca);
end;

function TProdutoService.Obter(AId: Integer): TProduto;
begin
  Result := FApi.Obter(AId);
end;

function TProdutoService.Criar(AProduto: TProduto): TProduto;
begin
  Validar(AProduto);
  Result := FApi.Criar(AProduto);
end;

function TProdutoService.Atualizar(AProduto: TProduto): TProduto;
begin
  Validar(AProduto);
  Result := FApi.Atualizar(AProduto);
end;

procedure TProdutoService.Inativar(AId: Integer);
begin
  FApi.Inativar(AId);
end;

end.
