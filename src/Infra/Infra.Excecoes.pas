unit Infra.Excecoes;

interface

uses
  System.SysUtils;

type
  // erro devolvido pela API (ou falta de resposta dela); Status = 0 quando nem chegou resposta
  EApi = class(Exception)
  private
    FStatus: Integer;
  public
    constructor Create(const AMensagem: string; AStatus: Integer = 0);
    property Status: Integer read FStatus;
  end;

  EApiValidacao = class(EApi);      // 400 / 409 / 422
  EApiNaoEncontrado = class(EApi);  // 404
  EApiNaoAutorizado = class(EApi);  // 401
  EApiIndisponivel = class(EApi);   // sem conexão, timeout, 5xx

  // validação feita no próprio cliente, antes de chamar a API
  EValidacao = class(Exception);

implementation

constructor EApi.Create(const AMensagem: string; AStatus: Integer);
begin
  inherited Create(AMensagem);
  FStatus := AStatus;
end;

end.
