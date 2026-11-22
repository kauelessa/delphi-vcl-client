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
  Test.Http in 'Test.Http.pas',
  Infra.Json in '..\src\Infra\Infra.Json.pas',
  Api.Base in '..\src\Api\Api.Base.pas',
  Test.Fakes in 'Test.Fakes.pas',
  Test.Json in 'Test.Json.pas',
  Test.ApiBase in 'Test.ApiBase.pas',
  Model.Sessao in '..\src\Models\Model.Sessao.pas',
  Infra.Dpapi in '..\src\Infra\Infra.Dpapi.pas',
  Infra.Preferencias in '..\src\Infra\Infra.Preferencias.pas',
  Api.Auth in '..\src\Api\Api.Auth.pas',
  Api.Health in '..\src\Api\Api.Health.pas',
  Service.Sessao in '..\src\Services\Service.Sessao.pas',
  Test.Dpapi in 'Test.Dpapi.pas',
  Test.Sessao in 'Test.Sessao.pas',
  Model.Pagina in '..\src\Models\Model.Pagina.pas',
  Model.Cliente in '..\src\Models\Model.Cliente.pas',
  Model.Produto in '..\src\Models\Model.Produto.pas',
  Api.Cliente in '..\src\Api\Api.Cliente.pas',
  Api.Produto in '..\src\Api\Api.Produto.pas',
  Service.Cliente in '..\src\Services\Service.Cliente.pas',
  Service.Produto in '..\src\Services\Service.Produto.pas',
  Test.ClienteProduto in 'Test.ClienteProduto.pas';

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
