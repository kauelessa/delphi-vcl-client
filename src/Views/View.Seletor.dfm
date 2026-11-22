object frmSeletor: TfrmSeletor
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Escolher'
  ClientHeight = 480
  ClientWidth = 560
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
    Width = 528
    Height = 448
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Escolher'
      Transparent = True
    end
    object edtBusca: TcxTextEdit
      Left = 24
      Top = 56
      Properties.OnChange = edtBuscaPropertiesChange
      TabOrder = 0
      TextHint = 'Buscar...'
      OnKeyDown = edtBuscaKeyDown
      Width = 480
    end
    object grdItens: TcxGrid
      Left = 24
      Top = 92
      Width = 480
      Height = 270
      TabOrder = 1
      object tvItens: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        OnDblClick = tvItensDblClick
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
        OptionsView.NoDataToDisplayInfoText = '<Nada encontrado>'
      end
      object lvItens: TcxGridLevel
        GridView = tvItens
      end
    end
    object lblInfo: TcxLabel
      Left = 24
      Top = 368
      Caption = 'informa'#231#245'es'
      Transparent = True
    end
    object btnCancelar: TcxButton
      Left = 24
      Top = 392
      Width = 110
      Height = 38
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 3
    end
    object btnEscolher: TcxButton
      Left = 344
      Top = 392
      Width = 160
      Height = 38
      Caption = 'Escolher'
      TabOrder = 2
      OnClick = btnEscolherClick
    end
  end
  object tmrBusca: TTimer
    Enabled = False
    Interval = 400
    OnTimer = tmrBuscaTimer
    Left = 488
    Top = 24
  end
end
