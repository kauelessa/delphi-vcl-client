unit Test.Async;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAsync = class
  private
    procedure AguardarFila(var ATerminou: Boolean);
  public
    [Test]
    procedure ExecutarAsync_SucessoNaThreadPrincipal;
    [Test]
    procedure ExecutarAsync_ErroChegaNaThreadPrincipal;
    [Test]
    procedure ExecutarAsync_AcaoRodaForaDaThreadPrincipal;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Diagnostics, Infra.Async, Infra.Excecoes;

procedure TTestAsync.AguardarFila(var ATerminou: Boolean);
var
  LTempo: TStopwatch;
begin
  LTempo := TStopwatch.StartNew;
  while not ATerminou and (LTempo.ElapsedMilliseconds < 5000) do
    CheckSynchronize(10);
  Assert.IsTrue(ATerminou, 'o retorno não chegou à thread principal em 5 s');
end;

procedure TTestAsync.ExecutarAsync_SucessoNaThreadPrincipal;
var
  LTerminou: Boolean;
  LThread: TThreadID;
begin
  LTerminou := False;
  LThread := 0;
  ExecutarAsync(
    procedure begin end,
    procedure
    begin
      LThread := TThread.CurrentThread.ThreadID;
      LTerminou := True;
    end,
    procedure(E: Exception)
    begin
      LTerminou := True;
    end);
  AguardarFila(LTerminou);
  Assert.AreEqual(MainThreadID, LThread);
end;

procedure TTestAsync.ExecutarAsync_ErroChegaNaThreadPrincipal;
var
  LTerminou: Boolean;
  LMensagem: string;
  LClasse: TClass;
  LThread: TThreadID;
begin
  LTerminou := False;
  ExecutarAsync(
    procedure
    begin
      raise EApiIndisponivel.Create('x');
    end,
    procedure
    begin
      LTerminou := True;
    end,
    procedure(E: Exception)
    begin
      LMensagem := E.Message;
      LClasse := E.ClassType;
      LThread := TThread.CurrentThread.ThreadID;
      LTerminou := True;
    end);
  AguardarFila(LTerminou);
  Assert.AreEqual('x', LMensagem);
  Assert.AreEqual(EApiIndisponivel, LClasse);
  Assert.AreEqual(MainThreadID, LThread);
end;

procedure TTestAsync.ExecutarAsync_AcaoRodaForaDaThreadPrincipal;
var
  LTerminou: Boolean;
  LThreadAcao: TThreadID;
begin
  LTerminou := False;
  LThreadAcao := MainThreadID;
  ExecutarAsync(
    procedure
    begin
      LThreadAcao := TThread.CurrentThread.ThreadID;
    end,
    procedure
    begin
      LTerminou := True;
    end,
    procedure(E: Exception)
    begin
      LTerminou := True;
    end);
  AguardarFila(LTerminou);
  Assert.AreNotEqual(MainThreadID, LThreadAcao);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAsync);

end.
