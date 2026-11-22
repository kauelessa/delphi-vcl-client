unit Api.Cliente;

interface

uses
  Model.Cliente, Model.Pagina, Api.Base;

type
  // objetos devolvidos são do chamador (libere com Free)
  IClienteApi = interface
    ['{C3B81E5A-2F49-4D7C-A0E6-7B5D9F1C3A28}']
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
    function Obter(AId: Integer): TCliente;
    function Criar(ACliente: TCliente): TCliente;
    function Atualizar(ACliente: TCliente): TCliente;
    procedure Inativar(AId: Integer);
  end;

  TClienteApi = class(TApiBase, IClienteApi)
  public
    function Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
    function Obter(AId: Integer): TCliente;
    function Criar(ACliente: TCliente): TCliente;
    function Atualizar(ACliente: TCliente): TCliente;
    procedure Inativar(AId: Integer);
  end;

implementation

uses
  System.SysUtils, System.JSON, Infra.Http, Infra.Json;

function ClienteDeJson(AJson: TJSONObject): TCliente;
begin
  Result := TCliente.Create;
  Result.Id := LerInteiro(AJson, 'id');
  Result.Nome := LerTexto(AJson, 'nome');
  Result.Documento := LerTexto(AJson, 'documento');
  Result.Email := LerTexto(AJson, 'email');
  Result.Telefone := LerTexto(AJson, 'telefone');
end;

function ClienteDoTexto(const AJson: string): TCliente;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ClienteDeJson(LJson);
  finally
    LJson.Free;
  end;
end;

function CorpoCliente(ACliente: TCliente): string;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('nome', ACliente.Nome).AddPair('documento', ACliente.Documento);
    if ACliente.Email <> '' then
      LJson.AddPair('email', ACliente.Email);
    if ACliente.Telefone <> '' then
      LJson.AddPair('telefone', ACliente.Telefone);
    Result := LJson.ToJSON;
  finally
    LJson.Free;
  end;
end;

function TClienteApi.Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>;
begin
  Result := LerPagina<TCliente>(
    Enviar(THttpMetodo.Get, RotaPaginada('/clientes', APagina, ALimite, 'busca', ABusca)),
    ClienteDeJson);
end;

function TClienteApi.Obter(AId: Integer): TCliente;
begin
  Result := ClienteDoTexto(Enviar(THttpMetodo.Get, '/clientes/' + AId.ToString));
end;

function TClienteApi.Criar(ACliente: TCliente): TCliente;
begin
  Result := ClienteDoTexto(Enviar(THttpMetodo.Post, '/clientes', CorpoCliente(ACliente)));
end;

function TClienteApi.Atualizar(ACliente: TCliente): TCliente;
begin
  Result := ClienteDoTexto(Enviar(THttpMetodo.Put, '/clientes/' + ACliente.Id.ToString, CorpoCliente(ACliente)));
end;

procedure TClienteApi.Inativar(AId: Integer);
begin
  Enviar(THttpMetodo.Delete, '/clientes/' + AId.ToString);
end;

end.
