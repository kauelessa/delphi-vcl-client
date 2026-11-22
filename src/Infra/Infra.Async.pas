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

type
  // a tela cria um, desativa no Destroy, e os callbacks conferem antes de mexer nela:
  // se o usuário trocou de aba no meio da chamada, o retorno é simplesmente ignorado
  ISinalVida = interface
    ['{D41B7E28-3A6F-4C95-B8E0-5F2C9A1D7E63}']
    function Ativo: Boolean;
    procedure Desativar;
  end;

procedure ExecutarAsync(const AAcao: TProc; const ASucesso: TProc; const AErro: TProc<Exception>);
function NovoSinalVida: ISinalVida;

implementation

uses
  System.Classes, System.Threading;

type
  TSinalVida = class(TInterfacedObject, ISinalVida)
  private
    FAtivo: Boolean;
  public
    constructor Create;
    function Ativo: Boolean;
    procedure Desativar;
  end;

constructor TSinalVida.Create;
begin
  inherited Create;
  FAtivo := True;
end;

function TSinalVida.Ativo: Boolean;
begin
  Result := FAtivo;
end;

procedure TSinalVida.Desativar;
begin
  FAtivo := False;
end;

function NovoSinalVida: ISinalVida;
begin
  Result := TSinalVida.Create;
end;

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
