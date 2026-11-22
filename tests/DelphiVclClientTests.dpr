program DelphiVclClientTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Infra.Excecoes in '..\src\Infra\Infra.Excecoes.pas',
  Infra.Config in '..\src\Infra\Infra.Config.pas',
  Infra.Log in '..\src\Infra\Infra.Log.pas',
  Infra.LogHttp in '..\src\Infra\Infra.LogHttp.pas',
  Infra.Http in '..\src\Infra\Infra.Http.pas',
  Test.LogHttp in 'Test.LogHttp.pas',
  Test.Config in 'Test.Config.pas',
  Test.Http in 'Test.Http.pas';

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
