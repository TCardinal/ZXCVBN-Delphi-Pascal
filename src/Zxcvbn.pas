unit Zxcvbn;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.Translation,
  Zxcvbn.MatcherFactory,
  Zxcvbn.Matcher,
  Zxcvbn.DictionaryMatcher,
  Zxcvbn.Result;

type
  /// <summary>
  /// <para>Zxcvbn is used to estimate the strength of passwords. </para>
  ///
  /// <para>This implementation is a port of the Zxcvbn JavaScript library by Dan Wheeler:
  /// https://github.com/lowe/zxcvbn</para>
  ///
  /// <para>To quickly evaluate a password, use the <see cref="MatchPassword"/> static function.</para>
  ///
  /// <para>To evaluate a number of passwords, create an instance of this object and repeatedly call the <see cref="EvaluatePassword"/> function.
  /// Reusing the the Zxcvbn instance will ensure that pattern matchers will only be created once rather than being recreated for each password
  /// e=being evaluated.</para>
  /// </summary>
  TZxcvbn = class
  const
    BruteforcePattern = 'bruteforce';
  private
    FMatcherFactory: IZxcvbnMatcherFactory;
    FTranslation: TZxcvbnTranslation;

    /// <summary>
    /// Returns a new result structure initialised with data for the lowest entropy result of all of the matches passed in, adding brute-force
    /// matches where there are no lesser entropy found pattern matches.
    /// </summary>
    /// <param name="APassword">Password being evaluated</param>
    /// <param name="AMatches">List of matches found against the password</param>
    /// <returns>A result object for the lowest entropy match sequence</returns>
    function FindMinimumEntropyMatch(APassword: String; AMatches: TList<TZxcvbnMatch>): TZxcvbnResult;

    function GetLongestMatch(const AMatchSequence: TList<TZxcvbnMatch>): TZxcvbnMatch;

    procedure GetMatchFeedback(const AMatch: TZxcvbnMatch; AIsSoleMatch: Boolean; var AResult: TZxcvbnResult);

    procedure GetDictionaryMatchFeedback(const AMatch: TZxcvbnDictionaryMatch; AIsSoleMatch: Boolean; var AResult: TZxcvbnResult);
  public
    /// <summary>
    /// Create a new instance of Zxcvbn that uses the default matchers.
    /// </summary>
    /// <param name="ADictionariesPath">Path where to look for dictionary files (if not embedded in resources)</param>
    /// <param name="ATranslation">The language in which the strings are returned</param>
    constructor Create(ADictionariesPath: String = ''; ATranslation: TZxcvbnTranslation = ztEnglish); overload;

    /// <summary>
    /// Create an instance of Zxcvbn that will use the given matcher factory to create matchers to use
    /// to find password weakness.
    /// </summary>
    /// <param name="AMatcherFactory">The factory used to create the pattern matchers used</param>
    /// <param name="ATranslation">The language in which the strings are returned</param>
    constructor Create(AMatcherFactory: IZxcvbnMatcherFactory; ATranslation: TZxcvbnTranslation = ztEnglish); overload;

    /// <summary>
    /// <para>Perform the password matching on the given password and user inputs, returing the result structure with information
    /// on the lowest entropy match found.</para>
    ///
    /// <para>User data will be treated as another kind of dictionary matching, but can be different for each password being evaluated.</para>
    /// </summary>
    /// <param name="APassword">Password</param>
    /// <param name="AUserInputs">Optionally, a string list of user data</param>
    /// <returns>Result for lowest entropy match</returns>
    function EvaluatePassword(APassword: String; AUserInputs: TStringList = nil): TZxcvbnResult;

    /// <summary>
    /// <para>A class function to match a password against the default matchers without having to create
    /// an instance of Zxcvbn yourself, with supplied user data. </para>
    ///
    /// <para>Supplied user data will be treated as another kind of dictionary matching.</para>
    /// </summary>
    /// <param name="APassword">the password to test</param>
    /// <param name="ADictionariesPath">optionally, dictionary files path</param>
    /// <param name="AUserInputs">optionally, the user inputs list</param>
    /// <returns>The results of the password evaluation</returns>
    class function MatchPassword(APassword: String; ADictionariesPath: String = '';
      AUserInputs: TStringList = nil): TZxcvbnResult;
  end;

implementation
uses
  System.Math,
  System.Diagnostics,
  System.RegularExpressions,
  Zxcvbn.DefaultMatcherFactory,
  Zxcvbn.PasswordScoring,
  Zxcvbn.SpatialMatcher,
  Zxcvbn.RepeatMatcher,
  Zxcvbn.L33tMatcher,
  Zxcvbn.Utility;

{ TZxcvbn }

constructor TZxcvbn.Create(ADictionariesPath: String = ''; ATranslation: TZxcvbnTranslation = ztEnglish);
begin
  Create(TZxcvbnDefaultMatcherFactory.Create(ADictionariesPath), ATranslation);
end;

constructor TZxcvbn.Create(AMatcherFactory: IZxcvbnMatcherFactory; ATranslation: TZxcvbnTranslation = ztEnglish);
begin
  FMatcherFactory := AMatcherFactory;
  FTranslation := ATranslation;
end;

function TZxcvbn.FindMinimumEntropyMatch(APassword: String; AMatches: TList<TZxcvbnMatch>): TZxcvbnResult;
var
  bruteforce_cardinality: Integer;
  minimumEntropyToIndex: array of Double;
  bestMatchForIndex: array of TZxcvbnMatch;
  k: Integer;
  match: TZxcvbnMatch;
  candidate_entropy: Double;
  matchSequence, matchSequenceCopy: TList<TZxcvbnMatch>;
  m1, m2: TZxcvbnMatch;
  m2i: Integer;
  ns, ne: Integer;
  minEntropy: Double;
  crackTime: Double;
  res: TZxcvbnResult;
  longestMatch: TZxcvbnMatch;
begin
  bruteforce_cardinality := Zxcvbn.PasswordScoring.PasswordCardinality(APassword);

  // Minimum entropy up to position k in the password
  SetLength(minimumEntropyToIndex, APassword.Length);
  SetLength(bestMatchForIndex, APassword.Length);

  for k := 0 to APassword.Length - 1 do
  begin
    // Start with bruteforce scenario added to previous sequence to beat
    if (k = 0) then
      minimumEntropyToIndex[k] := LogN(2, bruteforce_cardinality)
    else
      minimumEntropyToIndex[k] := (minimumEntropyToIndex[k - 1]) + LogN(2, bruteforce_cardinality);

    // All matches that end at the current character, test to see if the entropy is less
    for match in AMatches do
    begin
      if (match.j <> k) then Continue;

      if (match.i <= 0) then
      begin
        candidate_entropy := match.Entropy;
      end else
        candidate_entropy := minimumEntropyToIndex[match.i - 1] + match.Entropy;

      if (candidate_entropy < minimumEntropyToIndex[k]) then
      begin
        minimumEntropyToIndex[k] := candidate_entropy;
        bestMatchForIndex[k] := match;
      end;
    end;
  end;

  // Walk backwards through lowest entropy matches, to build the best password sequence
  matchSequence := TList<TZxcvbnMatch>.Create;
  k := APassword.Length-1;
  while k >= 0 do
  begin
    if (bestMatchForIndex[k] <> nil) then
    begin
      // to-do clone
      matchSequence.Add(bestMatchForIndex[k].Clone);
      k := bestMatchForIndex[k].i; // Jump back to start of match
    end;
    Dec(k);
  end;
  matchSequence.Reverse;

  // The match sequence might have gaps, fill in with bruteforce matching
  // After this the matches in matchSequence must cover the whole string (i.e. match[k].j == match[k + 1].i - 1)
  if (matchSequence.Count = 0) and (APassword.Length > 0) then
  begin
    // To make things easy, we'll separate out the case where there are no matches so everything is bruteforced
    match := TZxcvbnMatch.Create;
    match.i := 0;
    match.j := APassword.Length;
    match.Token := APassword;
    match.Cardinality := bruteforce_cardinality;
    match.Pattern := BruteforcePattern;
    try
      match.Entropy := LogN(2, Power(bruteforce_cardinality, APassword.Length));
    except
      on e: EOverflow do
        match.Entropy := Infinity;
    end;
    matchSequence.Add(match);
  end else
  begin
    // There are matches, so find the gaps and fill them in
    matchSequenceCopy := TList<TZxcvbnMatch>.Create;
    for k := 0 to matchSequence.Count-1 do
    begin
      m1 := matchSequence[k];
      // Next match, or a match past the end of the password
      if (k < matchSequence.Count - 1) then
        m2i := matchSequence[k + 1].i
      else
      begin
        m2i := APassword.Length;
      end;

      // to-do clone
      matchSequenceCopy.Add(m1.Clone);
      if (m1.j < m2i - 1) then
      begin
        // Fill in gap
        ns := m1.j + 1;
        ne := m2i - 1;

        match := TZxcvbnMatch.Create;
        match.i := ns;
        match.j := ne;
        match.Token := APassword.Substring(ns, ne - ns + 1);
        match.Cardinality := bruteforce_cardinality;
        match.Pattern := BruteforcePattern;
        match.Entropy := LogN(2, Power(bruteforce_cardinality, ne - ns + 1));
        matchSequenceCopy.Add(match);
      end;
    end;

    for match in matchSequence do
      match.Free;
    matchSequence.Free;
    matchSequence := matchSequenceCopy;
  end;

  if (APassword.Length = 0) then
    minEntropy := 0
  else
    minEntropy := minimumEntropyToIndex[APassword.Length - 1];
  crackTime := Zxcvbn.PasswordScoring.EntropyToCrackTime(minEntropy);

  res := TZxcvbnResult.Create;
  res.Password := APassword;
  res.Entropy := minEntropy;
  res.MatchSequence := matchSequence;
  res.CrackTime := crackTime;
  res.CrackTimeDisplay := Zxcvbn.Utility.DisplayTime(crackTime, FTranslation);
  res.Score := Zxcvbn.PasswordScoring.CrackTimeToScore(crackTime);

  //starting feedback
  res.Warning := zwDefault;
  res.Suggestions := [];
//  Include(res.Suggestions, zsDefault);

  if Assigned(matchSequence) then
  begin
    if (matchSequence.Count > 0) then
    begin
      //no Feedback if score is good or great
      if (res.Score > 2) then
      begin
        res.Warning := zwEmpty;
        res.Suggestions := [];
        Include(res.Suggestions, zsEmpty);
      end else
      begin
        //tie feedback to the longest match for longer sequences
        longestMatch := GetLongestMatch(matchSequence);
        GetMatchFeedback(longestMatch, (matchSequence.Count = 1), res);
        Include(res.Suggestions, zsAddAnotherWordOrTwo);
      end;
    end;
  end;
  Result := res;
end;

function TZxcvbn.GetLongestMatch(const AMatchSequence: TList<TZxcvbnMatch>): TZxcvbnMatch;
var
  longestMatch: TZxcvbnMatch;
  match: TZxcvbnMatch;
begin
  longestMatch := nil;

  if Assigned(AMatchSequence) then
  begin
    if (AMatchSequence.Count > 0) then
    begin
      longestMatch := AMatchSequence[0];
      for match in AMatchSequence do
      begin
        if (match.Token.Length > longestMatch.Token.Length) then
          longestMatch := match;
      end;
    end;
  end;

  Result := longestMatch;
end;

procedure TZxcvbn.GetMatchFeedback(const AMatch: TZxcvbnMatch; AIsSoleMatch: Boolean; var AResult: TZxcvbnResult);
var
  spatialMatch: TZxcvbnSpatialMatch;
begin
  if (AMatch.Pattern = 'dictionary') then
  begin
    GetDictionaryMatchFeedback(TZxcvbnDictionaryMatch(AMatch), AIsSoleMatch, AResult);
  end else if (AMatch.Pattern = 'spatial') then
  begin
    spatialMatch := TZxcvbnSpatialMatch(AMatch);

    if (spatialMatch.Turns = 1) then
      AResult.Warning := TZxcvbnWarning.zwStraightRow
    else
      AResult.Warning := TZxcvbnWarning.zwShortKeyboardPatterns;

    AResult.Suggestions := [];
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsUseLongerKeyboardPattern);
  end else if (AMatch.Pattern = 'repeat') then
  begin
    if (TZxcvbnRepeatMatch(AMatch).BaseToken.Length = 1) then
      AResult.Warning := TZxcvbnWarning.zwRepeatsLikeAaaEasy
    else
      AResult.Warning := TZxcvbnWarning.zwRepeatsLikeAbcSlighterHarder;

    AResult.Suggestions := [];
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsAvoidRepeatedWordsAndChars);
  end else if (AMatch.Pattern = 'sequence') then
  begin
    AResult.Warning := TZxcvbnWarning.zwSequenceAbcEasy;

    AResult.Suggestions := [];
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsAvoidSequences);

    //todo: add support for recent_year
  end else if (AMatch.Pattern = 'date') then
  begin
    AResult.Warning := TZxcvbnWarning.zwDatesEasy;

    AResult.Suggestions := [];
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsAvoidDatesYearsAssociatedYou);
  end else
  begin
    AResult.Suggestions := [];
  end;
end;

procedure TZxcvbn.GetDictionaryMatchFeedback(const AMatch: TZxcvbnDictionaryMatch; AIsSoleMatch: Boolean; var AResult: TZxcvbnResult);
var
  word: String;
begin
  if (AMatch.DictionaryName.Equals('passwords')) then
  begin
    //todo: add support for reversed words
    if (AIsSoleMatch and not (AMatch is TZxcvbnL33tMatch)) then
    begin
      if (AMatch.Rank <= 10) then
        AResult.Warning := TZxcvbnWarning.zwTop10Passwords
      else if (AMatch.Rank <= 100) then
        AResult.Warning := TZxcvbnWarning.zwTop100Passwords
      else
        AResult.Warning := TZxcvbnWarning.zwCommonPasswords;
    end else if (Zxcvbn.PasswordScoring.CrackTimeToScore(Zxcvbn.PasswordScoring.EntropyToCrackTime(AMatch.Entropy)) <= 1) then
    begin
      AResult.Warning := TZxcvbnWarning.zwSimilarCommonPasswords;
    end
  end
  else if (AMatch.DictionaryName.Equals('english')) then
  begin
    if AIsSoleMatch then
      AResult.Warning := TZxcvbnWarning.zwWordEasy;
  end
  else if (AMatch.DictionaryName.Equals('surnames') or
           AMatch.DictionaryName.Equals('male_names') or
           AMatch.DictionaryName.Equals('female_names')) then
  begin
    if AIsSoleMatch then
      AResult.Warning := TZxcvbnWarning.zwNameSurnamesEasy
    else
      AResult.Warning := TZxcvbnWarning.zwCommonNameSurnamesEasy;
  end
  else
  begin
    AResult.warning := TZxcvbnWarning.zwEmpty;
  end;

  word := AMatch.Token;
  if (TRegex.IsMatch(word, Zxcvbn.PasswordScoring.StartUpper)) then
  begin
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsCapsDontHelp);
  end
  else if (TRegex.IsMatch(word, Zxcvbn.PasswordScoring.AllUpper) and not word.Equals(word.ToLowerInvariant)) then
  begin
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsAllCapsEasy);
  end;

  //todo: add support for reversed words
  //if match.reversed and match.token.length >= 4
  //    suggestions.push "Reversed words aren't much harder to guess"

  if (AMatch is TZxcvbnL33tMatch) then
    Include(AResult.Suggestions, TZxcvbnSuggestion.zsPredictableSubstitutionsEasy);
end;

function TZxcvbn.EvaluatePassword(APassword: String; AUserInputs: TStringList = nil): TZxcvbnResult;
var
  matches: TList<TZxcvbnMatch>;
  matcher: IZxcvbnMatcher;
  match: TZxcvbnMatch;
  res: TZxcvbnResult;
  timer: TStopWatch;
begin
  matches := TList<TZxcvbnMatch>.Create;

  timer := System.Diagnostics.TStopwatch.StartNew;

  for matcher in FMatcherFactory.CreateMatchers(AUserInputs) do
    matcher.MatchPassword(APassword, matches);

  res := FindMinimumEntropyMatch(APassword, matches);

  // cleanup
  for match in matches do
    match.Free;
  matches.Free;

  timer.Stop;
  res.CalcTime := timer.ElapsedMilliseconds;

  Result := res;
end;

class function TZxcvbn.MatchPassword(APassword: String; ADictionariesPath: String = '';
  AUserInputs: TStringList = nil): TZxcvbnResult;
var
  zx: TZxcvbn;
begin
  zx := TZxcvbn.Create(ADictionariesPath);
  try
    Result := zx.EvaluatePassword(APassword, AUserInputs);
  finally
    zx.Free;
  end;
end;

end.
