unit Controller.Cliente;

// Todas as funções fazem chamada de rede: a tela as roda com ExecutarAsync.
// Sem estado (métodos de classe): a tela pode ser fechada no meio da chamada sem problema.

interface

uses
  Model.Cliente, Model.Pagina;

type
  TClienteController = class
  public
    class function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>; static;
    class function Obter(AId: Integer): TCliente; static;
    /// Id = 0 cadastra; senão atualiza. Devolve o cliente como a API gravou.
    class function Salvar(ACliente: TCliente): TCliente; static;
    class procedure Inativar(AId: Integer); static;
  end;

implementation

uses
  Controller.Fabrica;

class function TClienteController.Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
begin
  Result := TFabrica.Clientes.Listar(APagina, ALimite, ABusca);
end;

class function TClienteController.Obter(AId: Integer): TCliente;
begin
  Result := TFabrica.Clientes.Obter(AId);
end;

class function TClienteController.Salvar(ACliente: TCliente): TCliente;
begin
  if ACliente.Id = 0 then
    Result := TFabrica.Clientes.Criar(ACliente)
  else
    Result := TFabrica.Clientes.Atualizar(ACliente);
end;

class procedure TClienteController.Inativar(AId: Integer);
begin
  TFabrica.Clientes.Inativar(AId);
end;

end.
