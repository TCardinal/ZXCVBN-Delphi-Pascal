unit Zxcvbn.RepeatMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  TZxcvbnRepeatMatch = class;

  /// <summary>
  /// Match repeated characters in the password (repeats must be more than two characters long to count)
  /// </summary>
  TZxcvbnRepeatMatcher = class(TInterfacedObject, IZxcvbnMatcher)
  const
    RepeatPattern = 'repeat';
  private
    function CalculateEntropy(AMatch: TZxcvbnRepeatMatch): Double;
  public
    /// <summary>
    /// Find repeat matches in <paramref name="APassword"/> and adds them to <paramref name="AMatches"/>
    /// </summary>
    /// <param name="APassword">The password to check</param>
    /// <param name="AMatches"></param>
    /// <seealso cref="TZxcvbnRepeatMatch"/>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
  end;

  /// <summary>
  /// A match found with the RepeatMatcher
  /// </summary>
  TZxcvbnRepeatMatch = class(TZxcvbnMatch)
  public
    /// <summary>
    /// The substring that was repeated
    /// </summary>
    BaseToken: String;

    /// <summary>
    /// Repeat count
    /// </summary>
    RepeatCount: Integer;

    procedure CopyTo(AMatch: TZxcvbnRepeatMatch);
  end;

implementation
uses
  System.Math,
  System.RegularExpressions,
  Zxcvbn.PasswordScoring,
  Zxcvbn.Utility;

{ TZxcvbnRepeatMatch }

procedure TZxcvbnRepeatMatch.CopyTo(AMatch: TZxcvbnRepeatMatch);
begin
  AMatch.BaseToken := Self.BaseToken;
  AMatch.RepeatCount := Self.RepeatCount;
end;

{ TZxcvbnRepeatMatcher }

function TZxcvbnRepeatMatcher.CalculateEntropy(AMatch: TZxcvbnRepeatMatch): Double;
begin
  Result := LogN(2, Zxcvbn.PasswordScoring.PasswordCardinality(AMatch.BaseToken) * AMatch.RepeatCount);
end;

procedure TZxcvbnRepeatMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  addMatch: TZxcvbnRepeatMatch;
  matches: TList<TZxcvbnMatch>;
  i, j: Integer;
  lastIndex: Integer;
  greedy, lazy, lazyAnchored: TRegEx;
  greedyMatch, lazyMatch: System.RegularExpressions.TMatch;
  match, baseMatch: System.RegularExpressions.TMatch;
  baseToken: String;
  gl: Integer;
begin
  matches := TList<TZxcvbnMatch>.Create;
  try
    greedy := TRegEx.Create('(.+)\1+');
    lazy := TRegEx.Create('(.+?)\1+');
    lazyAnchored := TRegEx.Create('^(.+?)\1+$');
    lastIndex := 0;

    while (lastIndex < APassword.Length) do
    begin
      greedyMatch := greedy.Match(APassword, lastIndex, APassword.Length - lastIndex + 1);
      lazyMatch := lazy.Match(APassword, lastIndex, APassword.Length - lastIndex + 1);
      if not greedyMatch.Success then Break;

      if lazyMatch.Success then
        gl := lazyMatch.Groups[0].Length
      else
        gl := 0;

      if (greedyMatch.Groups[0].Length > gl) then
      begin
        match := greedyMatch;
        baseMatch := lazyAnchored.Match(match.Groups[0].Value);
        if baseMatch.Success then
          baseToken := baseMatch.Groups[0].Value
        else
          baseToken := match.Groups[0].Value;
      end else
      begin
        match := lazyMatch;
        baseToken := match.Groups[1].Value;
      end;

      i := match.Groups[0].Index-1;
      j := match.Groups[0].Index-1 + match.Groups[0].Length - 1;

      addMatch := TZxcvbnRepeatMatch.Create;
      addMatch.Pattern := RepeatPattern;
      addMatch.Token := APassword.Substring(i, j - i + 1);
      addMatch.i := i;
      addMatch.j := j;
      addMatch.RepeatCount := match.Groups[0].Length div baseToken.Length;
      addMatch.BaseToken := baseToken;
      addMatch.Entropy := CalculateEntropy(addMatch);
      matches.Add(addMatch);

      lastIndex := j + 1;
    end;

    AMatches.AddRange(matches);
  finally
    matches.Free;
  end;
end;

end.
