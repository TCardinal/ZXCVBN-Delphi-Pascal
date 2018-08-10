program ZxcvbnDemo;





{$R 'Dictionaries.res' '..\dict\Dictionaries.rc'}

uses
  Vcl.Forms,
  ZxcvbnDemoForm in 'ZxcvbnDemoForm.pas' {MainForm},
  Zxcvbn.DateMatcher in '..\src\Zxcvbn.DateMatcher.pas',
  Zxcvbn.DefaultMatcherFactory in '..\src\Zxcvbn.DefaultMatcherFactory.pas',
  Zxcvbn.DictionaryMatcher in '..\src\Zxcvbn.DictionaryMatcher.pas',
  Zxcvbn.L33tMatcher in '..\src\Zxcvbn.L33tMatcher.pas',
  Zxcvbn.Matcher in '..\src\Zxcvbn.Matcher.pas',
  Zxcvbn.MatcherFactory in '..\src\Zxcvbn.MatcherFactory.pas',
  Zxcvbn in '..\src\Zxcvbn.pas',
  Zxcvbn.PasswordScoring in '..\src\Zxcvbn.PasswordScoring.pas',
  Zxcvbn.RegexMatcher in '..\src\Zxcvbn.RegexMatcher.pas',
  Zxcvbn.RepeatMatcher in '..\src\Zxcvbn.RepeatMatcher.pas',
  Zxcvbn.Result in '..\src\Zxcvbn.Result.pas',
  Zxcvbn.SequenceMatcher in '..\src\Zxcvbn.SequenceMatcher.pas',
  Zxcvbn.SpatialMatcher in '..\src\Zxcvbn.SpatialMatcher.pas',
  Zxcvbn.Translation in '..\src\Zxcvbn.Translation.pas',
  Zxcvbn.Utility in '..\src\Zxcvbn.Utility.pas',
  uDebouncedEvent in 'uDebouncedEvent.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
