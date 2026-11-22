unit Test.Preferencias;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestPreferencias = class
  public
    // o grid guarda o layout pelo ID da coluna (ordem de criacao): coluna nova no meio
    // fazia a "Origem" herdar largura e alinhamento da antiga "Total"
    [Test]
    procedure ChaveGrid_MesmasColunas_MesmaChave;
    [Test]
    procedure ChaveGrid_ColunaNova_ChaveDiferente;
    [Test]
    procedure ChaveGrid_ComecaPelaClasse;
  end;

implementation

uses
  System.SysUtils, Controller.Preferencias;

procedure TTestPreferencias.ChaveGrid_MesmasColunas_MesmaChave;
begin
  Assert.AreEqual(TPreferenciasTela.ChaveGrid('TfraPedidos', ['colId', 'colNumero', 'colTotal']),
    TPreferenciasTela.ChaveGrid('TfraPedidos', ['colId', 'colNumero', 'colTotal']));
end;

procedure TTestPreferencias.ChaveGrid_ColunaNova_ChaveDiferente;
begin
  Assert.AreNotEqual(TPreferenciasTela.ChaveGrid('TfraPedidos', ['colId', 'colNumero', 'colTotal']),
    TPreferenciasTela.ChaveGrid('TfraPedidos', ['colId', 'colNumero', 'colOrigem', 'colTotal']));
end;

procedure TTestPreferencias.ChaveGrid_ComecaPelaClasse;
begin
  Assert.StartsWith('TfraPedidos.', TPreferenciasTela.ChaveGrid('TfraPedidos', ['colId']));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPreferencias);

end.
