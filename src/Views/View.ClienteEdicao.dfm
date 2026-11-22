object frmClienteEdicao: TfrmClienteEdicao
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Cliente'
  ClientHeight = 392
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
    Height = 360
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Cliente'
      Transparent = True
    end
    object lblNome: TcxLabel
      Left = 24
      Top = 62
      Caption = 'Nome'
      Transparent = True
    end
    object edtNome: TcxTextEdit
      Left = 24
      Top = 84
      Properties.MaxLength = 100
      TabOrder = 0
      Width = 380
    end
    object lblDocumento: TcxLabel
      Left = 24
      Top = 120
      Caption = 'CPF ou CNPJ'
      Transparent = True
    end
    object edtDocumento: TcxTextEdit
      Left = 24
      Top = 142
      Properties.MaxLength = 18
      TabOrder = 1
      Width = 220
    end
    object lblEmail: TcxLabel
      Left = 24
      Top = 178
      Caption = 'E-mail'
      Transparent = True
    end
    object edtEmail: TcxTextEdit
      Left = 24
      Top = 200
      Properties.MaxLength = 120
      TabOrder = 2
      Width = 380
    end
    object lblTelefone: TcxLabel
      Left = 24
      Top = 236
      Caption = 'Telefone'
      Transparent = True
    end
    object edtTelefone: TcxTextEdit
      Left = 24
      Top = 258
      Properties.MaxLength = 20
      TabOrder = 3
      Width = 220
    end
    object btnCancelar: TcxButton
      Left = 24
      Top = 302
      Width = 110
      Height = 38
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 5
    end
    object btnSalvar: TcxButton
      Left = 244
      Top = 302
      Width = 160
      Height = 38
      Caption = 'Salvar'
      Default = True
      TabOrder = 4
      OnClick = btnSalvarClick
    end
  end
end
