unit Infra.Json;

// Leitura e escrita de JSON sem depender da configuração regional do Windows.

interface

uses
  System.JSON;

function NumeroJson(AValor: Currency): TJSONNumber;
/// Ausente ou null devolve ''.
function LerTexto(AObj: TJSONObject; const ANome: string): string;
/// Ausente ou null devolve 0.
function LerInteiro(AObj: TJSONObject; const ANome: string): Integer;
function LerCurrency(AObj: TJSONObject; const ANome: string): Currency;
/// ISO 8601 (com ou sem fuso) convertido para a hora local.
function LerDataHora(AObj: TJSONObject; const ANome: string): TDateTime;

implementation

uses
  System.SysUtils, System.DateUtils;

function Valor(AObj: TJSONObject; const ANome: string): TJSONValue;
begin
  Result := AObj.GetValue(ANome);
  if (Result <> nil) and Result.Null then
    Result := nil;
end;

function NumeroJson(AValor: Currency): TJSONNumber;
begin
  // TJSONNumber formata com ponto decimal, independente do FormatSettings
  Result := TJSONNumber.Create(Double(AValor));
end;

function LerTexto(AObj: TJSONObject; const ANome: string): string;
var
  LValor: TJSONValue;
begin
  LValor := Valor(AObj, ANome);
  if LValor = nil then
    Result := ''
  else
    Result := LValor.Value;
end;

function LerInteiro(AObj: TJSONObject; const ANome: string): Integer;
var
  LValor: TJSONValue;
begin
  LValor := Valor(AObj, ANome);
  if LValor is TJSONNumber then
    Result := TJSONNumber(LValor).AsInt
  else
    Result := 0;
end;

function LerCurrency(AObj: TJSONObject; const ANome: string): Currency;
var
  LValor: TJSONValue;
begin
  LValor := Valor(AObj, ANome);
  if LValor is TJSONNumber then
    Result := TJSONNumber(LValor).AsDouble
  else
    Result := 0;
end;

function LerDataHora(AObj: TJSONObject; const ANome: string): TDateTime;
var
  LTexto: string;
begin
  LTexto := LerTexto(AObj, ANome);
  if LTexto = '' then
    Exit(0);
  Result := ISO8601ToDate(LTexto, False);
end;

end.
