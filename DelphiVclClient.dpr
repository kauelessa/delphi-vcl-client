program DelphiVclClient;

uses
  Vcl.Forms;

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Vendas';
  Application.Run;
end.
