object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'zxcvbn-pascal Demo'
  ClientHeight = 358
  ClientWidth = 444
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    444
    358)
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
    Width = 410
    Height = 243
    Anchors = [akLeft, akTop, akRight, akBottom]
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    WordWrap = True
    ExplicitWidth = 345
    ExplicitHeight = 245
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
