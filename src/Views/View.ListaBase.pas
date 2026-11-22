unit View.ListaBase;

{
  Frame base das listas paginadas (clientes, produtos, pedidos): busca, grid,
  botões Novo/Editar/Inativar e a barra de paginação.

  As telas filhas não têm .dfm próprio: herdam este e criam as colunas em
  código (CriarColunas). Cada filha diz como buscar a página na API
  (BuscarPagina, roda fora da thread principal) e como mostrá-la
  (ExibirPagina, roda na thread principal).
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, dxDateRanges, dxScrollbarAnnotations, cxGridCustomTableView,
  cxGridTableView, cxGridCustomView, cxClasses, cxGridLevel, cxGrid, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtons, dxPanel, Infra.Async;

type
  TfraListaBase = class(TFrame)
    pnlFerramentas: TdxPanel;
    edtBusca: TcxTextEdit;
    btnInativar: TcxButton;
    btnEditar: TcxButton;
    btnNovo: TcxButton;
    grdLista: TcxGrid;
    tvLista: TcxGridTableView;
    lvLista: TcxGridLevel;
    pnlRodape: TdxPanel;
    btnAnterior: TcxButton;
    lblPagina: TcxLabel;
    btnProxima: TcxButton;
    lblTotal: TcxLabel;
    lblPorPagina: TcxLabel;
    cbPorPagina: TcxComboBox;
    lblCarregando: TcxLabel;
    tmrBusca: TTimer;
    procedure edtBuscaPropertiesChange(Sender: TObject);
    procedure edtBuscaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tmrBuscaTimer(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnInativarClick(Sender: TObject);
    procedure btnAnteriorClick(Sender: TObject);
    procedure btnProximaClick(Sender: TObject);
    procedure cbPorPaginaPropertiesChange(Sender: TObject);
    procedure tvListaDblClick(Sender: TObject);
    procedure tvListaFocusedRecordChanged(Sender: TcxCustomGridTableView; APrevFocusedRecord,
      AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
  private
    FSinal: ISinalVida;
    FPagina: Integer;
    FTotalPaginas: Integer;
    FOcupado: Boolean;
    FColunaId: TcxGridColumn;
    FCarregandoPreferencias: Boolean;
    procedure DefinirOcupado(AOcupado: Boolean);
    procedure AtualizarRodape(ATotal: Integer);
  protected
    procedure CriarColunas; virtual; abstract;
    function AdicionarColuna(const ANome, ATitulo: string; ALargura: Integer;
      const ATipo: string = 'String'): TcxGridColumn;
    /// Roda fora da thread principal; devolve a TPagina<T> (ou outro objeto) que ExibirPagina vai ler.
    function BuscarPagina(APagina, ALimite: Integer; const ABusca: string): TObject; virtual; abstract;
    /// Roda na thread principal. Preenche o grid (DefinirLinha) e devolve total e total de páginas.
    procedure ExibirPagina(ADados: TObject; out ATotal, ATotalPaginas: Integer); virtual; abstract;
    procedure DefinirLinha(AIndice, AId: Integer; const AValores: array of Variant);
    procedure Novo; virtual; abstract;
    procedure Editar(AId: Integer); virtual; abstract;
    procedure Inativar(AId: Integer); virtual; abstract;
    function MensagemInativar(const ADescricao: string): string; virtual; abstract;
    /// Telas sem busca de texto (pedidos) devolvem False e a caixa de busca some.
    function TemBusca: Boolean; virtual;
    /// Executa AAcao fora da thread principal com a tela "ocupada"; ASucesso só roda se a
    /// tela ainda existir; ALimpeza roda sempre (para liberar o que a ação criou).
    procedure Executar(const AAcao, ASucesso: TProc; const ALimpeza: TProc = nil);
    function IdSelecionado: Integer;
    function DescricaoSelecionada: string;
    function TextoBusca: string;
    property Pagina: Integer read FPagina;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Carregar(APagina: Integer);
    procedure Recarregar;
  end;

implementation

{$R *.dfm}

uses
  System.Math, System.UITypes, Vcl.Dialogs, Controller.Preferencias, View.Estilo;

const
  ITENS_POR_PAGINA: array[0..2] of Integer = (20, 50, 100);

constructor TfraListaBase.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);
  FSinal := NovoSinalVida;
  FPagina := 1;
  FTotalPaginas := 1;
  EstilizarBotao(btnNovo, TFuncaoBotao.Novo);
  EstilizarBotao(btnEditar, TFuncaoBotao.Editar);
  EstilizarBotao(btnInativar, TFuncaoBotao.Perigo);
  EstilizarBotao(btnAnterior, TFuncaoBotao.Neutro);
  EstilizarBotao(btnProxima, TFuncaoBotao.Neutro);
  lblPagina.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblTotal.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblPorPagina.Style.TextColor := COR_TEXTO_SECUNDARIO;
  lblCarregando.Style.TextColor := COR_MARCA;
  lblCarregando.Visible := False;
  edtBusca.Visible := TemBusca;

  FColunaId := AdicionarColuna('colId', 'Id', 0, 'Integer');
  FColunaId.Visible := False;
  FColunaId.VisibleForCustomization := False;
  CriarColunas;
  tvLista.RestoreFromIniFile(TPreferenciasTela.ArquivoGrids, False, False, [], ClassName);

  FCarregandoPreferencias := True;
  try
    for I := Low(ITENS_POR_PAGINA) to High(ITENS_POR_PAGINA) do
      if ITENS_POR_PAGINA[I] = TPreferenciasTela.ItensPorPagina then
        cbPorPagina.ItemIndex := I;
  finally
    FCarregandoPreferencias := False;
  end;
  AtualizarRodape(0);
end;

destructor TfraListaBase.Destroy;
begin
  FSinal.Desativar;
  try
    tvLista.StoreToIniFile(TPreferenciasTela.ArquivoGrids, False, [], ClassName);
  except
    // preferência de tela não pode impedir o fechamento
  end;
  inherited;
end;

function TfraListaBase.TemBusca: Boolean;
begin
  Result := True;
end;

function TfraListaBase.AdicionarColuna(const ANome, ATitulo: string; ALargura: Integer;
  const ATipo: string): TcxGridColumn;
begin
  Result := tvLista.CreateColumn;
  Result.Name := ANome; // o nome é a chave do layout salvo
  Result.Caption := ATitulo;
  Result.DataBinding.ValueType := ATipo;
  Result.Options.Editing := False;
  if ALargura > 0 then
    Result.Width := ALargura;
end;

procedure TfraListaBase.DefinirLinha(AIndice, AId: Integer; const AValores: array of Variant);
var
  I: Integer;
begin
  tvLista.DataController.Values[AIndice, FColunaId.Index] := AId;
  for I := 0 to High(AValores) do
    tvLista.DataController.Values[AIndice, I + 1] := AValores[I];
end;

function TfraListaBase.IdSelecionado: Integer;
var
  LIndice: Integer;
begin
  Result := 0;
  LIndice := tvLista.DataController.FocusedRecordIndex;
  if LIndice >= 0 then
    Result := tvLista.DataController.Values[LIndice, FColunaId.Index];
end;

function TfraListaBase.DescricaoSelecionada: string;
var
  LIndice: Integer;
begin
  Result := '';
  LIndice := tvLista.DataController.FocusedRecordIndex;
  if (LIndice >= 0) and (tvLista.ColumnCount > 1) then
    Result := VarToStr(tvLista.DataController.Values[LIndice, 1]);
end;

function TfraListaBase.TextoBusca: string;
begin
  Result := edtBusca.Text;
end;

procedure TfraListaBase.DefinirOcupado(AOcupado: Boolean);
begin
  FOcupado := AOcupado;
  lblCarregando.Visible := AOcupado;
  Screen.Cursor := IfThen(AOcupado, crAppStart, crDefault);
  btnNovo.Enabled := not AOcupado;
  btnAnterior.Enabled := not AOcupado and (FPagina > 1);
  btnProxima.Enabled := not AOcupado and (FPagina < FTotalPaginas);
  cbPorPagina.Enabled := not AOcupado;
  btnEditar.Enabled := not AOcupado and (IdSelecionado > 0);
  btnInativar.Enabled := btnEditar.Enabled;
end;

procedure TfraListaBase.Executar(const AAcao, ASucesso, ALimpeza: TProc);
var
  LSinal: ISinalVida;
begin
  LSinal := FSinal;
  DefinirOcupado(True);
  ExecutarAsync(AAcao,
    procedure
    begin
      try
        if LSinal.Ativo then
        begin
          DefinirOcupado(False);
          ASucesso;
        end
        else
          Screen.Cursor := crDefault;
      finally
        if Assigned(ALimpeza) then
          ALimpeza;
      end;
    end,
    procedure(E: Exception)
    begin
      try
        if LSinal.Ativo then
        begin
          DefinirOcupado(False);
          MostrarErro(E);
        end
        else
          Screen.Cursor := crDefault;
      finally
        if Assigned(ALimpeza) then
          ALimpeza;
      end;
    end);
end;

procedure TfraListaBase.Carregar(APagina: Integer);
var
  LBusca: string;
  LLimite: Integer;
  LDados: TObject;
  LSinal: ISinalVida;
begin
  if FOcupado then
    Exit;
  LSinal := FSinal;
  LBusca := TextoBusca;
  LLimite := TPreferenciasTela.ItensPorPagina;
  LDados := nil;
  Executar(
    procedure
    begin
      LDados := BuscarPagina(APagina, LLimite, LBusca);
    end,
    procedure
    var
      LTotal, LTotalPaginas: Integer;
    begin
      tvLista.BeginUpdate;
      try
        tvLista.DataController.RecordCount := 0;
        ExibirPagina(LDados, LTotal, LTotalPaginas);
      finally
        tvLista.EndUpdate;
      end;
      FPagina := APagina;
      FTotalPaginas := LTotalPaginas;
      // inativou o último item da página: volta para a anterior
      if (tvLista.DataController.RecordCount = 0) and (APagina > 1) then
      begin
        TThread.ForceQueue(nil,
          procedure
          begin
            if LSinal.Ativo then
              Carregar(APagina - 1);
          end);
        Exit;
      end;
      AtualizarRodape(LTotal);
    end,
    procedure
    begin
      LDados.Free;
    end);
end;

procedure TfraListaBase.Recarregar;
begin
  Carregar(FPagina);
end;

procedure TfraListaBase.AtualizarRodape(ATotal: Integer);
begin
  lblPagina.Caption := Format('Página %d de %d', [FPagina, FTotalPaginas]);
  if ATotal = 1 then
    lblTotal.Caption := '1 registro'
  else
    lblTotal.Caption := Format('%d registros', [ATotal]);
  DefinirOcupado(FOcupado);
end;

procedure TfraListaBase.edtBuscaPropertiesChange(Sender: TObject);
begin
  // espera a pessoa parar de digitar antes de chamar a API
  tmrBusca.Enabled := False;
  tmrBusca.Enabled := True;
end;

procedure TfraListaBase.edtBuscaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    tmrBuscaTimer(nil);
  end;
end;

procedure TfraListaBase.tmrBuscaTimer(Sender: TObject);
begin
  tmrBusca.Enabled := False;
  Carregar(1);
end;

procedure TfraListaBase.btnNovoClick(Sender: TObject);
begin
  Novo;
end;

procedure TfraListaBase.btnEditarClick(Sender: TObject);
begin
  if IdSelecionado > 0 then
    Editar(IdSelecionado);
end;

procedure TfraListaBase.tvListaDblClick(Sender: TObject);
begin
  if not FOcupado then
    btnEditarClick(nil);
end;

procedure TfraListaBase.btnInativarClick(Sender: TObject);
var
  LId: Integer;
begin
  LId := IdSelecionado;
  if LId = 0 then
    Exit;
  if MessageDlg(MensagemInativar(DescricaoSelecionada), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  Executar(
    procedure
    begin
      Inativar(LId);
    end,
    procedure
    begin
      Recarregar;
    end);
end;

procedure TfraListaBase.btnAnteriorClick(Sender: TObject);
begin
  if FPagina > 1 then
    Carregar(FPagina - 1);
end;

procedure TfraListaBase.btnProximaClick(Sender: TObject);
begin
  if FPagina < FTotalPaginas then
    Carregar(FPagina + 1);
end;

procedure TfraListaBase.cbPorPaginaPropertiesChange(Sender: TObject);
begin
  if FCarregandoPreferencias or (cbPorPagina.ItemIndex < 0) then
    Exit;
  TPreferenciasTela.DefinirItensPorPagina(ITENS_POR_PAGINA[cbPorPagina.ItemIndex]);
  Carregar(1);
end;

procedure TfraListaBase.tvListaFocusedRecordChanged(Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
begin
  DefinirOcupado(FOcupado);
end;

end.
