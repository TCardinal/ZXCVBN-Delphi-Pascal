program zxcvbn_test;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.Loggers.Text,
  DUnitX.TestFramework,
  uZxcvbnTest in 'uZxcvbnTest.pas',
  Zxcvbn in '..\src\Zxcvbn.pas',
  Zxcvbn.DateMatcher in '..\src\Zxcvbn.DateMatcher.pas',
  Zxcvbn.DefaultMatcherFactory in '..\src\Zxcvbn.DefaultMatcherFactory.pas',
  Zxcvbn.DictionaryMatcher in '..\src\Zxcvbn.DictionaryMatcher.pas',
  Zxcvbn.L33tMatcher in '..\src\Zxcvbn.L33tMatcher.pas',
  Zxcvbn.Matcher in '..\src\Zxcvbn.Matcher.pas',
  Zxcvbn.MatcherFactory in '..\src\Zxcvbn.MatcherFactory.pas',
  Zxcvbn.PasswordScoring in '..\src\Zxcvbn.PasswordScoring.pas',
  Zxcvbn.RegexMatcher in '..\src\Zxcvbn.RegexMatcher.pas',
  Zxcvbn.RepeatMatcher in '..\src\Zxcvbn.RepeatMatcher.pas',
  Zxcvbn.Result in '..\src\Zxcvbn.Result.pas',
  Zxcvbn.SequenceMatcher in '..\src\Zxcvbn.SequenceMatcher.pas',
  Zxcvbn.SpatialMatcher in '..\src\Zxcvbn.SpatialMatcher.pas',
  Zxcvbn.Translation in '..\src\Zxcvbn.Translation.pas',
  Zxcvbn.Utility in '..\src\Zxcvbn.Utility.pas';

{$R Dictionaries.res}

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    TDUnitX.CheckCommandLine;
    TDUnitX.Options.HideBanner := True;
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    logger := TDUnitXConsoleLogger.Create(False);
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.AddLogger(logger);

    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
