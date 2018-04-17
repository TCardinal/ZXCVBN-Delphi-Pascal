unit Zxcvbn.RegexMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.RegularExpressions,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  /// <summary>
  /// <para>Use a regular expression to match agains the password. (e.g. 'year' and 'digits' pattern matchers are implemented with this matcher.</para>
  /// <para>A note about cardinality: the cardinality parameter is used to calculate the entropy of matches found with the regex matcher. Since
  /// this cannot be calculated automatically from the regex pattern it must be provided. It can be provided per-character or per-match. Per-match will
  /// result in every match having the same entropy (lg cardinality) whereas per-character will depend on the match length (lg cardinality ^ length)</para>
  /// </summary>
  TZxcvbnRegexMatcher = class(TInterfacedObject, IZxcvbnMatcher)
  private
    FMatchRegex: TRegEx;
    FMatcherName: String;
    FCardinality: Integer;
    FPerCharCardinality: Boolean;
  public
    /// <summary>
    /// Create a new regex pattern matcher
    /// </summary>
    /// <param name="APattern">The regex pattern to match</param>
    /// <param name="ACardinality">The cardinality of this match. Since this cannot be calculated from a pattern it must be provided. Can
    /// be give per-matched-character or per-match</param>
    /// <param name="APerCharCardinality">True if cardinality is given as per-matched-character</param>
    /// <param name="AMatcherName">The name to give this matcher ('pattern' in resulting matches)</param>
    constructor Create(APattern: String; ACardinality: Integer; APerCharCardinality: Boolean = True;
      AMatcherName: String = 'regex'); overload;

    /// <summary>
    /// Create a new regex pattern matcher
    /// </summary>
    /// <param name="AMatchRegex">The regex object used to perform matching</param>
    /// <param name="ACardinality">The cardinality of this match. Since this cannot be calculated from a pattern it must be provided. Can
    /// be give per-matched-character or per-match</param>
    /// <param name="APerCharCardinality">True if cardinality is given as per-matched-character</param>
    /// <param name="AMatcherName">The name to give this matcher ('pattern' in resulting matches)</param>
    constructor Create(AMatchRegex: TRegEx; ACardinality: Integer; APerCharCardinality: Boolean = True;
      AMatcherName: String = 'regex'); overload;

    /// <summary>
    /// Find all matches of the regex in <paramref name="APassword"/> and adds them to <paramref name="AMatches"/> list
    /// </summary>
    /// <param name="APassword">The password to check</param>
    /// <param name="AMatches"></param>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
  end;


implementation
uses
  System.Math,
  Zxcvbn.Utility;

{ TZxcvbnRegexMatcher }

constructor TZxcvbnRegexMatcher.Create(APattern: String; ACardinality: Integer;
  APerCharCardinality: Boolean = True; AMatcherName: String = 'regex');
begin
  Create(TRegEx.Create(APattern), ACardinality, APerCharCardinality, AMatcherName);
end;

constructor TZxcvbnRegexMatcher.Create(AMatchRegex: TRegEx; ACardinality: Integer;
  APerCharCardinality: Boolean = True; AMatcherName: String = 'regex');
begin
  FMatchRegex := AMatchRegex;
  FMatcherName := AMatcherName;
  FCardinality := ACardinality;
  FPerCharCardinality := APerCharCardinality;
end;

procedure TZxcvbnRegexMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  reMatches: System.RegularExpressions.TMatchCollection;
  rem: System.RegularExpressions.TMatch;
  pwMatches: TList<TZxcvbnMatch>;
  addMatch: TZxcvbnMatch;
begin
  reMatches := FMatchRegex.Matches(APassword);

  pwMatches := TList<TZxcvbnMatch>.Create;
  try
    for rem in reMatches do
    begin
      addMatch := TZxcvbnMatch.Create;
      addMatch.Pattern := FMatcherName;
      addMatch.i := rem.Index-1;
      addMatch.j := rem.Index-1 + rem.Length - 1;
      addMatch.Token := APassword.Substring(rem.Index-1, rem.Length);
      addMatch.Cardinality := FCardinality;
      if FPerCharCardinality then
        addMatch.Entropy := LogN(2, Power(FCardinality, rem.Length))
      else
        addMatch.Entropy := LogN(2, FCardinality);
      pwMatches.Add(addMatch);
    end;

    AMatches.AddRange(pwMatches);
  finally
    pwMatches.Free;
  end;
end;

end.
