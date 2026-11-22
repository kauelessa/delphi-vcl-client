object fraListaBase: TfraListaBase
  Left = 0
  Top = 0
  Width = 900
  Height = 480
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object pnlFerramentas: TdxPanel
    AlignWithMargins = True
    Left = 16
    Top = 12
    Width = 868
    Height = 44
    Margins.Left = 16
    Margins.Top = 12
    Margins.Right = 16
    Margins.Bottom = 8
    Align = alTop
    Color = clWhite
    TabOrder = 0
    DesignSize = (
      868
      44)
    object edtBusca: TcxTextEdit
      Left = 0
      Top = 8
      Properties.OnChange = edtBuscaPropertiesChange
      TabOrder = 0
      TextHint = 'Buscar...'
      OnKeyDown = edtBuscaKeyDown
      Width = 340
    end
    object btnInativar: TcxButton
      Left = 522
      Top = 4
      Width = 110
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Inativar'
      TabOrder = 1
      OnClick = btnInativarClick
    end
    object btnEditar: TcxButton
      Left = 640
      Top = 4
      Width = 110
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Editar'
      TabOrder = 2
      OnClick = btnEditarClick
    end
    object btnNovo: TcxButton
      Left = 758
      Top = 4
      Width = 110
      Height = 36
      Anchors = [akTop, akRight]
      Caption = '+ Novo'
      TabOrder = 3
      OnClick = btnNovoClick
    end
  end
  object grdLista: TcxGrid
    AlignWithMargins = True
    Left = 16
    Top = 64
    Width = 868
    Height = 360
    Margins.Left = 16
    Margins.Top = 0
    Margins.Right = 16
    Margins.Bottom = 0
    Align = alClient
    TabOrder = 1
    object tvLista: TcxGridTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      OnDblClick = tvListaDblClick
      OnFocusedRecordChanged = tvListaFocusedRecordChanged
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
      OptionsView.NoDataToDisplayInfoText = '<Nenhum registro>'
    end
    object lvLista: TcxGridLevel
      GridView = tvLista
    end
  end
  object pnlRodape: TdxPanel
    AlignWithMargins = True
    Left = 16
    Top = 432
    Width = 868
    Height = 40
    Margins.Left = 16
    Margins.Top = 8
    Margins.Right = 16
    Margins.Bottom = 8
    Align = alBottom
    Color = clWhite
    TabOrder = 2
    DesignSize = (
      868
      40)
    object btnAnterior: TcxButton
      Left = 0
      Top = 3
      Width = 110
      Height = 34
      Caption = '< Anterior'
      TabOrder = 0
      OnClick = btnAnteriorClick
    end
    object lblPagina: TcxLabel
      Left = 120
      Top = 10
      Caption = 'P'#225'gina 1 de 1'
      Transparent = True
    end
    object btnProxima: TcxButton
      Left = 230
      Top = 3
      Width = 110
      Height = 34
      Caption = 'Pr'#243'xima >'
      TabOrder = 1
      OnClick = btnProximaClick
    end
    object lblTotal: TcxLabel
      Left = 356
      Top = 10
      Caption = '0 registros'
      Transparent = True
    end
    object lblCarregando: TcxLabel
      Left = 480
      Top = 10
      Caption = 'Carregando...'
      Transparent = True
    end
    object lblPorPagina: TcxLabel
      Left = 676
      Top = 10
      Anchors = [akTop, akRight]
      Caption = 'Itens por p'#225'gina'
      Transparent = True
    end
    object cbPorPagina: TcxComboBox
      Left = 788
      Top = 6
      Anchors = [akTop, akRight]
      Properties.DropDownListStyle = lsFixedList
      Properties.Items.Strings = (
        '20'
        '50'
        '100')
      Properties.OnChange = cbPorPaginaPropertiesChange
      TabOrder = 2
      Width = 80
    end
  end
  object tmrBusca: TTimer
    Enabled = False
    Interval = 400
    OnTimer = tmrBuscaTimer
    Left = 840
    Top = 120
  end
end
