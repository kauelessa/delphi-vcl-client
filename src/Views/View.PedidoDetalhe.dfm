object frmPedidoDetalhe: TfrmPedidoDetalhe
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Pedido'
  ClientHeight = 470
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object pnlCartao: TdxPanel
    Left = 16
    Top = 16
    Width = 868
    Height = 438
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Pedido'
      Transparent = True
    end
    object lblStatus: TcxLabel
      Left = 720
      Top = 18
      AutoSize = False
      Caption = 'ABERTO'
      Properties.Alignment.Horz = taRightJustify
      Properties.Alignment.Vert = taVCenter
      Transparent = True
      Height = 30
      Width = 124
    end
    object lblCliente: TcxLabel
      Left = 24
      Top = 58
      Caption = 'Cliente'
      Transparent = True
    end
    object lblData: TcxLabel
      Left = 24
      Top = 80
      Caption = 'Data'
      Transparent = True
    end
    object lblVendedor: TcxLabel
      Left = 320
      Top = 58
      Caption = 'Vendedor'
      Transparent = True
    end
    object lblOrigem: TcxLabel
      Left = 320
      Top = 80
      Caption = 'Origem'
      Transparent = True
    end
    object lblNota: TcxLabel
      Left = 612
      Top = 112
      AutoSize = False
      Caption = 'NF-e'
      Properties.WordWrap = True
      Transparent = True
      Height = 44
      Width = 232
    end
    object lblLocal: TcxLabel
      Left = 612
      Top = 162
      AutoSize = False
      Caption = 'Local'
      Properties.WordWrap = True
      Transparent = True
      Height = 44
      Width = 232
    end
    object btnMapa: TcxButton
      Left = 612
      Top = 208
      Width = 140
      Height = 32
      Caption = 'Ver no mapa'
      TabOrder = 2
      OnClick = btnMapaClick
    end
    object lblAssinatura: TcxLabel
      Left = 612
      Top = 252
      Caption = 'Assinatura do cliente'
      Transparent = True
    end
    object imgAssinatura: TcxImage
      Left = 612
      Top = 276
      Properties.GraphicClassName = 'TdxSmartImage'
      Properties.ReadOnly = True
      Properties.ShowFocusRect = False
      Style.BorderStyle = ebsSingle
      TabOrder = 3
      Height = 76
      Width = 232
    end
    object lblObservacao: TcxLabel
      Left = 24
      Top = 356
      AutoSize = False
      Caption = 'Observa'#231#227'o'
      Properties.WordWrap = True
      Transparent = True
      Height = 32
      Width = 340
    end
    object grdItens: TcxGrid
      Left = 24
      Top = 112
      Width = 560
      Height = 240
      TabOrder = 0
      object tvItens: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsData.Deleting = False
        OptionsData.DeletingConfirmation = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.ColumnAutoWidth = True
        OptionsView.GroupByBox = False
        OptionsView.NoDataToDisplayInfoText = '<Sem itens>'
        object colProduto: TcxGridColumn
          Caption = 'Produto'
          Width = 240
        end
        object colQuantidade: TcxGridColumn
          Caption = 'Qtd'
          DataBinding.ValueType = 'Integer'
          PropertiesClassName = 'TcxTextEditProperties'
          Properties.Alignment.Horz = taRightJustify
          HeaderAlignmentHorz = taRightJustify
          Width = 60
        end
        object colPreco: TcxGridColumn
          Caption = 'Pre'#231'o unit.'
          DataBinding.ValueType = 'Currency'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = 'R$ ,0.00'
          HeaderAlignmentHorz = taRightJustify
          Width = 110
        end
        object colTotal: TcxGridColumn
          Caption = 'Total'
          DataBinding.ValueType = 'Currency'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = 'R$ ,0.00'
          HeaderAlignmentHorz = taRightJustify
          Width = 110
        end
      end
      object lvItens: TcxGridLevel
        GridView = tvItens
      end
    end
    object lblTotal: TcxLabel
      Left = 644
      Top = 356
      AutoSize = False
      Caption = 'Total'
      Properties.Alignment.Horz = taRightJustify
      Properties.Alignment.Vert = taVCenter
      Transparent = True
      Height = 32
      Width = 200
    end
    object btnFechar: TcxButton
      Left = 734
      Top = 392
      Width = 110
      Height = 34
      Cancel = True
      Caption = 'Fechar'
      Default = True
      ModalResult = 2
      TabOrder = 1
    end
  end
end
