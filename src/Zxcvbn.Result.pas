unit Zxcvbn.Result;

interface
uses
  System.Classes, System.Generics.Collections;

type
  /// <summary>
  /// Warning associated with the password analysis
  /// </summary>
  TZxcvbnWarning = (
    /// <summary>
    /// Empty string
    /// </summary>
    zwDefault,

    /// <summary>
    /// Straight rows of keys are easy to guess
    /// </summary>
    zwStraightRow,

    /// <summary>
    /// Short keyboard patterns are easy to guess
    /// </summary>
    zwShortKeyboardPatterns,

    /// <summary>
    /// Repeats like "aaa" are easy to guess
    /// </summary>
    zwRepeatsLikeAaaEasy,

    /// <summary>
    /// Repeats like "abcabcabc" are only slightly harder to guess than "abc"
    /// </summary>
    zwRepeatsLikeAbcSlighterHarder,

    /// <summary>
    /// Sequences like abc or 6543 are easy to guess
    /// </summary>
    zwSequenceAbcEasy,

    /// <summary>
    /// Recent years are easy to guess
    /// </summary>
    zwRecentYearsEasy,

    /// <summary>
    ///  Dates are often easy to guess
    /// </summary>
    zwDatesEasy,

    /// <summary>
    ///  This is a top-10 common password
    /// </summary>
    zwTop10Passwords,

    /// <summary>
    /// This is a top-100 common password
    /// </summary>
    zwTop100Passwords,

    /// <summary>
    /// This is a very common password
    /// </summary>
    zwCommonPasswords,

    /// <summary>
    /// This is similar to a commonly used password
    /// </summary>
    zwSimilarCommonPasswords,

    /// <summary>
    /// A word by itself is easy to guess
    /// </summary>
    zwWordEasy,

    /// <summary>
    /// Names and surnames by themselves are easy to guess
    /// </summary>
    zwNameSurnamesEasy,

    /// <summary>
    /// Common names and surnames are easy to guess
    /// </summary>
    zwCommonNameSurnamesEasy,

    /// <summary>
    ///  Empty String
    /// </summary>
    zwEmpty
  );

type
  /// <summary>
  /// Suggestion on how to improve the password base on zxcvbn's password analysis
  /// </summary>
  TZxcvbnSuggestion = (
    /// <summary>
    ///  Use a few words, avoid common phrases
    ///  No need for symbols, digits, or uppercase letters
    /// </summary>
    zsDefault,

    /// <summary>
    ///  Add another word or two. Uncommon words are better.
    /// </summary>
    zsAddAnotherWordOrTwo,

    /// <summary>
    ///  Use a longer keyboard pattern with more turns
    /// </summary>
    zsUseLongerKeyboardPattern,

    /// <summary>
    ///  Avoid repeated words and characters
    /// </summary>
    zsAvoidRepeatedWordsAndChars,

    /// <summary>
    ///  Avoid sequences
    /// </summary>
    zsAvoidSequences,

    /// <summary>
    ///  Avoid recent years
    ///  Avoid years that are associated with you
    /// </summary>
    zsAvoidYearsAssociatedYou,

    /// <summary>
    ///  Avoid dates and years that are associated with you
    /// </summary>
    zsAvoidDatesYearsAssociatedYou,

    /// <summary>
    ///  Capitalization doesn't help very much
    /// </summary>
    zsCapsDontHelp,

    /// <summary>
    /// All-uppercase is almost as easy to guess as all-lowercase
    /// </summary>
    zsAllCapsEasy,

    /// <summary>
    /// Reversed words aren't much harder to guess
    /// </summary>
    zsReversedWordEasy,

    /// <summary>
    ///  Predictable substitutions like '@' instead of 'a' don't help very much
    /// </summary>
    zsPredictableSubstitutionsEasy,

    /// <summary>
    ///  Empty String
    /// </summary>
    zsEmpty
  );
  TZxcvbnSuggestions = set of TZxcvbnSuggestion;

type
  /// <summary>
  /// <para>A single match that one of the pattern matchers has made against the password being tested.</para>
  ///
  /// <para>Some pattern matchers implement subclasses of match that can provide more information on their specific results.</para>
  ///
  /// <para>Matches must all have the <see cref="Pattern"/>, <see cref="Token"/>, <see cref="Entropy"/>, <see cref="i"/> and
  /// <see cref="j"/> fields (i.e. all but the <see cref="Cardinality"/> field, which is optional) set before being returned from the matcher
  /// in which they are created.</para>
  /// </summary>
  TZxcvbnMatch = class
  public
    /// <summary>
    /// The name of the pattern matcher used to generate this match
    /// </summary>
    Pattern: String;

    /// <summary>
    /// The portion of the password that was matched
    /// </summary>
    Token: String;

    /// <summary>
    /// The entropy that this portion of the password covers using the current pattern matching technique
    /// </summary>
    Entropy: Extended;


    // The following are more internal measures, but may be useful to consumers

    /// <summary>
    /// Some pattern matchers can associate the cardinality of the set of possible matches that the
    /// entropy calculation is derived from. Not all matchers provide a value for cardinality.
    /// </summary>
    Cardinality: Integer;

    /// <summary>
    /// The start index in the password string of the matched token.
    /// </summary>
    i: Integer;// Start Index

    /// <summary>
    /// The end index in the password string of the matched token.
    /// </summary>
    j: Integer; // End Index

    function Clone: TZxcvbnMatch;
  end;

type
  /// <summary>
  /// The results of zxcvbn's password analysis
  /// </summary>
  TZxcvbnResult = class
  private
	 function get_Guesses: Real;
    function get_GuessesLog10: Real;
  public
    /// <summary>
    /// A calculated estimate of how many bits of entropy the password covers, rounded to three decimal places.
    /// </summary>
    Entropy: Double;

    /// <summary>
    /// The number of milliseconds that zxcvbn took to calculate results for this password
    /// </summary>
	 CalcTime: NativeInt;

	 /// <summary>
	 /// A score from 0 to 4 (inclusive), with 0 being least secure and 4 being most secure calculated from crack time:
	 /// [0,1,2,3,4] if crack time is less than [10**2, 10**4, 10**6, 10**8, Infinity] seconds.
	 /// Useful for implementing a strength meter
    /// </summary>
	 Score: Integer;

    /// <summary>
    /// An estimation of the crack time for this password in seconds
    /// </summary>
//	 CrackTime: Double;
	 /// <summary>Time (seconds) to crack with an online attack on a service that ratelimits password auth attempts. (100 guesses/hour)</summary>
	 CrackTime_OnlineThrottling: Double;
	 /// <summary>Time (seconds) to crack with online attack on a service that doesn't ratelimit, or where an attacker has outsmarted ratelimiting. (100 guesses/sec)</summary>
	 CrackTime_OnlineNoThrottling: Double;
	 /// <summary>Time (seconds) to crack with an offline attack. assumes multiple attackers, proper user-unique salting, and a slow hash function with moderate work factor, such as bcrypt, scrypt, PBKDF2. (10,000 guesses/sec)</summary>
	 CrackTime_OfflineSlowHashing: Double;
	 /// <summary>Time (seconds) to crack with offline attack with user-unique salting but a fast hash function like SHA-1, SHA-256 or MD5. A wide range of reasonable numbers anywhere from one billion - one trillion guesses per second, depending on number of cores and machines. (10 billion gusses/sec)</summary>
	 CrackTime_OfflineFastHashing: Double;

//	res.CrackTimeDisplay := Zxcvbn.Utility.DisplayTime(crackTime, FTranslation);
	CrackTimeDisplay_OnlineThrottling: string;
	CrackTimeDisplay_OnlineNoThrottling: string;
	CrackTimeDisplay_OfflineSlowHashing: string;
	CrackTimeDisplay_OfflineFastHashing: string;


    /// <summary>
    /// A friendly string for the crack time (like "centuries", "instant", "7 minutes", "14 hours" etc.)
    /// </summary>
    CrackTimeDisplay: String;

	 /// <summary>
    /// The sequence of matches that were used to create the entropy calculation
    /// </summary>
    MatchSequence: TList<TZxcvbnMatch>;

	 /// <summary>
	 /// The password that was used to generate these results
	 /// </summary>
	 Password: String;

	 /// <summary>
	 /// Warning on this password
	 /// </summary>
	 Warning: TZxcvbnWarning;

	 /// <summary>
	 /// Suggestion on how to improve the password
	 /// </summary>
	 Suggestions: TZxcvbnSuggestions;

	 /// <summary>
	 /// Constructor initialize Suggestion list.
	 /// </summary>
	 constructor Create;
	 destructor Destroy; override;

	 /// <summary>Estimated guesses needed to crack password</summary>
	 property Guesses: Real read get_Guesses;

	 /// <summary>Order of magnitude of result.Guesses</summary>
	 property GuessesLog10: Real read get_GuessesLog10;
  end;

implementation

uses
  Math,
  Zxcvbn.DateMatcher,
  Zxcvbn.DictionaryMatcher,
  Zxcvbn.L33tMatcher,
  Zxcvbn.RegexMatcher,
  Zxcvbn.RepeatMatcher,
  Zxcvbn.SequenceMatcher,
  Zxcvbn.SpatialMatcher,
  Zxcvbn.PasswordScoring;

{ TZxcvbnResult }

constructor TZxcvbnResult.Create;
begin
  Suggestions := [];
end;

destructor TZxcvbnResult.Destroy;
var
  match: TZxcvbnMatch;
begin
  if Assigned(MatchSequence) then
  begin
    for match in MatchSequence do
      match.Free;
    MatchSequence.Free;
  end;
  inherited;
end;

function TZxcvbnResult.get_Guesses: Real;
begin
	Result := 0.5 * Math.Power(2, Self.Entropy);
end;

function TZxcvbnResult.get_GuessesLog10: Real;
begin
	Result := Math.Log10(Self.Guesses);
end;

{ TZxcvbnMatch }

function TZxcvbnMatch.Clone: TZxcvbnMatch;

  procedure CopyBaseProperties(const AFrom: TZxcvbnMatch; var ATo: TZxcvbnMatch);
  begin
	 ATo.Pattern := AFrom.Pattern;
	 ATo.Token := AFrom.Token;
	 ATo.Entropy := AFrom.Entropy;
    ATo.Cardinality := AFrom.Cardinality;
    ATo.i := AFrom.i;
    ATo.j := AFrom.j;
  end;

begin
  if Self is TZxcvbnDateMatch then
  begin
    Result := TZxcvbnDateMatch.Create;
    CopyBaseProperties(Self, Result);
    (Self as TZxcvbnDateMatch).CopyTo(Result as TZxcvbnDateMatch);
  end else if (Self is TZxcvbnDictionaryMatch) or (Self is TZxcvbnL33tMatch) then
  begin
    if Self is TZxcvbnL33tMatch then
    begin
      Result := TZxcvbnL33tMatch.Create;
      CopyBaseProperties(Self, Result);
      (Self as TZxcvbnL33tMatch).CopyTo(Result as TZxcvbnL33tMatch);
      (Self as TZxcvbnDictionaryMatch).CopyTo(Result as TZxcvbnDictionaryMatch);
    end else
    begin
      Result := TZxcvbnDictionaryMatch.Create;
      CopyBaseProperties(Self, Result);
      (Self as TZxcvbnDictionaryMatch).CopyTo(Result as TZxcvbnDictionaryMatch);
    end;
  end else if Self is TZxcvbnRepeatMatch then
  begin
    Result := TZxcvbnRepeatMatch.Create;
    CopyBaseProperties(Self, Result);
    (Self as TZxcvbnRepeatMatch).CopyTo(Result as TZxcvbnRepeatMatch);
  end else if Self is TZxcvbnSequenceMatch then
  begin
    Result := TZxcvbnSequenceMatch.Create;
    CopyBaseProperties(Self, Result);
    (Self as TZxcvbnSequenceMatch).CopyTo(Result as TZxcvbnSequenceMatch);
  end else if Self is TZxcvbnSpatialMatch then
  begin
    Result := TZxcvbnSpatialMatch.Create;
    CopyBaseProperties(Self, Result);
    (Self as TZxcvbnSpatialMatch).CopyTo(Result as TZxcvbnSpatialMatch);
  end else
  begin
    Result := TZxcvbnMatch.Create;
    CopyBaseProperties(Self, Result);
  end;
end;

end.
