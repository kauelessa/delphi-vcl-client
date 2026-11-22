object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Vendas'
  ClientHeight = 640
  ClientWidth = 1040
  Color = clBtnFace
  Constraints.MinHeight = 520
  Constraints.MinWidth = 860
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object pnlTopo: TdxPanel
    Left = 0
    Top = 0
    Width = 1040
    Height = 56
    Align = alTop
    Color = clWhite
    TabOrder = 0
    DesignSize = (
      1040
      56)
    object lblMarca: TcxLabel
      Left = 20
      Top = 14
      Caption = 'Vendas'
      Transparent = True
    end
    object btnAbaPedidos: TcxButton
      Left = 140
      Top = 8
      Width = 100
      Height = 46
      Caption = 'Pedidos'
      TabOrder = 0
      OnClick = btnAbaClick
    end
    object btnAbaClientes: TcxButton
      Left = 244
      Top = 8
      Width = 100
      Height = 46
      Caption = 'Clientes'
      TabOrder = 1
      OnClick = btnAbaClick
    end
    object btnAbaProdutos: TcxButton
      Left = 348
      Top = 8
      Width = 100
      Height = 46
      Caption = 'Produtos'
      TabOrder = 2
      OnClick = btnAbaClick
    end
    object lblUsuario: TcxLabel
      Left = 640
      Top = 15
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'usu'#225'rio'
      Properties.Alignment.Horz = taRightJustify
      Transparent = True
      Properties.Alignment.Vert = taVCenter
      Height = 28
      Width = 380
    end
  end
  object pnlConteudo: TdxPanel
    Left = 0
    Top = 56
    Width = 1040
    Height = 560
    Align = alClient
    TabOrder = 1
    object pnlCartao: TdxPanel
      AlignWithMargins = True
      Left = 16
      Top = 16
      Width = 1008
      Height = 528
      Margins.Left = 16
      Margins.Top = 16
      Margins.Right = 16
      Margins.Bottom = 16
      Align = alClient
      Color = clWhite
      TabOrder = 0
    end
  end
  object sbPrincipal: TdxStatusBar
    Left = 0
    Top = 616
    Width = 1040
    Height = 24
    Panels = <
      item
        PanelStyleClassName = 'TdxStatusBarTextPanelStyle'
        Width = 520
      end
      item
        PanelStyleClassName = 'TdxStatusBarTextPanelStyle'
      end>
    PaintStyle = stpsUseLookAndFeel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
  end
  object tmrHealth: TTimer
    Interval = 30000
    OnTimer = tmrHealthTimer
    Left = 960
    Top = 80
  end
end
