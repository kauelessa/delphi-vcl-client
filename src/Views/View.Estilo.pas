unit View.Estilo;

{
  Visual do sistema: skin WXI, botões em tons pastel por função e cartões
  brancos arredondados.

  Por que desenho próprio nos botões: com skin ativa, o TcxButton ignora a
  propriedade Colors (o painter da skin desenha o elemento sem usar a cor), e
  sem skin ele fica quadrado. O OnCustomDraw com GDI+ (dxGPPaintCanvas) dá o
  botão arredondado e com antialias, mantendo o TcxButton normal no .dfm.

  O cartão é um TdxPanel comum no .dfm, arredondado aqui por região
  (SetWindowRgn), para o form continuar abrindo no designer da IDE.
}

interface

uses
  System.SysUtils, Vcl.Graphics, Vcl.Controls, cxButtons;

type
  {$SCOPEDENUMS ON}
  TFuncaoBotao = (Novo, Editar, Perigo, Neutro, Aba);
  {$SCOPEDENUMS OFF}

const
  // cores em BGR (TColor); o comentário mostra o #RRGGBB
  COR_MARCA = $00E5464F;            // #4F46E5
  COR_TEXTO = $003B291E;            // #1E293B
  COR_TEXTO_SECUNDARIO = $008B7564; // #64748B
  COR_ERRO = $001C1CB9;             // #B91C1C
  COR_SUCESSO = $003D8015;          // #15803D
  COR_ETIQUETA_OK = $00E7FCDC;      // #DCFCE7
  COR_ETIQUETA_ERRO = $00E2E2FE;    // #FEE2E2

/// Aplica a skin WXI em todos os forms. Chamar uma vez, antes do primeiro form.
procedure AplicarTema;
procedure EstilizarBotao(AButton: TcxButton; AFuncao: TFuncaoBotao);
/// Aba selecionada (TFuncaoBotao.Aba): texto na cor da marca e sublinhado.
procedure SelecionarAba(AButton: TcxButton; ASelecionada: Boolean);
procedure ArredondarCartao(AControle: TWinControl; ARaio: Integer = 14);
/// Mostra o erro de uma chamada assíncrona com o mesmo tratamento das exceções da tela
/// (Application.OnException da janela principal: aviso para regra violada, erro + log para o resto).
procedure MostrarErro(AErro: Exception);

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.UITypes, Vcl.Forms, Vcl.Menus, cxGraphics,
  cxGeometry, cxLookAndFeelPainters, dxGDIPlusClasses, dxSkinsCore, dxSkinWXI, dxSkinsForm;

type
  TCoresBotao = record
    Fundo, FundoHot, Texto: TColor;
  end;

  // um só objeto atende o OnCustomDraw de todos os botões (o evento é "of object")
  TDesenhistaBotao = class
  public
    procedure Desenhar(Sender: TObject; ACanvas: TcxCanvas; AViewInfo: TcxButtonViewInfo;
      var AHandled: Boolean);
  end;

  // reaplica a região arredondada sempre que o controle muda de tamanho
  TArredondador = class(TComponent)
  private
    FControle: TWinControl;
    FRaio: Integer;
    FWndProcOriginal: TWndMethod;
    procedure WndProcNovo(var AMensagem: TMessage);
    procedure Aplicar;
  public
    constructor Criar(AControle: TWinControl; ARaio: Integer);
  end;

const
  CORES: array[TFuncaoBotao] of TCoresBotao = (
    (Fundo: $00FFE7E0; FundoHot: $00FED2C7; Texto: $00CA3843),   // Novo:   #E0E7FF / #C7D2FE / #4338CA
    (Fundo: $00E7FCDC; FundoHot: $00D0F7BB; Texto: $003D8015),   // Editar: #DCFCE7 / #BBF7D0 / #15803D
    (Fundo: $00E2E2FE; FundoHot: $00CACAFE; Texto: $001C1CB9),   // Perigo: #FEE2E2 / #FECACA / #B91C1C
    (Fundo: $00F9F5F1; FundoHot: $00F0E8E2; Texto: $00554133),   // Neutro: #F1F5F9 / #E2E8F0 / #334155
    (Fundo: clNone;    FundoHot: clNone;    Texto: $008B7564));  // Aba:    sem fundo / #64748B
  COR_DESABILITADO_FUNDO = $00F9F5F1; // #F1F5F9
  COR_DESABILITADO_TEXTO = $00B8A394; // #94A3B8
  RAIO_BOTAO = 10;
  // Tag do botão: byte baixo = TFuncaoBotao; este bit = aba selecionada
  TAG_ABA_SELECIONADA = $100;

var
  GDesenhista: TDesenhistaBotao;
  GSkin: TdxSkinController;

procedure AplicarTema;
begin
  if GSkin <> nil then
    Exit;
  GSkin := TdxSkinController.Create(Application);
  GSkin.NativeStyle := False;
  GSkin.SkinName := 'WXI';
end;

procedure EstilizarBotao(AButton: TcxButton; AFuncao: TFuncaoBotao);
begin
  AButton.Tag := Ord(AFuncao);
  AButton.Cursor := crHandPoint;
  AButton.OnCustomDraw := GDesenhista.Desenhar;
  AButton.Invalidate;
end;

procedure SelecionarAba(AButton: TcxButton; ASelecionada: Boolean);
begin
  if ASelecionada then
    AButton.Tag := AButton.Tag or TAG_ABA_SELECIONADA
  else
    AButton.Tag := AButton.Tag and not TAG_ABA_SELECIONADA;
  AButton.Invalidate;
end;

procedure ArredondarCartao(AControle: TWinControl; ARaio: Integer);
begin
  TArredondador.Criar(AControle, ARaio);
end;

procedure MostrarErro(AErro: Exception);
begin
  if Assigned(Application.OnException) then
    Application.OnException(Application, AErro)
  else
    Application.ShowException(AErro);
end;

function CorDeFundoDoPai(AControle: TControl): TColor;
begin
  // cartões e barra do topo são brancos; fora deles fica a cor da janela
  if (AControle.Parent <> nil) and (AControle.Parent.Brush.Color <> clNone) then
    Result := AControle.Parent.Brush.Color
  else
    Result := clWhite;
end;

{ TDesenhistaBotao }

procedure TDesenhistaBotao.Desenhar(Sender: TObject; ACanvas: TcxCanvas; AViewInfo: TcxButtonViewInfo;
  var AHandled: Boolean);
var
  LBotao: TcxButton;
  LFuncao: TFuncaoBotao;
  LRect, LTexto: TRect;
  LFundo, LCorTexto: TColor;
  LSelecionada: Boolean;
begin
  LBotao := TcxButton(Sender);
  LFuncao := TFuncaoBotao(LBotao.Tag and $FF);
  LRect := LBotao.ClientRect;
  ACanvas.FillRect(LRect, CorDeFundoDoPai(LBotao));

  LCorTexto := CORES[LFuncao].Texto;
  LSelecionada := (LFuncao = TFuncaoBotao.Aba) and (LBotao.Tag and TAG_ABA_SELECIONADA <> 0);

  if LFuncao = TFuncaoBotao.Aba then
  begin
    if LSelecionada then
      LCorTexto := COR_MARCA
    else if AViewInfo.State = cxbsHot then
      LCorTexto := COR_TEXTO;
    if LSelecionada then
      ACanvas.FillRect(Rect(LRect.Left + 8, LRect.Bottom - 3, LRect.Right - 8, LRect.Bottom), COR_MARCA);
  end
  else
  begin
    if not LBotao.Enabled then
    begin
      LFundo := COR_DESABILITADO_FUNDO;
      LCorTexto := COR_DESABILITADO_TEXTO;
    end
    else if AViewInfo.State in [cxbsHot, cxbsPressed] then
      LFundo := CORES[LFuncao].FundoHot
    else
      LFundo := CORES[LFuncao].Fundo;

    dxGPPaintCanvas.BeginPaint(ACanvas.Handle, LRect);
    try
      dxGPPaintCanvas.SmoothingMode := smAntiAlias;
      dxGPPaintCanvas.RoundRect(cxRectInflate(LRect, -1, -1), LFundo, LFundo, RAIO_BOTAO, RAIO_BOTAO, 1, 255, 255);
      if LBotao.Focused then
        dxGPPaintCanvas.RoundRect(cxRectInflate(LRect, -1, -1), LCorTexto, LFundo, RAIO_BOTAO, RAIO_BOTAO, 1, 160, 0);
    finally
      dxGPPaintCanvas.EndPaint;
    end;
  end;

  ACanvas.Font.Assign(LBotao.Font);
  ACanvas.Font.Color := LCorTexto;
  if (LFuncao <> TFuncaoBotao.Aba) or LSelecionada then
    ACanvas.Font.Style := [fsBold];
  ACanvas.Brush.Style := bsClear;
  LTexto := LRect;
  if AViewInfo.State = cxbsPressed then
    OffsetRect(LTexto, 0, 1);
  ACanvas.DrawTexT(StripHotkey(LBotao.Caption), LTexto, cxAlignCenter or cxAlignVCenter or cxSingleLine);
  AHandled := True;
end;

{ TArredondador }

constructor TArredondador.Criar(AControle: TWinControl; ARaio: Integer);
begin
  inherited Create(AControle); // liberado junto com o controle
  FControle := AControle;
  FRaio := ARaio;
  FWndProcOriginal := AControle.WindowProc;
  AControle.WindowProc := WndProcNovo;
  if AControle.HandleAllocated then
    Aplicar;
end;

procedure TArredondador.Aplicar;
begin
  SetWindowRgn(FControle.Handle,
    CreateRoundRectRgn(0, 0, FControle.Width + 1, FControle.Height + 1, FRaio, FRaio), True);
end;

procedure TArredondador.WndProcNovo(var AMensagem: TMessage);
begin
  FWndProcOriginal(AMensagem);
  if (AMensagem.Msg = WM_SIZE) or (AMensagem.Msg = WM_WINDOWPOSCHANGED) then
    if FControle.HandleAllocated then
      Aplicar;
end;

initialization
  GDesenhista := TDesenhistaBotao.Create;

finalization
  GDesenhista.Free;

end.
