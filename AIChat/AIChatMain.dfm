object frmAIChat: TfrmAIChat
  Left = 200
  Top = 100
  Width = 640
  Height = 520
  Caption = 'AI Chat Assistant'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
  end
  object pnlToolbar: TPanel
    Left = 0
    Top = 48
    Width = 624
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 468
    Width = 624
    Height = 19
    Panels = <
      item
        Text = 'Ready'
        Width = 200
      end
      item
        Text = 'Messages: 0'
        Width = 150
      end>
  end
  object pnlInput: TPanel
    Left = 0
    Top = 408
    Width = 624
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object BevelTop: TBevel
      Left = 0
      Top = 0
      Width = 624
      Height = 3
      Align = alTop
      Shape = bsTopLine
    end
    object lblInput: TLabel
      Left = 8
      Top = 6
      Width = 80
      Height = 13
      Caption = 'Your message:'
    end
    object memInput: TMemo
      Left = 8
      Top = 22
      Width = 529
      Height = 32
      TabOrder = 0
      OnKeyDown = memInputKeyDown
    end
    object btnSend: TButton
      Left = 544
      Top = 22
      Width = 75
      Height = 32
      Caption = 'Send'
      TabOrder = 1
      OnClick = btnSendClick
    end
  end
  object pnlChatHost: TPanel
    Left = 0
    Top = 78
    Width = 624
    Height = 330
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
  end
  object MainMenu: TMainMenu
    Left = 300
    Top = 200
    object File1: TMenuItem
      Caption = '&File'
      object ClearChat1: TMenuItem
        Caption = '&Clear Chat'
        OnClick = Clear1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'E&xit'
        OnClick = Exit1Click
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      object About1: TMenuItem
        Caption = '&About...'
        OnClick = About1Click
      end
    end
  end
end
