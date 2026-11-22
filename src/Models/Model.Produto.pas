unit Model.Produto;

interface

type
  TProduto = class
  public
    Id: Integer;
    Descricao: string;
    Preco: Currency;
    Estoque: Integer;
    CodigoBarras: string; // vazio = sem código
  end;

implementation

end.
