object frmRelogin: TfrmRelogin
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Sess'#227'o expirada'
  ClientHeight = 250
  ClientWidth = 440
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 17
  object pnlCartao: TdxPanel
    Left = 16
    Top = 16
    Width = 408
    Height = 218
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Entre de novo'
      Transparent = True
    end
    object lblMensagem: TcxLabel
      Left = 24
      Top = 50
      AutoSize = False
      Caption = 'Sua sess'#227'o expirou.'
      Properties.WordWrap = True
      Transparent = True
      Height = 44
      Width = 360
    end
    object edtSenha: TcxTextEdit
      Left = 24
      Top = 104
      Properties.EchoMode = eemPassword
      TabOrder = 0
      TextHint = 'Senha'
      Width = 360
    end
    object btnCancelar: TcxButton
      Left = 24
      Top = 156
      Width = 110
      Height = 38
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 2
    end
    object btnContinuar: TcxButton
      Left = 144
      Top = 156
      Width = 240
      Height = 38
      Caption = 'Continuar'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
end
