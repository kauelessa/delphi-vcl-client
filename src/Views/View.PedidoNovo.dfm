object frmPedidoNovo: TfrmPedidoNovo
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Novo pedido'
  ClientHeight = 560
  ClientWidth = 720
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
    Width = 688
    Height = 528
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Novo pedido'
      Transparent = True
    end
    object lblClienteTitulo: TcxLabel
      Left = 24
      Top = 58
      Caption = 'Cliente'
      Transparent = True
    end
    object lblCliente: TcxLabel
      Left = 24
      Top = 80
      Caption = 'Nenhum cliente escolhido'
      Transparent = True
    end
    object btnEscolherCliente: TcxButton
      Left = 504
      Top = 70
      Width = 160
      Height = 36
      Caption = 'Escolher cliente'
      TabOrder = 0
      OnClick = btnEscolherClienteClick
    end
    object lblQuantidade: TcxLabel
      Left = 24
      Top = 120
      Caption = 'Quantidade'
      Transparent = True
    end
    object edtQuantidade: TcxSpinEdit
      Left = 24
      Top = 142
      Properties.MaxValue = 99999.000000000000000000
      Properties.MinValue = 1.000000000000000000
      TabOrder = 1
      Value = 1
      Width = 100
    end
    object btnAdicionarProduto: TcxButton
      Left = 136
      Top = 138
      Width = 170
      Height = 36
      Caption = 'Adicionar produto'
      TabOrder = 2
      OnClick = btnAdicionarProdutoClick
    end
    object btnAlterarQuantidade: TcxButton
      Left = 314
      Top = 138
      Width = 200
      Height = 36
      Caption = 'Alterar quantidade'
      TabOrder = 3
      OnClick = btnAlterarQuantidadeClick
    end
    object grdItens: TcxGrid
      Left = 24
      Top = 186
      Width = 640
      Height = 230
      TabOrder = 4
      object tvItens: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        OnFocusedRecordChanged = tvItensFocusedRecordChanged
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
        OptionsView.NoDataToDisplayInfoText = '<Adicione produtos ao pedido>'
        object colProduto: TcxGridColumn
          Caption = 'Produto'
          Width = 280
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
    object btnRemover: TcxButton
      Left = 24
      Top = 426
      Width = 140
      Height = 34
      Caption = 'Remover item'
      TabOrder = 5
      OnClick = btnRemoverClick
    end
    object lblTotal: TcxLabel
      Left = 404
      Top = 424
      AutoSize = False
      Caption = 'Total: R$ 0,00'
      Properties.Alignment.Horz = taRightJustify
      Properties.Alignment.Vert = taVCenter
      Transparent = True
      Height = 36
      Width = 260
    end
    object btnFechar: TcxButton
      Left = 24
      Top = 472
      Width = 110
      Height = 38
      Cancel = True
      Caption = 'Fechar'
      ModalResult = 2
      TabOrder = 7
    end
    object btnEnviar: TcxButton
      Left = 464
      Top = 472
      Width = 200
      Height = 38
      Caption = 'Enviar pedido'
      TabOrder = 6
      OnClick = btnEnviarClick
    end
  end
end
