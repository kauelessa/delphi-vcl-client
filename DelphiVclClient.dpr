program DelphiVclClient;

uses
  Vcl.Forms,
  Model.Sessao in 'src\Models\Model.Sessao.pas',
  Model.Pagina in 'src\Models\Model.Pagina.pas',
  Model.Cliente in 'src\Models\Model.Cliente.pas',
  Model.Produto in 'src\Models\Model.Produto.pas',
  Model.Pedido in 'src\Models\Model.Pedido.pas',
  Model.PedidoDigitacao in 'src\Models\Model.PedidoDigitacao.pas',
  Infra.Excecoes in 'src\Infra\Infra.Excecoes.pas',
  Infra.Config in 'src\Infra\Infra.Config.pas',
  Infra.Log in 'src\Infra\Infra.Log.pas',
  Infra.LogHttp in 'src\Infra\Infra.LogHttp.pas',
  Infra.Http in 'src\Infra\Infra.Http.pas',
  Infra.Json in 'src\Infra\Infra.Json.pas',
  Infra.Dpapi in 'src\Infra\Infra.Dpapi.pas',
  Infra.Preferencias in 'src\Infra\Infra.Preferencias.pas',
  Infra.Async in 'src\Infra\Infra.Async.pas',
  Api.Base in 'src\Api\Api.Base.pas',
  Api.Auth in 'src\Api\Api.Auth.pas',
  Api.Health in 'src\Api\Api.Health.pas',
  Api.Cliente in 'src\Api\Api.Cliente.pas',
  Api.Produto in 'src\Api\Api.Produto.pas',
  Api.Pedido in 'src\Api\Api.Pedido.pas',
  Service.Sessao in 'src\Services\Service.Sessao.pas',
  Service.Cliente in 'src\Services\Service.Cliente.pas',
  Service.Produto in 'src\Services\Service.Produto.pas',
  Service.Rascunho in 'src\Services\Service.Rascunho.pas',
  Service.Pedido in 'src\Services\Service.Pedido.pas',
  Controller.Fabrica in 'src\Controllers\Controller.Fabrica.pas',
  Controller.Login in 'src\Controllers\Controller.Login.pas',
  Controller.Principal in 'src\Controllers\Controller.Principal.pas',
  View.Estilo in 'src\Views\View.Estilo.pas',
  View.Login in 'src\Views\View.Login.pas' {frmLogin},
  View.Relogin in 'src\Views\View.Relogin.pas' {frmRelogin},
  View.Principal in 'src\Views\View.Principal.pas' {frmPrincipal};

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Vendas';
  AplicarTema;
  LimparLogsAntigos(Config.PastaLog, Config.RetencaoLogDias);

  // sem login não há o que mostrar: desistir do login fecha o programa
  if not TfrmLogin.Executar then
    Exit;

  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
