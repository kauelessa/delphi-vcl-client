unit Model.Pagina;

interface

uses
  System.Generics.Collections;

type
  // uma página das listagens da API: { dados, pagina, limite, total }
  TPagina<T: class> = class
  private
    FDados: TObjectList<T>;
  public
    Pagina: Integer;
    Limite: Integer;
    Total: Integer;
    constructor Create;
    destructor Destroy; override;
    /// Nunca menor que 1, para a tela sempre mostrar "página 1 de 1".
    function TotalPaginas: Integer;
    property Dados: TObjectList<T> read FDados;
  end;

implementation

constructor TPagina<T>.Create;
begin
  inherited Create;
  FDados := TObjectList<T>.Create(True);
end;

destructor TPagina<T>.Destroy;
begin
  FDados.Free;
  inherited;
end;

function TPagina<T>.TotalPaginas: Integer;
begin
  if (Limite <= 0) or (Total <= 0) then
    Exit(1);
  Result := (Total + Limite - 1) div Limite;
end;

end.
