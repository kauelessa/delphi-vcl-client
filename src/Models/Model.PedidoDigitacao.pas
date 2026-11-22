unit Model.PedidoDigitacao;

{
  Pedido sendo montado na tela, antes de ir para a API. É também o que vai
  para o rascunho em disco (ParaJson / DeJson), para não perder o trabalho se
  o programa fechar ou a API cair.

  O total aqui é só uma prévia: quem calcula o valor final, com o preço do
  momento da venda, é a API.
}

interface

uses
  System.Generics.Collections, Model.Produto;

type
  TItemDigitado = class
  public
    ProdutoId: Integer;
    Descricao: string;
    PrecoUnitario: Currency;
    Quantidade: Integer;
  end;

  TPedidoEmDigitacao = class
  private
    FItens: TObjectList<TItemDigitado>;
    class procedure ValidarQuantidade(AQuantidade: Integer); static;
  public
    ClienteId: Integer;
    ClienteNome: string;
    constructor Create;
    destructor Destroy; override;
    /// Produto que já está na lista soma a quantidade (a API não aceita produto repetido).
    procedure AdicionarProduto(AProduto: TProduto; AQuantidade: Integer);
    procedure AlterarQuantidade(AIndice, AQuantidade: Integer);
    procedure RemoverItem(AIndice: Integer);
    function Total: Currency;
    function ParaJson: string;
    /// nil se o texto não for um rascunho válido.
    class function DeJson(const AJson: string): TPedidoEmDigitacao; static;
    property Itens: TObjectList<TItemDigitado> read FItens;
  end;

implementation

uses
  System.SysUtils, System.JSON, Infra.Json, Infra.Excecoes;

constructor TPedidoEmDigitacao.Create;
begin
  inherited Create;
  FItens := TObjectList<TItemDigitado>.Create(True);
end;

destructor TPedidoEmDigitacao.Destroy;
begin
  FItens.Free;
  inherited;
end;

class procedure TPedidoEmDigitacao.ValidarQuantidade(AQuantidade: Integer);
begin
  if AQuantidade <= 0 then
    raise EValidacao.Create('A quantidade deve ser maior que zero.');
end;

procedure TPedidoEmDigitacao.AdicionarProduto(AProduto: TProduto; AQuantidade: Integer);
var
  LItem: TItemDigitado;
begin
  ValidarQuantidade(AQuantidade);
  for LItem in FItens do
    if LItem.ProdutoId = AProduto.Id then
    begin
      LItem.Quantidade := LItem.Quantidade + AQuantidade;
      Exit;
    end;

  LItem := TItemDigitado.Create;
  LItem.ProdutoId := AProduto.Id;
  LItem.Descricao := AProduto.Descricao;
  LItem.PrecoUnitario := AProduto.Preco;
  LItem.Quantidade := AQuantidade;
  FItens.Add(LItem);
end;

procedure TPedidoEmDigitacao.AlterarQuantidade(AIndice, AQuantidade: Integer);
begin
  ValidarQuantidade(AQuantidade);
  FItens[AIndice].Quantidade := AQuantidade;
end;

procedure TPedidoEmDigitacao.RemoverItem(AIndice: Integer);
begin
  FItens.Delete(AIndice);
end;

function TPedidoEmDigitacao.Total: Currency;
var
  LItem: TItemDigitado;
begin
  Result := 0;
  for LItem in FItens do
    Result := Result + LItem.PrecoUnitario * LItem.Quantidade;
end;

function TPedidoEmDigitacao.ParaJson: string;
var
  LJson, LJsonItem: TJSONObject;
  LItens: TJSONArray;
  LItem: TItemDigitado;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('clienteId', TJSONNumber.Create(ClienteId)).AddPair('clienteNome', ClienteNome);
    LItens := TJSONArray.Create;
    LJson.AddPair('itens', LItens);
    for LItem in FItens do
    begin
      LJsonItem := TJSONObject.Create;
      LJsonItem.AddPair('produtoId', TJSONNumber.Create(LItem.ProdutoId))
        .AddPair('descricao', LItem.Descricao)
        .AddPair('precoUnitario', NumeroJson(LItem.PrecoUnitario))
        .AddPair('quantidade', TJSONNumber.Create(LItem.Quantidade));
      LItens.AddElement(LJsonItem);
    end;
    Result := LJson.ToJSON;
  finally
    LJson.Free;
  end;
end;

class function TPedidoEmDigitacao.DeJson(const AJson: string): TPedidoEmDigitacao;
var
  LValor: TJSONValue;
  LJson: TJSONObject;
  LItens: TJSONArray;
  LJsonItem: TJSONValue;
  LItem: TItemDigitado;
begin
  Result := nil;
  LValor := TJSONObject.ParseJSONValue(AJson);
  try
    if not (LValor is TJSONObject) then
      Exit;
    LJson := TJSONObject(LValor);
    Result := TPedidoEmDigitacao.Create;
    Result.ClienteId := LerInteiro(LJson, 'clienteId');
    Result.ClienteNome := LerTexto(LJson, 'clienteNome');
    if LJson.TryGetValue<TJSONArray>('itens', LItens) then
      for LJsonItem in LItens do
        if LJsonItem is TJSONObject then
        begin
          LItem := TItemDigitado.Create;
          LItem.ProdutoId := LerInteiro(TJSONObject(LJsonItem), 'produtoId');
          LItem.Descricao := LerTexto(TJSONObject(LJsonItem), 'descricao');
          LItem.PrecoUnitario := LerCurrency(TJSONObject(LJsonItem), 'precoUnitario');
          LItem.Quantidade := LerInteiro(TJSONObject(LJsonItem), 'quantidade');
          Result.FItens.Add(LItem);
        end;
  finally
    LValor.Free;
  end;
end;

end.
