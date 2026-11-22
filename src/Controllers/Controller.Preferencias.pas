unit Controller.Preferencias;

// Preferências de tela guardadas por usuário do Windows (itens por página, layout dos grids).

interface

type
  TPreferenciasTela = class
  public
    class function ItensPorPagina: Integer; static;
    class procedure DefinirItensPorPagina(AValor: Integer); static;
    /// Arquivo .ini onde os grids guardam colunas, larguras e ordenação.
    class function ArquivoGrids: string; static;
    /// Seção do grid no ArquivoGrids. O DevExpress guarda as colunas pelo ID (ordem de
    /// criação), então a chave muda junto com as colunas: layout de outra versão é ignorado.
    class function ChaveGrid(const AClasse: string; const AColunas: array of string): string; static;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Hash, Infra.Preferencias;

const
  SECAO = 'Telas';
  OPCOES: array[0..2] of Integer = (20, 50, 100);

class function TPreferenciasTela.ItensPorPagina: Integer;
var
  LOpcao: Integer;
begin
  Result := StrToIntDef(Preferencias.Ler(SECAO, 'ItensPorPagina', '20'), 20);
  for LOpcao in OPCOES do
    if Result = LOpcao then
      Exit;
  Result := 20; // valor editado à mão fora das opções: volta ao padrão
end;

class procedure TPreferenciasTela.DefinirItensPorPagina(AValor: Integer);
begin
  Preferencias.Gravar(SECAO, 'ItensPorPagina', AValor.ToString);
end;

class function TPreferenciasTela.ArquivoGrids: string;
begin
  Result := TPath.Combine(PastaUsuario, 'grids.ini');
end;

class function TPreferenciasTela.ChaveGrid(const AClasse: string; const AColunas: array of string): string;
begin
  Result := AClasse + '.' + THashBobJenkins.GetHashString(string.Join('|', AColunas));
end;

end.
