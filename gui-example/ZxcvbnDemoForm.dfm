object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'zxcvbn-pascal Demo'
  ClientHeight = 266
  ClientWidth = 379
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object labStrength: TLabel
    Left = 16
    Top = 59
    Width = 94
    Height = 13
    Caption = 'Password strength:'
  end
  object labWarnings: TLabel
    Left = 16
    Top = 92
    Width = 345
    Height = 161
    AutoSize = False
    WordWrap = True
  end
  object pbStrength: TPaintBox
    Left = 116
    Top = 62
    Width = 130
    Height = 8
    OnPaint = pbStrengthPaint
  end
  object edPassword: TLabeledEdit
    Left = 16
    Top = 32
    Width = 345
    Height = 21
    EditLabel.Width = 50
    EditLabel.Height = 13
    EditLabel.Caption = 'Password:'
    TabOrder = 0
  end
end
