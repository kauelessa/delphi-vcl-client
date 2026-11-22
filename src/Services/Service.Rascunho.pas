unit Service.Rascunho;

// Rascunho do pedido em digitação: %APPDATA%\DelphiVclClient\rascunho-pedido.json

interface

uses
  Model.PedidoDigitacao;

type
  IRascunhoPedido = interface
    ['{2B8E4F17-C9A3-4D5E-90B6-A1F7C3E8D452}']
    procedure Salvar(APedido: TPedidoEmDigitacao);
    /// nil se não houver rascunho ou o arquivo estiver inválido. O objeto é do chamador.
    function Carregar: TPedidoEmDigitacao;
    procedure Descartar;
    function Existe: Boolean;
  end;

  TRascunhoArquivo = class(TInterfacedObject, IRascunhoPedido)
  private
    FArquivo: string;
  public
    constructor Create(const AArquivo: string);
    procedure Salvar(APedido: TPedidoEmDigitacao);
    function Carregar: TPedidoEmDigitacao;
    procedure Descartar;
    function Existe: Boolean;
  end;

/// Caminho padrão do rascunho na pasta do usuário.
function ArquivoRascunhoPadrao: string;

implementation

uses
  System.SysUtils, System.IOUtils, Infra.Preferencias;

function ArquivoRascunhoPadrao: string;
begin
  Result := TPath.Combine(PastaUsuario, 'rascunho-pedido.json');
end;

constructor TRascunhoArquivo.Create(const AArquivo: string);
begin
  inherited Create;
  FArquivo := AArquivo;
end;

procedure TRascunhoArquivo.Salvar(APedido: TPedidoEmDigitacao);
begin
  ForceDirectories(ExtractFilePath(FArquivo));
  TFile.WriteAllText(FArquivo, APedido.ParaJson, TEncoding.UTF8);
end;

function TRascunhoArquivo.Carregar: TPedidoEmDigitacao;
begin
  Result := nil;
  if not Existe then
    Exit;
  try
    Result := TPedidoEmDigitacao.DeJson(TFile.ReadAllText(FArquivo, TEncoding.UTF8));
  except
    Result := nil; // arquivo ilegível vale como "sem rascunho"
  end;
end;

procedure TRascunhoArquivo.Descartar;
begin
  if Existe then
    TFile.Delete(FArquivo);
end;

function TRascunhoArquivo.Existe: Boolean;
begin
  Result := TFile.Exists(FArquivo);
end;

end.
