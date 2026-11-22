unit Controller.Produto;

// Todas as funções fazem chamada de rede: a tela as roda com ExecutarAsync.
// Sem estado (métodos de classe): a tela pode ser fechada no meio da chamada sem problema.

interface

uses
  Model.Produto, Model.Pagina;

type
  TProdutoController = class
  public
    class function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>; static;
    class function Obter(AId: Integer): TProduto; static;
    /// Id = 0 cadastra; senão atualiza (inclusive o estoque).
    class function Salvar(AProduto: TProduto): TProduto; static;
    class procedure Inativar(AId: Integer); static;
  end;

implementation

uses
  Controller.Fabrica;

class function TProdutoController.Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TProduto>;
begin
  Result := TFabrica.Produtos.Listar(APagina, ALimite, ABusca);
end;

class function TProdutoController.Obter(AId: Integer): TProduto;
begin
  Result := TFabrica.Produtos.Obter(AId);
end;

class function TProdutoController.Salvar(AProduto: TProduto): TProduto;
begin
  if AProduto.Id = 0 then
    Result := TFabrica.Produtos.Criar(AProduto)
  else
    Result := TFabrica.Produtos.Atualizar(AProduto);
end;

class procedure TProdutoController.Inativar(AId: Integer);
begin
  TFabrica.Produtos.Inativar(AId);
end;

end.
