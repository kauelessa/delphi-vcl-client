unit Test.Json;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  // roda com o Windows "em pt-BR" (vírgula decimal) para provar que o JSON não depende disso
  [TestFixture]
  TTestJson = class
  private
    FFormatoOriginal: TFormatSettings;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure NumeroJson_ComVirgulaRegional_SaiComPonto;
    [Test]
    procedure LerCurrency_LeNumeroComPonto;
    [Test]
    procedure LerTexto_NullOuAusente_Vazio;
    [Test]
    procedure LerInteiro_Ausente_Zero;
    [Test]
    procedure LerDataHora_Iso8601ComFuso;
  end;

implementation

uses
  System.JSON, System.DateUtils, Infra.Json;

procedure TTestJson.Setup;
begin
  FFormatoOriginal := FormatSettings;
  FormatSettings.DecimalSeparator := ',';
  FormatSettings.ThousandSeparator := '.';
end;

procedure TTestJson.TearDown;
begin
  FormatSettings := FFormatoOriginal;
end;

procedure TTestJson.NumeroJson_ComVirgulaRegional_SaiComPonto;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create.AddPair('preco', NumeroJson(279.90));
  try
    Assert.AreEqual('{"preco":279.9}', LObj.ToJSON);
  finally
    LObj.Free;
  end;
end;

procedure TTestJson.LerCurrency_LeNumeroComPonto;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.ParseJSONValue('{"v":349.9}') as TJSONObject;
  try
    Assert.AreEqual(Currency(349.9), LerCurrency(LObj, 'v'));
  finally
    LObj.Free;
  end;
end;

procedure TTestJson.LerTexto_NullOuAusente_Vazio;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.ParseJSONValue('{"email":null}') as TJSONObject;
  try
    Assert.AreEqual('', LerTexto(LObj, 'email'));
    Assert.AreEqual('', LerTexto(LObj, 'telefone'));
  finally
    LObj.Free;
  end;
end;

procedure TTestJson.LerInteiro_Ausente_Zero;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.ParseJSONValue('{"id":7}') as TJSONObject;
  try
    Assert.AreEqual(7, LerInteiro(LObj, 'id'));
    Assert.AreEqual(0, LerInteiro(LObj, 'estoque'));
  finally
    LObj.Free;
  end;
end;

procedure TTestJson.LerDataHora_Iso8601ComFuso;
var
  LObj: TJSONObject;
  LUtc: TDateTime;
begin
  LObj := TJSONObject.ParseJSONValue('{"data":"2026-11-20T10:15:00.000-03:00"}') as TJSONObject;
  try
    // compara em UTC para não depender do fuso da máquina que roda o teste
    LUtc := TTimeZone.Local.ToUniversalTime(LerDataHora(LObj, 'data'));
    Assert.AreEqual(EncodeDateTime(2026, 11, 20, 13, 15, 0, 0), LUtc, OneSecond);
  finally
    LObj.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJson);

end.
