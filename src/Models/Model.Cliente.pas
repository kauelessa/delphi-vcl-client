unit Model.Cliente;

interface

type
  TCliente = class
  public
    Id: Integer;
    Nome: string;
    Documento: string; // como a API grava: só letras e números
    Email: string;
    Telefone: string;
    /// CPF ###.###.###-## ou CNPJ ##.###.###/####-## (aceita o CNPJ alfanumérico).
    function DocumentoFormatado: string;
  end;

implementation

uses
  System.SysUtils;

function TCliente.DocumentoFormatado: string;
var
  D: string;
begin
  D := Documento;
  case Length(D) of
    11: Result := Format('%s.%s.%s-%s', [Copy(D, 1, 3), Copy(D, 4, 3), Copy(D, 7, 3), Copy(D, 10, 2)]);
    14: Result := Format('%s.%s.%s/%s-%s', [Copy(D, 1, 2), Copy(D, 3, 3), Copy(D, 6, 3), Copy(D, 9, 4), Copy(D, 13, 2)]);
  else
    Result := D;
  end;
end;

end.
