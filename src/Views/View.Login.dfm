object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Vendas - Entrar'
  ClientHeight = 476
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object pnlCartao: TdxPanel
    Left = 20
    Top = 20
    Width = 380
    Height = 436
    Color = clWhite
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 28
      Top = 22
      Caption = 'Vendas'
      Transparent = True
    end
    object lblSubtitulo: TcxLabel
      Left = 28
      Top = 62
      Caption = 'Entre com o seu usu'#225'rio da API'
      Transparent = True
    end
    object lblPerfil: TcxLabel
      Left = 28
      Top = 100
      Caption = 'Servidor'
      Transparent = True
    end
    object cbPerfil: TcxComboBox
      Left = 28
      Top = 122
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 0
      Width = 324
    end
    object lblUsuario: TcxLabel
      Left = 28
      Top = 158
      Caption = 'Usu'#225'rio'
      Transparent = True
    end
    object edtUsuario: TcxTextEdit
      Left = 28
      Top = 180
      TabOrder = 1
      Width = 324
    end
    object lblSenha: TcxLabel
      Left = 28
      Top = 216
      Caption = 'Senha'
      Transparent = True
    end
    object edtSenha: TcxTextEdit
      Left = 28
      Top = 238
      Properties.EchoMode = eemPassword
      TabOrder = 2
      Width = 324
    end
    object chkLembrarUsuario: TcxCheckBox
      Left = 28
      Top = 276
      Caption = 'Lembrar usu'#225'rio'
      Properties.OnChange = chkLembrarUsuarioPropertiesChange
      TabOrder = 3
      Transparent = True
    end
    object chkLembrarSenha: TcxCheckBox
      Left = 190
      Top = 276
      Caption = 'Lembrar senha'
      TabOrder = 4
      Transparent = True
    end
    object lblErro: TcxLabel
      Left = 28
      Top = 308
      AutoSize = False
      Caption = 'mensagem de erro'
      Properties.WordWrap = True
      Transparent = True
      Height = 46
      Width = 324
    end
    object btnSair: TcxButton
      Left = 28
      Top = 366
      Width = 110
      Height = 38
      Cancel = True
      Caption = 'Sair'
      ModalResult = 2
      TabOrder = 6
    end
    object btnEntrar: TcxButton
      Left = 148
      Top = 366
      Width = 204
      Height = 38
      Caption = 'Entrar'
      Default = True
      TabOrder = 5
      OnClick = btnEntrarClick
    end
  end
end
