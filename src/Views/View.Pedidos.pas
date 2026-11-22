unit View.Pedidos;

{
  Lista de pedidos. Usa o .dfm de TfraListaBase: a busca de texto dá lugar ao
  filtro por cliente (a API filtra pedidos por clienteId), "Editar" vira "Ver"
  e "Inativar" vira "Cancelar", habilitado só para pedidos ABERTOS.
}

interface

uses
  System.Classes, cxGraphics, cxGridCustomTableView, cxGridTableView, cxButtons, cxLabel,
  View.ListaBase;

type
  TfraPedidos = class(TfraListaBase)
  private
    FClienteId: Integer;
    FColunaStatus: TcxGridColumn;
    FLblFiltro: TcxLabel;
    FBtnFiltrar: TcxButton;
    FBtnLimpar: TcxButton;
    procedure FiltrarClick(Sender: TObject);
    procedure LimparClick(Sender: TObject);
    procedure AtualizarFiltro(const ANomeCliente: string);
    procedure DesenharStatus(Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
  protected
    procedure CriarColunas; override;
    function BuscarPagina(APagina, ALimite: Integer; const ABusca: string): TObject; override;
    procedure ExibirPagina(ADados: TObject; out ATotal, ATotalPaginas: Integer); override;
    procedure Novo; override;
    procedure Editar(AId: Integer); override;
    procedure Inativar(AId: Integer); override;
    function MensagemInativar(const ADescricao: string): string; override;
    function TemBusca: Boolean; override;
    function PodeInativarSelecionado: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.SysUtils, System.Variants, Vcl.Controls, Vcl.Graphics, cxCurrencyEdit, cxCalendar,
  Model.Pedido, Model.Pagina, Model.Cliente, Controller.Pedido, View.Estilo, View.Seletor,
  View.PedidoDetalhe, View.PedidoNovo;

constructor TfraPedidos.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  tvLista.OnCustomDrawCell := DesenharStatus;

  // filtro por cliente no lugar da busca de texto
  FLblFiltro := TcxLabel.Create(Self);
  FLblFiltro.Parent := pnlFerramentas;
  FLblFiltro.Transparent := True;
  FLblFiltro.SetBounds(0, 12, 260, 22);
  FLblFiltro.Style.TextColor := COR_TEXTO_SECUNDARIO;

  FBtnFiltrar := TcxButton.Create(Self);
  FBtnFiltrar.Parent := pnlFerramentas;
  FBtnFiltrar.SetBounds(270, 4, 150, 36);
  FBtnFiltrar.Caption := 'Filtrar por cliente';
  FBtnFiltrar.OnClick := FiltrarClick;
  EstilizarBotao(FBtnFiltrar, TFuncaoBotao.Neutro);

  FBtnLimpar := TcxButton.Create(Self);
  FBtnLimpar.Parent := pnlFerramentas;
  FBtnLimpar.SetBounds(428, 4, 90, 36);
  FBtnLimpar.Caption := 'Limpar';
  FBtnLimpar.OnClick := LimparClick;
  EstilizarBotao(FBtnLimpar, TFuncaoBotao.Neutro);

  AtualizarFiltro('');
end;

function TfraPedidos.TemBusca: Boolean;
begin
  Result := False;
end;

procedure TfraPedidos.CriarColunas;
var
  LColuna: TcxGridColumn;
begin
  // botões da base com o vocabulário de pedidos
  btnNovo.Caption := '+ Novo pedido';
  btnNovo.Width := 140;
  btnNovo.Left := pnlFerramentas.Width - btnNovo.Width;
  btnEditar.Caption := 'Ver';
  btnEditar.Left := btnNovo.Left - btnEditar.Width - 8;
  btnInativar.Caption := 'Cancelar';
  btnInativar.Left := btnEditar.Left - btnInativar.Width - 8;

  AdicionarColuna('colNumero', 'Nº', 70, 'Integer');
  LColuna := AdicionarColuna('colData', 'Data', 150, 'DateTime');
  LColuna.PropertiesClass := TcxDateEditProperties;
  TcxDateEditProperties(LColuna.Properties).DisplayFormat := 'dd/mm/yyyy hh:nn';
  TcxDateEditProperties(LColuna.Properties).Kind := ckDateTime;
  AdicionarColuna('colCliente', 'Cliente', 240);
  AdicionarColuna('colVendedor', 'Vendedor', 160);
  AdicionarColuna('colOrigem', 'Origem', 70);
  FColunaStatus := AdicionarColuna('colStatus', 'Status', 110);
  LColuna := AdicionarColuna('colTotal', 'Total', 120, 'Currency');
  LColuna.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(LColuna.Properties).DisplayFormat := 'R$ ,0.00';
  TcxCurrencyEditProperties(LColuna.Properties).Alignment.Horz := taRightJustify;
  LColuna.HeaderAlignmentHorz := taRightJustify;
  AdicionarColuna('colNota', 'NF-e', 90);
end;

procedure TfraPedidos.AtualizarFiltro(const ANomeCliente: string);
begin
  if FClienteId = 0 then
    FLblFiltro.Caption := 'Todos os clientes'
  else
    FLblFiltro.Caption := 'Cliente: ' + ANomeCliente;
  FBtnLimpar.Enabled := FClienteId <> 0;
end;

procedure TfraPedidos.FiltrarClick(Sender: TObject);
var
  LCliente: TCliente;
begin
  if not TfrmSeletor.EscolherCliente(LCliente) then
    Exit;
  try
    FClienteId := LCliente.Id;
    AtualizarFiltro(LCliente.Nome);
  finally
    LCliente.Free;
  end;
  Carregar(1);
end;

procedure TfraPedidos.LimparClick(Sender: TObject);
begin
  FClienteId := 0;
  AtualizarFiltro('');
  Carregar(1);
end;

function TfraPedidos.BuscarPagina(APagina, ALimite: Integer; const ABusca: string): TObject;
begin
  Result := TPedidoController.Listar(APagina, ALimite, FClienteId);
end;

procedure TfraPedidos.ExibirPagina(ADados: TObject; out ATotal, ATotalPaginas: Integer);
var
  LPagina: TPagina<TPedido>;
  I: Integer;
  P: TPedido;
begin
  LPagina := ADados as TPagina<TPedido>;
  tvLista.DataController.RecordCount := LPagina.Dados.Count;
  for I := 0 to LPagina.Dados.Count - 1 do
  begin
    P := LPagina.Dados[I];
    DefinirLinha(I, P.Id, [P.Id, P.Data, P.ClienteNome, P.VendedorNome, P.OrigemDescricao,
      P.Status.Descricao, P.ValorTotal, P.NotaDescricao]);
  end;
  ATotal := LPagina.Total;
  ATotalPaginas := LPagina.TotalPaginas;
end;

function TfraPedidos.PodeInativarSelecionado: Boolean;
var
  LIndice: Integer;
begin
  LIndice := tvLista.DataController.FocusedRecordIndex;
  Result := (LIndice >= 0) and
    (VarToStr(tvLista.DataController.Values[LIndice, FColunaStatus.Index]) = TStatusPedido.Aberto.Descricao);
end;

procedure TfraPedidos.DesenharStatus(Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // status em verde (ABERTO) ou vermelho (CANCELADO); o grid desenha o resto normalmente
  if AViewInfo.Item <> FColunaStatus then
    Exit;
  ACanvas.Font.Style := [fsBold];
  if VarToStr(AViewInfo.Value) = TStatusPedido.Aberto.Descricao then
    ACanvas.Font.Color := COR_SUCESSO
  else
    ACanvas.Font.Color := COR_ERRO;
end;

procedure TfraPedidos.Novo;
begin
  if TfrmPedidoNovo.Executar then
    Carregar(1);
end;

procedure TfraPedidos.Editar(AId: Integer);
begin
  TfrmPedidoDetalhe.Mostrar(AId);
end;

procedure TfraPedidos.Inativar(AId: Integer);
begin
  TPedidoController.Cancelar(AId).Free;
end;

function TfraPedidos.MensagemInativar(const ADescricao: string): string;
begin
  Result := Format('Cancelar o pedido Nº %s? O estoque dos produtos volta.', [ADescricao]);
end;

end.
