unit Infra.Async;

{
  Roda AAcao numa thread do pool (TTask) e devolve o resultado na thread
  principal, por TThread.Queue: ASucesso se terminou bem, AErro com a exceção
  se não. Assim a tela nunca congela esperando a API e os callbacks podem
  mexer nos componentes VCL com segurança.

  A exceção entregue a AErro é liberada logo depois dele; não guarde a
  referência.
}

interface

uses
  System.SysUtils;

procedure ExecutarAsync(const AAcao: TProc; const ASucesso: TProc; const AErro: TProc<Exception>);

implementation

uses
  System.Classes, System.Threading;

procedure EntregarErro(AExcecao: Exception; const AErro: TProc<Exception>);
begin
  TThread.Queue(nil,
    procedure
    begin
      try
        AErro(AExcecao);
      finally
        AExcecao.Free;
      end;
    end);
end;

procedure ExecutarAsync(const AAcao: TProc; const ASucesso: TProc; const AErro: TProc<Exception>);
begin
  TTask.Run(
    procedure
    begin
      try
        AAcao;
      except
        // AcquireExceptionObject tira a exceção do controle do RTL para ela sobreviver ao except
        EntregarErro(Exception(AcquireExceptionObject), AErro);
        Exit;
      end;
      TThread.Queue(nil,
        procedure
        begin
          ASucesso;
        end);
    end);
end;

end.
