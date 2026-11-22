unit Infra.Dpapi;

{
  Cifra textos com a DPAPI do Windows (CryptProtectData), no escopo do usuário
  atual: só o mesmo usuário do Windows, na mesma máquina, consegue decifrar.
  Usado para a senha lembrada no login; o resultado vai para o .ini em Base64.

  Não há chave no código nem no arquivo: quem guarda a chave é o Windows,
  amarrada às credenciais do usuário.
}

interface

/// Cifra e devolve em Base64. Texto vazio devolve ''.
function Proteger(const ATexto: string): string;
/// Decifra o Base64 gerado por Proteger. Qualquer falha devolve ''.
function Desproteger(const ABase64: string): string;

implementation

uses
  Winapi.Windows, System.SysUtils, System.NetEncoding;

const
  CRYPTPROTECT_UI_FORBIDDEN = $1;

type
  DATA_BLOB = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDATA_BLOB = ^DATA_BLOB;

function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: PWideChar; pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';

function CryptUnprotectData(pDataIn: PDATA_BLOB; ppszDataDescr: PPWideChar; pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';

function Proteger(const ATexto: string): string;
var
  LBytes, LCifrado: TBytes;
  LEntrada, LSaida: DATA_BLOB;
begin
  if ATexto = '' then
    Exit('');
  LBytes := TEncoding.UTF8.GetBytes(ATexto);
  LEntrada.cbData := Length(LBytes);
  LEntrada.pbData := @LBytes[0];
  if not CryptProtectData(@LEntrada, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @LSaida) then
    RaiseLastOSError;
  try
    SetLength(LCifrado, LSaida.cbData);
    Move(LSaida.pbData^, LCifrado[0], LSaida.cbData);
  finally
    LocalFree(HLOCAL(LSaida.pbData));
  end;
  // sem quebras de linha, para caber numa linha do .ini
  Result := TBase64Encoding.Create(0).EncodeBytesToString(LCifrado);
end;

function Desproteger(const ABase64: string): string;
var
  LCifrado, LBytes: TBytes;
  LEntrada, LSaida: DATA_BLOB;
  LCodificador: TBase64Encoding;
begin
  Result := '';
  if ABase64 = '' then
    Exit;
  LCodificador := TBase64Encoding.Create(0);
  try
    try
      LCifrado := LCodificador.DecodeStringToBytes(ABase64);
    except
      Exit;
    end;
  finally
    LCodificador.Free;
  end;
  if Length(LCifrado) = 0 then
    Exit;

  LEntrada.cbData := Length(LCifrado);
  LEntrada.pbData := @LCifrado[0];
  if not CryptUnprotectData(@LEntrada, nil, nil, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @LSaida) then
    Exit; // outro usuário, outra máquina ou valor adulterado
  try
    SetLength(LBytes, LSaida.cbData);
    if LSaida.cbData > 0 then
      Move(LSaida.pbData^, LBytes[0], LSaida.cbData);
  finally
    LocalFree(HLOCAL(LSaida.pbData));
  end;
  Result := TEncoding.UTF8.GetString(LBytes);
end;

end.
