object frmPedidoDetalhe: TfrmPedidoDetalhe
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Pedido'
  ClientHeight = 470
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 17
  object pnlCartao: TdxPanel
    Left = 16
    Top = 16
    Width = 608
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
      Left = 460
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
      Left = 384
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
      Left = 474
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
