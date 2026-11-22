unit View.Clientes;

// Lista de clientes. Sem .dfm próprio: usa o de TfraListaBase e cria as colunas aqui.

interface

uses
  System.Classes, View.ListaBase;

type
  TfraClientes = class(TfraListaBase)
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
  System.SysUtils, Model.Cliente, Model.Pagina, Controller.Cliente, View.ClienteEdicao;

procedure TfraClientes.CriarColunas;
begin
  edtBusca.TextHint := 'Buscar por nome ou CPF/CNPJ';
  AdicionarColuna('colNome', 'Nome', 260);
  AdicionarColuna('colDocumento', 'CPF/CNPJ', 150);
  AdicionarColuna('colEmail', 'E-mail', 220);
  AdicionarColuna('colTelefone', 'Telefone', 120);
end;

function TfraClientes.BuscarPagina(APagina, ALimite: Integer; const ABusca: string): TObject;
begin
  Result := TClienteController.Listar(APagina, ALimite, ABusca);
end;

procedure TfraClientes.ExibirPagina(ADados: TObject; out ATotal, ATotalPaginas: Integer);
var
  LPagina: TPagina<TCliente>;
  I: Integer;
  C: TCliente;
begin
  LPagina := ADados as TPagina<TCliente>;
  tvLista.DataController.RecordCount := LPagina.Dados.Count;
  for I := 0 to LPagina.Dados.Count - 1 do
  begin
    C := LPagina.Dados[I];
    DefinirLinha(I, C.Id, [C.Nome, C.DocumentoFormatado, C.Email, C.Telefone]);
  end;
  ATotal := LPagina.Total;
  ATotalPaginas := LPagina.TotalPaginas;
end;

procedure TfraClientes.Novo;
begin
  if TfrmClienteEdicao.Executar(0) then
    Recarregar;
end;

procedure TfraClientes.Editar(AId: Integer);
begin
  if TfrmClienteEdicao.Executar(AId) then
    Recarregar;
end;

procedure TfraClientes.Inativar(AId: Integer);
begin
  TClienteController.Inativar(AId);
end;

function TfraClientes.MensagemInativar(const ADescricao: string): string;
begin
  Result := Format('Inativar %s? O cliente deixa de aparecer nas listas e em novos pedidos.', [ADescricao]);
end;

end.
