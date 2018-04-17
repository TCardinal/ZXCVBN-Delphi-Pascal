unit uZxcvbnTest;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TZxcvbnTest = class(TObject)

  type
    TTestPassword = record
      Password: String;
      ExpectedEntropy: Double;
      ExpectedWarning: String;
      ExpectedSuggestions: array[0..2] of String;
    end;

  const
    testPasswords: array[0..34] of TTestPassword = (
      (Password: 'zxcvbn'; ExpectedEntropy: 6.044;
        ExpectedWarning: 'This is a top-100 common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'qwER43@!'; ExpectedEntropy: 26.865;
        ExpectedWarning: 'Short keyboard patterns are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Use a longer keyboard pattern with more turns','' )),
      (Password: 'Tr0ub4dour&3'; ExpectedEntropy: 32.56;
        ExpectedWarning: '';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Capitalization doesn''t help very much','Predictable substitutions like ''@'' instead of ''a'' don''t help very much' )),
      (Password: 'correcthorsebatterystaple'; ExpectedEntropy: 46.904;
        ExpectedWarning: '';
        ExpectedSuggestions: ( '', '','' )),
      (Password: 'coRrecth0rseba++ery9.23.2007staple$'; ExpectedEntropy: 65.649;
        ExpectedWarning: '';
        ExpectedSuggestions: ( '', '','' )),
      (Password: 'D0g..................'; ExpectedEntropy: 22.396;
        ExpectedWarning: 'Repeats like "aaa" are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Avoid repeated words and characters','' )),
      (Password: 'abcdefghijk987654321'; ExpectedEntropy: 11.951;
        ExpectedWarning: 'Sequences like abc or 6543 are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Avoid sequences','' )),
      (Password: 'neverforget13/3/1997'; ExpectedEntropy: 34.380;
        ExpectedWarning: '';
        ExpectedSuggestions: ( '', '','' )),
      (Password: '1qaz2wsx3edc'; ExpectedEntropy: 10.421;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'temppass22'; ExpectedEntropy: 16.746;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'briansmith'; ExpectedEntropy: 4.322;
        ExpectedWarning: 'Common names and surnames are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      //original library gives 4/4 score here while this library gives 0
      (Password: 'briansmith4mayor'; ExpectedEntropy: 19.722;
        ExpectedWarning: 'Common names and surnames are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      //gives wrong advice since this library return 'password' as match instead of the complete 'password1' 'This is a very common password'
      (Password: 'password1'; ExpectedEntropy: 6.17;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'viking'; ExpectedEntropy: 8.243;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'thx1138'; ExpectedEntropy: 7.994;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      //original library return '' which is less good in that case
      (Password: 'ScoRpi0ns'; ExpectedEntropy: 20.49;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Predictable substitutions like ''@'' instead of ''a'' don''t help very much','' )),
      //original library gives 3/4 score here while this library gives 0
      (Password: 'do you know'; ExpectedEntropy: 38.518;
        ExpectedWarning: '';
        ExpectedSuggestions: ( '', '','' )),
      (Password: 'ryanhunter2000'; ExpectedEntropy: 17.795;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      //original library gives 3/4 score here while this library gives 1
      (Password: 'rianhunter2000'; ExpectedEntropy: 25.389;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      //original library gives 3/4 score here while this library gives 2
      (Password: 'asdfghju7654rewq'; ExpectedEntropy: 29.782;
        ExpectedWarning: 'Short keyboard patterns are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Use a longer keyboard pattern with more turns','' )),
      (Password: 'AOEUIDHG&*()LS_'; ExpectedEntropy: 36.172;
        ExpectedWarning: '';
        ExpectedSuggestions: ( '', '','' )),
      (Password: '12345678'; ExpectedEntropy: 1.585;
        ExpectedWarning: 'This is a top-10 common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'All-uppercase is almost as easy to guess as all-lowercase','' )),
      (Password: 'defghi6789'; ExpectedEntropy: 12.607;
        ExpectedWarning: 'Sequences like abc or 6543 are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Avoid sequences','' )),
      (Password: 'rosebud'; ExpectedEntropy: 8.409;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'Rosebud'; ExpectedEntropy: 9.409;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Capitalization doesn''t help very much','' )),
      (Password: 'ROSEBUD'; ExpectedEntropy: 9.409;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'All-uppercase is almost as easy to guess as all-lowercase','' )),
      (Password: 'rosebuD'; ExpectedEntropy: 9.409;
        ExpectedWarning: 'This is a very common password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', '','' )),
      (Password: 'ros3bud99'; ExpectedEntropy: 13.731;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Predictable substitutions like ''@'' instead of ''a'' don''t help very much','' )),
      (Password: 'r0s3bud99'; ExpectedEntropy: 15.053;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Predictable substitutions like ''@'' instead of ''a'' don''t help very much','' )),
      (Password: 'R0$38uD99'; ExpectedEntropy: 18.538;
        ExpectedWarning: 'This is similar to a commonly used password';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Predictable substitutions like ''@'' instead of ''a'' don''t help very much','' )),
      //original library gives 4/4 score here while this library gives 1
      (Password: 'verlineVANDERMARK'; ExpectedEntropy: 26.642;
        ExpectedWarning: 'Common names and surnames are easy to guess';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'All-uppercase is almost as easy to guess as all-lowercase','' )),
      (Password: 'krekrekrekrekre'; ExpectedEntropy: 7.022;
        ExpectedWarning: 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"';
        ExpectedSuggestions: ( 'Add another word or two. Uncommon words are better.', 'Avoid repeated words and characters','' )),
      (Password: 'eheuczkqyq'; ExpectedEntropy: 41.304;
        ExpectedWarning: '';
        ExpectedSuggestions: ('', '', '')),
      (Password: 'rWibMFACxAUGZmxhVncy'; ExpectedEntropy: 107.977;
        ExpectedWarning: '';
        ExpectedSuggestions: ('', '', '')),
      (Password: 'Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w'; ExpectedEntropy: 160.607;
        ExpectedWarning: '';
        ExpectedSuggestions: ('', '', ''))
    );

  private
    procedure O(AMessage: String);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure RunAllTestPasswords;

    [Test]
    [TestCase('asdf', 'asdf,26')]
    [TestCase('ASDF', 'ASDF,26')]
    [TestCase('aSDf', 'aSDf,52')]
    [TestCase('124890', '124890,10')]
    [TestCase('aS159Df', 'aS159Df,62')]
    [TestCase('!@<%:{$:#<@}{+&)(*%', '!@<%:{$:#<@}{+&)(*%,33')]
    [TestCase('©', '©,100')]
    [TestCase('ThisIs@T3stP4ssw0rd!', 'ThisIs@T3stP4ssw0rd!,95')]
    procedure BruteForceCardinalityTest(APassword: String; ACardinality: Integer);

    [Test]
    procedure TimeDisplayStrings;

    [Test]
    procedure TimeDisplayStringsGerman;

    [Test]
    procedure RepeatMatcher;

    [Test]
    procedure SequenceMatcher;

    [Test]
    procedure DigitsRegexMatcher;

    [Test]
    [TestCase('1297',      '1297,1')]
    [TestCase('98123',     '98123,1')]
    [TestCase('221099',    '221099,1')]
    [TestCase('352002',    '352002,1')]
    [TestCase('2011157',   '2011157,1')]
    [TestCase('11222015',  '11222015,1')]
    [TestCase('2013/06/1', '2013/06/1,1')]
    [TestCase('13-05-08',  '13-05-08,1')]
    [TestCase('17 8 1992', '17 8 1992,1')]
    [TestCase('10.16.16',  '10.16.16,1')]
    [TestCase('11222015',  '11222015,1')]
    procedure DateMatcher(APassword: String; AExpectedMatchesCount: Integer);

    [Test]
    procedure SpatialMatcher;

    [Test]
    procedure BinomialTest;

    [Test]
    procedure DictionaryTest;

    [Test]
    [TestCase('password', 'password')]
    [TestCase('p@ssword', 'p@ssword')]
    [TestCase('p1ssword', 'p1ssword')]
    [TestCase('p1!ssword', 'p1!ssword')]
    [TestCase('p1!ssw0rd', 'p1!ssw0rd')]
    [TestCase('p1!ssw0rd|', 'p1!ssw0rd|')]
    procedure L33tTest(APassword: String);

    [Test]
    procedure EmptyPassword;

    [Test]
    procedure SinglePasswordTest;

    [Test]
    procedure WarningTest;

    [Test]
    procedure SuggestionsTest;
  end;

implementation
uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  Zxcvbn,
  Zxcvbn.Matcher,
  Zxcvbn.PasswordScoring,
  Zxcvbn.Utility,
  Zxcvbn.Translation,
  Zxcvbn.DateMatcher,
  Zxcvbn.DictionaryMatcher,
  Zxcvbn.L33tMatcher,
  Zxcvbn.RegexMatcher,
  Zxcvbn.RepeatMatcher,
  Zxcvbn.SequenceMatcher,
  Zxcvbn.SpatialMatcher,
  Zxcvbn.Result;

procedure TZxcvbnTest.Setup;
begin
end;

procedure TZxcvbnTest.TearDown;
begin
end;

procedure TZxcvbnTest.O(AMessage: String);
begin
  Log(TLogLevel.Information, AMessage);
end;

procedure TZxcvbnTest.RunAllTestPasswords;
var
  zx: TZxcvbn;
  i: Integer;
  password: String;
  result: TZxcvbnResult;
  match: TZxcvbnMatch;
  dm: TZxcvbnDictionaryMatch;
  lm: TZxcvbnL33tMatch;
  spm: TZxcvbnSpatialMatch;
  rm: TZxcvbnRepeatMatch;
  sm: TZxcvbnSequenceMatch;
  dam: TZxcvbnDateMatch;
begin
  zx := TZxcvbn.Create;
  try
    for i := Low(testPasswords) to High(testPasswords) do
    begin
      password := testPasswords[i].Password;
      result := zx.EvaluatePassword(password);
      try
        O('');
        O('Password:        '+ result.Password);
        O('Entropy:         '+ result.Entropy.ToString);
        O('Crack Time (s):  '+ result.CrackTime.ToString);
        O('Crack Time (d):  '+ result.CrackTimeDisplay);
        O('Score (0 to 4):  '+ result.Score.ToString);
        O('Calc time (ms):  '+ result.CalcTime.ToString);
        O('--------------------');

        for match in result.MatchSequence do
        begin
          if (match <> result.MatchSequence.First) then O('+++++++++++++++++');

          O(match.Token);
          O('Pattern:      '+ match.Pattern);
          O('Entropy:      '+ match.Entropy.ToString);

          if (match is TZxcvbnDictionaryMatch) then
          begin
            dm := match as TZxcvbnDictionaryMatch;
            O('Dict. Name:   '+ dm.DictionaryName);
            O('Rank:         '+ dm.Rank.ToString);
            O('Base Entropy: '+ dm.BaseEntropy.ToString);
            O('Upper Entpy:  '+ dm.UppercaseEntropy.ToString);
          end;

          if (match is TZxcvbnL33tMatch) then
          begin
            lm := match as TZxcvbnL33tMatch;
            O('L33t Entpy:   '+ lm.L33tEntropy.ToString);
            O('Unleet:       '+ lm.MatchedWord);
          end;

          if (match is TZxcvbnSpatialMatch) then
          begin
            spm := match as TZxcvbnSpatialMatch;
            O('Graph:        '+ spm.Graph);
            O('Turns:        '+ spm.Turns.ToString);
            O('Shifted Keys: '+ spm.ShiftedCount.ToString);
          end;

          if (match is TZxcvbnRepeatMatch) then
          begin
            rm := match as TZxcvbnRepeatMatch;
            O('Repeat count:  '+ rm.RepeatCount.ToString);
            O('Base token:  '+ rm.BaseToken);
          end;

          if (match is TZxcvbnSequenceMatch) then
          begin
            sm := match as TZxcvbnSequenceMatch;
            O('Seq. name:    '+ sm.SequenceName);
            O('Seq. size:    '+ sm.SequenceSize.ToString);
            O('Ascending:    '+ sm.Ascending.ToString);
          end;

          if (match is TZxcvbnDateMatch) then
          begin
            dam := match as TZxcvbnDateMatch;
            O('Day:          '+ dam.Day.ToString);
            O('Month:        '+ dam.Month.ToString);
            O('Year:         '+ dam.Year.ToString);
            O('Separator:    '+ dam.Separator);
          end;
        end;

        O('');
        O('=========================================');
      finally
        result.Free;
      end;

      Assert.AreEqual(testPasswords[i].ExpectedEntropy, result.Entropy, 0.001);
    end;
  finally
    zx.Free;
  end;
end;

procedure TZxcvbnTest.BruteForceCardinalityTest(APassword: String; ACardinality: Integer);
begin
  Assert.AreEqual(ACardinality, Zxcvbn.PasswordScoring.PasswordCardinality(APassword));
end;

procedure TZxcvbnTest.TimeDisplayStrings;
begin
  // Note that the time strings should be + 1
  Assert.AreEqual('11 minutes', Zxcvbn.Utility.DisplayTime(60 * 10, TZxcvbnTranslation.ztEnglish));
  Assert.AreEqual('2 days', Zxcvbn.Utility.DisplayTime(60 * 60 * 24, TZxcvbnTranslation.ztEnglish));
  Assert.AreEqual('17 years', Zxcvbn.Utility.DisplayTime(60 * 60 * 24 * 365 * 15.4, TZxcvbnTranslation.ztEnglish));
end;

procedure TZxcvbnTest.TimeDisplayStringsGerman;
begin
  // Note that the time strings should be + 1
  Assert.AreEqual('11 Minuten', Zxcvbn.Utility.DisplayTime(60 * 10, TZxcvbnTranslation.ztGerman));
  Assert.AreEqual('2 Tage', Zxcvbn.Utility.DisplayTime(60 * 60 * 24, TZxcvbnTranslation.ztGerman));
  Assert.AreEqual('17 Jahre', Zxcvbn.Utility.DisplayTime(60 * 60 * 24 * 365 * 15.4, TZxcvbnTranslation.ztGerman));
end;

procedure TZxcvbnTest.RepeatMatcher;
var
  rm: Zxcvbn.RepeatMatcher.TZxcvbnRepeatMatcher;
  res: TList<TZxcvbnMatch>;
  m1, m2: TZxcvbnRepeatMatch;
  match: TZxcvbnMatch;
begin
  rm := TZxcvbnRepeatMatcher.Create;
  try
    res := TList<TZxcvbnMatch>.Create;
    try
      rm.MatchPassword('aaasdffff', res);
      Assert.AreEqual(2, res.Count);

      Assert.IsTrue(res.Items[0] is TZxcvbnRepeatMatch);
      m1 := TZxcvbnRepeatMatch(res.Items[0]);
      Assert.AreEqual(0, m1.i);
      Assert.AreEqual(2, m1.j);
      Assert.AreEqual('aaa', m1.Token);

      Assert.IsTrue(res.Items[1] is TZxcvbnRepeatMatch);
      m2 := TZxcvbnRepeatMatch(res.Items[1]);
      Assert.AreEqual(5, m2.i);
      Assert.AreEqual(8, m2.j);
      Assert.AreEqual('ffff', m2.Token);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      rm.MatchPassword('asdf', res);
      Assert.AreEqual(0, res.Count);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;
  finally
    rm.Free;
  end;
end;

procedure TZxcvbnTest.SequenceMatcher;
var
  seq: Zxcvbn.SequenceMatcher.TZxcvbnSequenceMatcher;
  res: TList<TZxcvbnMatch>;
  m1, m2: TZxcvbnSequenceMatch;
  match: TZxcvbnMatch;
begin
  seq := TZxcvbnSequenceMatcher.Create;
  try
    res := TList<TZxcvbnMatch>.Create;
    try
      seq.MatchPassword('abcd', res);
      Assert.AreEqual(1, res.Count);
      Assert.IsTrue(res.First is TZxcvbnSequenceMatch);
      m1 := TZxcvbnSequenceMatch(res.First);
      Assert.AreEqual(0, m1.i);
      Assert.AreEqual(3, m1.j);
      Assert.AreEqual('abcd', m1.Token);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      seq.MatchPassword('asdfabcdhujzyxwhgjj', res);
      Assert.AreEqual(2, res.Count);

      Assert.IsTrue(res.Items[0] is TZxcvbnSequenceMatch);
      m1 := TZxcvbnSequenceMatch(res.Items[0]);
      Assert.AreEqual(4, m1.i);
      Assert.AreEqual(7, m1.j);
      Assert.AreEqual('abcd', m1.Token);

      Assert.IsTrue(res.Items[1] is TZxcvbnSequenceMatch);
      m2 := TZxcvbnSequenceMatch(res.Items[1]);
      Assert.AreEqual(11, m2.i);
      Assert.AreEqual(14, m2.j);
      Assert.AreEqual('zyxw', m2.Token);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      seq.MatchPassword('dfsjkhfjksdh', res);
      Assert.AreEqual(0, res.Count);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;
  finally
    seq.Free;
  end;
end;

procedure TZxcvbnTest.DigitsRegexMatcher;
var
  re: Zxcvbn.RegexMatcher.TZxcvbnRegexMatcher;
  res: TList<TZxcvbnMatch>;
  m1, m3: TZxcvbnMatch;
  match: TZxcvbnMatch;
begin
  re := TZxcvbnRegexMatcher.Create('\d{3,}', 10);
  try
    res := TList<TZxcvbnMatch>.Create;
    try
      re.MatchPassword('abc123def', res);
      Assert.AreEqual(1, res.Count);
      m1 := TZxcvbnSequenceMatch(res.First);
      Assert.AreEqual(3, m1.i);
      Assert.AreEqual(5, m1.j);
      Assert.AreEqual('123', m1.Token);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      re.MatchPassword('123456789a12345b1234567', res);
      Assert.AreEqual(3, res.Count);
      m3 := res.Items[2];
      Assert.AreEqual('1234567', m3.Token);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      re.MatchPassword('12', res);
      Assert.AreEqual(0, res.Count);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      re.MatchPassword('dfsdfdfhgjkdfngjl', res);
      Assert.AreEqual(0, res.Count);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;
  finally
    re.Free;
  end;
end;

procedure TZxcvbnTest.DateMatcher(APassword: String; AExpectedMatchesCount: Integer);
var
  dm: Zxcvbn.DateMatcher.TZxcvbnDateMatcher;
  res: TList<TZxcvbnMatch>;
  match: TZxcvbnMatch;
begin
  dm := TZxcvbnDateMatcher.Create;
  try
    res := TList<TZxcvbnMatch>.Create;
    try
      dm.MatchPassword(APassword, res);
      Assert.AreEqual(AExpectedMatchesCount, res.Count);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;
  finally
    dm.Free;
  end;
end;

procedure TZxcvbnTest.SpatialMatcher;
var
  sm: Zxcvbn.SpatialMatcher.TZxcvbnSpatialMatcher;
  res: TList<TZxcvbnMatch>;
  m1: TZxcvbnSpatialMatch;
  match: TZxcvbnMatch;
begin
  sm := TZxcvbnSpatialMatcher.Create;
  try
    res := TList<TZxcvbnMatch>.Create;
    try
      sm.MatchPassword('qwert', res);
      Assert.AreEqual(1, res.Count);
      Assert.IsTrue(res.First is TZxcvbnSpatialMatch);
      m1 := TZxcvbnSpatialMatch(res.First);
      Assert.AreEqual('qwert', m1.Token);
      Assert.AreEqual(0, m1.i);
      Assert.AreEqual(4, m1.j);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      sm.MatchPassword('plko14569852pyfdb', res);
      Assert.AreEqual(6, res.Count); // Multiple matches from different keyboard types
    finally
      for match in res do
        match.Free;
      res.Free;
    end;
  finally
    sm.Free;
  end;
end;

procedure TZxcvbnTest.BinomialTest;
begin
  Assert.AreEqual(1, Zxcvbn.PasswordScoring.Binomial(0, 0));
  Assert.AreEqual(1, Zxcvbn.PasswordScoring.Binomial(1, 0));
  Assert.AreEqual(0, Zxcvbn.PasswordScoring.Binomial(0, 1));
  Assert.AreEqual(1, Zxcvbn.PasswordScoring.Binomial(1, 1));
  Assert.AreEqual(56, Zxcvbn.PasswordScoring.Binomial(8, 3));
  Assert.AreEqual(2598960, Zxcvbn.PasswordScoring.Binomial(52, 5));
end;

procedure TZxcvbnTest.DictionaryTest;
var
  dm: IZxcvbnMatcher;
  res: TList<TZxcvbnMatch>;
  leet: TZxcvbnL33tMatcher;
  match: TZxcvbnMatch;
begin
  dm := TZxcvbnDictionaryMatcher.Create('test', 'test_dictionary.txt');

  res := TList<TZxcvbnMatch>.Create;
  try
    dm.MatchPassword('NotInDictionary', res);
    Assert.AreEqual(0, res.Count, 'NotInDictionary');
  finally
    for match in res do
      match.Free;
    res.Free;
  end;

  res := TList<TZxcvbnMatch>.Create;
  try
    dm.MatchPassword('choreography', res);
    Assert.AreEqual(1, res.Count, 'choreography');
  finally
    for match in res do
      match.Free;
    res.Free;
  end;

  res := TList<TZxcvbnMatch>.Create;
  try
    dm.MatchPassword('ChOrEograPHy', res);
    Assert.AreEqual(1, res.Count, 'ChOrEograPHy');
  finally
    for match in res do
      match.Free;
    res.Free;
  end;

  leet := TZxcvbnL33tMatcher.Create(dm);
  try
    res := TList<TZxcvbnMatch>.Create;
    try
      leet.MatchPassword('3mu', res);
      Assert.AreEqual(1, res.Count, '3mu');
      leet.Free;
    finally
      for match in res do
        match.Free;
      res.Free;
    end;

    res := TList<TZxcvbnMatch>.Create;
    try
      leet := TZxcvbnL33tMatcher.Create(dm);
      leet.MatchPassword('3mupr4nce|egume', res);
    finally
      for match in res do
        match.Free;
      res.Free;
    end;
  finally
    leet.Free;
  end;
end;

procedure TZxcvbnTest.L33tTest(APassword: String);
var
  l: TZxcvbnL33tMatcher;
  sl: TStringList;
  res: TList<TZxcvbnMatch>;
  match: TZxcvbnMatch;
begin
  sl := TStringList.Create;
  try
    sl.Add('password');
    l := TZxcvbnL33tMatcher.Create(TZxcvbnDictionaryMatcher.Create('test', sl));
    try
      res := TList<TZxcvbnMatch>.Create;
      try
        l.MatchPassword(APassword, res);
      finally
        for match in res do
          match.Free;
        res.Free;
      end;
    finally
      l.Free;
    end;
  finally
    sl.Free;
  end;
end;

procedure TZxcvbnTest.EmptyPassword;
var
  res: TZxcvbnResult;
begin
  res := TZxcvbn.MatchPassword('');
  Assert.AreEqual(0, res.Entropy, 0);
  res.Free;
end;

procedure TZxcvbnTest.SinglePasswordTest;
var
  res: TZxcvbnResult;
begin
  res := TZxcvbn.MatchPassword('||ke');
  res.Free;
end;

procedure TZxcvbnTest.WarningTest;
var
  zx: TZxcvbn;
  i: Integer;
  password: String;
  result: TZxcvbnResult;
  expectedWarning: String;
  realWarning: String;
begin
  zx := TZxcvbn.Create;
  try
    for i := Low(testPasswords) to High(testPasswords) do
    begin
      password := testPasswords[i].Password;
      expectedWarning := testPasswords[i].ExpectedWarning;

      result := zx.EvaluatePassword(password);
      try
        realWarning := Zxcvbn.Utility.GetWarning(result.Warning);
        O('');
        O('Password:         '+ result.Password);
        O('Warning:          '+ realWarning);
        O('Expected Warning: '+ expectedWarning);

        O('');
        O('=========================================');

        Assert.AreEqual(expectedWarning, realWarning, ' for password: ' + testPasswords[i].Password);
      finally
        result.Free;
      end;
    end;
  finally
    zx.Free;
  end;
end;

procedure TZxcvbnTest.SuggestionsTest;
var
  zx: TZxcvbn;
  i, j: Integer;
  password: String;
  result: TZxcvbnResult;
  expectedSuggestion: String;
  realSuggestion: String;
  suggestion: TZxcvbnSuggestion;
begin
  zx := TZxcvbn.Create;
  try
    for i := Low(testPasswords) to High(testPasswords) do
    begin
      password := testPasswords[i].Password;

      result := zx.EvaluatePassword(password);
      try
        O('');
        O('Password:         '+ result.Password);
        j := 0;
        for suggestion in result.Suggestions do
        begin
          realSuggestion := Zxcvbn.Utility.GetSuggestion(suggestion);
          if (j > High(testPasswords[i].ExpectedSuggestions)) then
            Assert.Fail('Too much suggestions');
          expectedSuggestion := testPasswords[i].ExpectedSuggestions[j];
          O('Suggestion:          '+ realSuggestion);
          O('Expected Suggestion: '+ expectedSuggestion);

          Assert.AreEqual(expectedSuggestion, realSuggestion, ' for password: ' + testPasswords[i].Password);
          Inc(j);
        end;

        O('');
        O('=========================================');
      finally
        result.Free;
      end;
    end;
  finally
    zx.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TZxcvbnTest);
end.
