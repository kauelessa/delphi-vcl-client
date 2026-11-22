object frmProdutoEdicao: TfrmProdutoEdicao
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Produto'
  ClientHeight = 406
  ClientWidth = 460
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
    Width = 428
    Height = 374
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Produto'
      Transparent = True
    end
    object lblDescricao: TcxLabel
      Left = 24
      Top = 62
      Caption = 'Descri'#231#227'o'
      Transparent = True
    end
    object edtDescricao: TcxTextEdit
      Left = 24
      Top = 84
      Properties.MaxLength = 120
      TabOrder = 0
      Width = 380
    end
    object lblPreco: TcxLabel
      Left = 24
      Top = 120
      Caption = 'Pre'#231'o'
      Transparent = True
    end
    object edtPreco: TcxCurrencyEdit
      Left = 24
      Top = 142
      Properties.DisplayFormat = 'R$ ,0.00'
      TabOrder = 1
      Width = 160
    end
    object lblEstoque: TcxLabel
      Left = 204
      Top = 120
      Caption = 'Estoque'
      Transparent = True
    end
    object edtEstoque: TcxSpinEdit
      Left = 204
      Top = 142
      Properties.MaxValue = 999999.000000000000000000
      TabOrder = 2
      Width = 120
    end
    object lblCodigoBarras: TcxLabel
      Left = 24
      Top = 178
      Caption = 'C'#243'digo de barras'
      Transparent = True
    end
    object edtCodigoBarras: TcxTextEdit
      Left = 24
      Top = 200
      Properties.MaxLength = 14
      TabOrder = 3
      Width = 200
    end
    object lblDicaEstoque: TcxLabel
      Left = 24
      Top = 236
      AutoSize = False
      Caption = 'O estoque informado aqui substitui o atual. Pedidos baixam e cancelamentos devolvem automaticamente.'
      Properties.WordWrap = True
      Transparent = True
      Height = 40
      Width = 380
    end
    object btnCancelar: TcxButton
      Left = 24
      Top = 316
      Width = 110
      Height = 38
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 5
    end
    object btnSalvar: TcxButton
      Left = 244
      Top = 316
      Width = 160
      Height = 38
      Caption = 'Salvar'
      Default = True
      TabOrder = 4
      OnClick = btnSalvarClick
    end
  end
end
