unit Api.Produto;

interface

uses
  Model.Produto, Model.Pagina, Api.Base;

type
  // objetos devolvidos são do chamador (libere com Free)
  IProdutoApi = interface
    ['{7E2A5C91-4B3F-4A68-9D1E-0C6B8F2A5E14}']
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
    function Obter(AId: Integer): TProduto;
    function Criar(AProduto: TProduto): TProduto;
    /// Também é o ajuste de estoque: a API grava o Estoque enviado (valor absoluto).
    function Atualizar(AProduto: TProduto): TProduto;
    procedure Inativar(AId: Integer);
  end;

  TProdutoApi = class(TApiBase, IProdutoApi)
  public
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
    function Obter(AId: Integer): TProduto;
    function Criar(AProduto: TProduto): TProduto;
    function Atualizar(AProduto: TProduto): TProduto;
    procedure Inativar(AId: Integer);
  end;

implementation

uses
  System.SysUtils, System.JSON, Infra.Http, Infra.Json;

function ProdutoDeJson(AJson: TJSONObject): TProduto;
begin
  Result := TProduto.Create;
  Result.Id := LerInteiro(AJson, 'id');
  Result.Descricao := LerTexto(AJson, 'descricao');
  Result.Preco := LerCurrency(AJson, 'preco');
  Result.Estoque := LerInteiro(AJson, 'estoque');
end;

function ProdutoDoTexto(const AJson: string): TProduto;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ProdutoDeJson(LJson);
  finally
    LJson.Free;
  end;
end;

function CorpoProduto(AProduto: TProduto): string;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('descricao', AProduto.Descricao)
      .AddPair('preco', NumeroJson(AProduto.Preco))
      .AddPair('estoque', TJSONNumber.Create(AProduto.Estoque));
    Result := LJson.ToJSON;
  finally
    LJson.Free;
  end;
end;

function TProdutoApi.Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
begin
  Result := LerPagina<TProduto>(
    Enviar(THttpMetodo.Get, RotaPaginada('/produtos', APagina, ALimite, 'busca', ABusca)),
    ProdutoDeJson);
end;

function TProdutoApi.Obter(AId: Integer): TProduto;
begin
  Result := ProdutoDoTexto(Enviar(THttpMetodo.Get, '/produtos/' + AId.ToString));
end;

function TProdutoApi.Criar(AProduto: TProduto): TProduto;
begin
  Result := ProdutoDoTexto(Enviar(THttpMetodo.Post, '/produtos', CorpoProduto(AProduto)));
end;

function TProdutoApi.Atualizar(AProduto: TProduto): TProduto;
begin
  Result := ProdutoDoTexto(Enviar(THttpMetodo.Put, '/produtos/' + AProduto.Id.ToString, CorpoProduto(AProduto)));
end;

procedure TProdutoApi.Inativar(AId: Integer);
begin
  Enviar(THttpMetodo.Delete, '/produtos/' + AId.ToString);
end;

end.
