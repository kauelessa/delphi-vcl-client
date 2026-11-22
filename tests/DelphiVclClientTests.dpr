program DelphiVclClientTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework;

var
  LRunner: ITestRunner;
  LResultados: IRunResults;
begin
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.FailsOnNoAsserts := False;
    LRunner.AddLogger(TDUnitXConsoleLogger.Create(True));
    LRunner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile));

    LResultados := LRunner.Execute;
    if not LResultados.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Pressione <Enter> para sair.');
      System.Readln;
    end;
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
end.
