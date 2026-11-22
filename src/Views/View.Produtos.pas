unit View.Produtos;

// Lista de produtos. Sem .dfm próprio: usa o de TfraListaBase e cria as colunas aqui.

interface

uses
  System.Classes, View.ListaBase;

type
  TfraProdutos = class(TfraListaBase)
  protected
    procedure CriarColunas; override;
    function BuscarPagina(APagina, ALimite: Integer; const ABusca: string): TObject; override;
    procedure ExibirPagina(ADados: TObject; out ATotal, ATotalPaginas: Integer); override;
    procedure Novo; override;
    procedure Editar(AId: Integer); override;
    procedure Inativar(AId: Integer); override;
    function MensagemInativar(const ADescricao: string): string; override;
  end;

implementation

uses
  System.SysUtils, cxTextEdit, cxCurrencyEdit, cxGridTableView, Model.Produto, Model.Pagina, Controller.Produto,
  View.ProdutoEdicao;

procedure TfraProdutos.CriarColunas;
var
  LPreco, LEstoque: TcxGridColumn;
begin
  edtBusca.TextHint := 'Buscar pela descrição';
  AdicionarColuna('colDescricao', 'Descrição', 360);
  LPreco := AdicionarColuna('colPreco', 'Preço', 120, 'Currency');
  LPreco.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(LPreco.Properties).DisplayFormat := 'R$ ,0.00';
  TcxCurrencyEditProperties(LPreco.Properties).Alignment.Horz := taRightJustify;
  LPreco.HeaderAlignmentHorz := taRightJustify;
  LEstoque := AdicionarColuna('colEstoque', 'Estoque', 100, 'Integer');
  LEstoque.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(LEstoque.Properties).Alignment.Horz := taRightJustify;
  LEstoque.HeaderAlignmentHorz := taRightJustify;
end;

function TfraProdutos.BuscarPagina(APagina, ALimite: Integer; const ABusca: string): TObject;
begin
  Result := TProdutoController.Listar(APagina, ALimite, ABusca);
end;

procedure TfraProdutos.ExibirPagina(ADados: TObject; out ATotal, ATotalPaginas: Integer);
var
  LPagina: TPagina<TProduto>;
  I: Integer;
  P: TProduto;
begin
  LPagina := ADados as TPagina<TProduto>;
  tvLista.DataController.RecordCount := LPagina.Dados.Count;
  for I := 0 to LPagina.Dados.Count - 1 do
  begin
    P := LPagina.Dados[I];
    DefinirLinha(I, P.Id, [P.Descricao, P.Preco, P.Estoque]);
  end;
  ATotal := LPagina.Total;
  ATotalPaginas := LPagina.TotalPaginas;
end;

procedure TfraProdutos.Novo;
begin
  if TfrmProdutoEdicao.Executar(0) then
    Recarregar;
end;

procedure TfraProdutos.Editar(AId: Integer);
begin
  if TfrmProdutoEdicao.Executar(AId) then
    Recarregar;
end;

procedure TfraProdutos.Inativar(AId: Integer);
begin
  TProdutoController.Inativar(AId);
end;

function TfraProdutos.MensagemInativar(const ADescricao: string): string;
begin
  Result := Format('Inativar %s? O produto deixa de aparecer nas listas e em novos pedidos.', [ADescricao]);
end;

end.
