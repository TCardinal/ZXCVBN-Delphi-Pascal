unit Zxcvbn.L33tMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.DictionaryMatcher,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  TZxcvbnL33tMatch = class;

  /// <summary>
  /// This matcher applies some known l33t character substitutions and then attempts to match against passed in dictionary matchers.
  /// This detects passwords like 4pple which has a '4' substituted for an 'a'
  /// </summary>
  TZxcvbnL33tMatcher = class(TInterfacedObject, IZxcvbnMatcher)
  private
    FDictionaryMatchers: TList<IZxcvbnMatcher>;

    FSubstitutions: TDictionary<Char, String>;

    procedure CalculateL33tEntropy(AMatch: TZxcvbnL33tMatch);

    function TranslateString(ACharMap: TDictionary<Char, Char>; AStr: String): String;

    function EnumerateSubtitutions(ATable: TDictionary<Char, String>): TList<TDictionary<Char, Char>>;

    function BuildSubstitutionsMap: TDictionary<Char, String>;
  public
    /// <summary>
    /// Create a l33t matcher that applies substitutions and then matches agains the passed in list of dictionary matchers.
    /// </summary>
    /// <param name="ADictionaryMatchers">The list of dictionary matchers to check transformed passwords against</param>
    constructor Create(const ADictionaryMatchers: TList<IZxcvbnMatcher>); overload;

    /// <summary>
    /// Create a l33t matcher that applies substitutions and then matches agains a single dictionary matcher.
    /// </summary>
    /// <param name="ADictionaryMatcher">The dictionary matcher to check transformed passwords against</param>
    constructor Create(const ADictionaryMatcher: IZxcvbnMatcher); overload;

    destructor Destroy; override;
    
    /// <summary>
    /// Apply applicable l33t transformations and check <paramref name="APassword"/> against the dictionaries. 
    /// </summary>
    /// <param name="APassword">The password to check</param>
    /// <param name="AMatches"></param>
    /// <seealso cref="TZxcvbnL33tMatch"/>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
  end;

  /// <summary>
  /// L33tMatcher results are like dictionary match results with some extra information that pertains to the extra entropy that
  /// is garnered by using substitutions.
  /// </summary>
  TZxcvbnL33tMatch = class(TZxcvbnDictionaryMatch)
  private
    FSubs: TDictionary<Char, Char>;
  public
    /// <summary>
    /// The extra entropy from using l33t substitutions
    /// </summary>
    L33tEntropy: Double;

    /// <summary>
    /// The character mappings that are in use for this match
    /// </summary>
    property Subs: TDictionary<Char, Char> read FSubs write FSubs;

    procedure CopyTo(AMatch: TZxcvbnL33tMatch);

    /// <summary>
    /// Create a new l33t match from a dictionary match
    /// </summary>
    /// <param name="dm">The dictionary match to initialise the l33t match from</param>
    constructor Create(ADictionaryMatch: TZxcvbnDictionaryMatch); overload;

    /// <summary>
    /// Create an empty l33t match
    /// </summary>
    constructor Create; overload;

    destructor Destroy; override;
  end;

implementation
uses
  System.Math,
  Zxcvbn.PasswordScoring,
  Zxcvbn.Utility;

{ TZxcvbnL33tMatch }

constructor TZxcvbnL33tMatch.Create(ADictionaryMatch: TZxcvbnDictionaryMatch);
begin
  Self.BaseEntropy := ADictionaryMatch.BaseEntropy;
  Self.Cardinality := ADictionaryMatch.Cardinality;
  Self.DictionaryName := ADictionaryMatch.DictionaryName;
  Self.Entropy := ADictionaryMatch.Entropy;
  Self.i := ADictionaryMatch.i;
  Self.j := ADictionaryMatch.j;
  Self.MatchedWord := ADictionaryMatch.MatchedWord;
  Self.Pattern := ADictionaryMatch.Pattern;
  Self.Rank := ADictionaryMatch.Rank;
  Self.Token := ADictionaryMatch.Token;
  Self.UppercaseEntropy := ADictionaryMatch.UppercaseEntropy;

  FSubs := TDictionary<Char, Char>.Create;
end;

constructor TZxcvbnL33tMatch.Create;
begin
  FSubs := TDictionary<Char, Char>.Create;
end;

destructor TZxcvbnL33tMatch.Destroy;
begin
  FSubs.Free;
  inherited;
end;

procedure TZxcvbnL33tMatch.CopyTo(AMatch: TZxcvbnL33tMatch);
var
  sub: TPair<Char, Char>;
begin
  AMatch.MatchedWord := Self.MatchedWord;
  AMatch.Rank := Self.Rank;
  AMatch.BaseEntropy := Self.BaseEntropy;
  AMatch.UppercaseEntropy := Self.UppercaseEntropy;
  AMatch.L33tEntropy := Self.L33tEntropy;
  AMatch.L33tEntropy := Self.L33tEntropy;
  for sub in FSubs do
    AMatch.Subs.Add(sub.Key, sub.Value);
end;

{ TZxcvbnL33tMatcher }

constructor TZxcvbnL33tMatcher.Create(const ADictionaryMatchers: TList<IZxcvbnMatcher>);
begin
  FDictionaryMatchers := TList<IZxcvbnMatcher>.Create;
  FDictionaryMatchers.AddRange(ADictionaryMatchers);

  FSubstitutions := BuildSubstitutionsMap;
end;

constructor TZxcvbnL33tMatcher.Create(const ADictionaryMatcher: IZxcvbnMatcher);
begin
  FDictionaryMatchers := TList<IZxcvbnMatcher>.Create;
  FDictionaryMatchers.Add(ADictionaryMatcher);

  FSubstitutions := BuildSubstitutionsMap;
end;

destructor TZxcvbnL33tMatcher.Destroy;
begin
  if Assigned(FSubstitutions) then
    FSubstitutions.Free;

  FDictionaryMatchers.Free;
  inherited;
end;

procedure TZxcvbnL33tMatcher.CalculateL33tEntropy(AMatch: TZxcvbnL33tMatch);
var
  possibilities: Integer;
  kvp: TPair<Char, Char>;
  subbedChars: Integer;
  unsubbedChars: Integer;
  c: Char;
  i: Integer;
  entropy: Double;
begin
  possibilities := 0;

  subbedChars := 0;
  unsubbedChars := 0;
  for kvp in AMatch.Subs do
  begin
    for c in AMatch.Token do
      if (c = kvp.Key) then Inc(subbedChars);

    for c in AMatch.Token do
      if (c = kvp.Value) then Inc(unsubbedChars);

    for i := 0 to Min(subbedChars, unsubbedChars) + 1 do
      possibilities := possibilities + Zxcvbn.PasswordScoring.Binomial(subbedChars + unsubbedChars, i);
  end;

  entropy := LogN(2, possibilities);

  // In the case of only a single subsitution (e.g. 4pple) this would otherwise come out as zero, so give it one bit
  if (entropy < 1) then
    AMatch.L33tEntropy := 1
  else
    AMatch.L33tEntropy := entropy;

  AMatch.Entropy := AMatch.Entropy + AMatch.L33tEntropy;

  // We have to recalculate the uppercase entropy -- the password matcher will have used the subbed password not the original text
  AMatch.Entropy := AMatch.Entropy - AMatch.UppercaseEntropy;
  AMatch.UppercaseEntropy := Zxcvbn.PasswordScoring.CalculateUppercaseEntropy(AMatch.Token);
  AMatch.Entropy := AMatch.Entropy + AMatch.UppercaseEntropy;
end;

function TZxcvbnL33tMatcher.TranslateString(ACharMap: TDictionary<Char, Char>; AStr: String): String;
var
  c: Char;
  res: String;
begin
  res := '';
  for c in AStr do
  begin
    if ACharMap.ContainsKey(c) then
      res := res + ACharMap[c]
    else
      res := res + c;
  end;

  Result := res;
end;

function TZxcvbnL33tMatcher.EnumerateSubtitutions(ATable: TDictionary<Char, String>): TList<TDictionary<Char, Char>>;
var
  subs: TList<TDictionary<Char, Char>>;
  mapPair: TPair<Char, String>;
  normalChar: Char;
  l33tChar: Char;
  addedSubs: TList<TDictionary<Char, Char>>;
  subDict: TDictionary<Char, Char>;
  newSub: TDictionary<Char, Char>;
begin
  subs := TList<TDictionary<Char, Char>>.Create;

  subs.Add(TDictionary<Char, Char>.Create); // Must be at least one mapping dictionary to work

  for mapPair in ATable do
  begin
    normalChar := mapPair.Key;
    for l33tChar in mapPair.Value do
    begin
      // Can't add while enumerating so store here
      addedSubs := TList<TDictionary<Char, Char>>.Create;

      for subDict in subs do
      begin
        if (subDict.ContainsKey(l33tChar)) then
        begin
          // This mapping already contains a corresponding normal character for this character, so keep the existing one as is
          //   but add a duplicate with the mappring replaced with this normal character
          newSub := TDictionary<Char, Char>.Create(subDict);
          newSub.AddOrSetValue(l33tChar, normalChar);
          addedSubs.Add(newSub);
        end else
        begin
          subDict.AddOrSetValue(l33tChar, normalChar);
        end;
      end;

      subs.AddRange(addedSubs);
      addedSubs.Free;
    end;
  end;

  Result := subs;
end;

function TZxcvbnL33tMatcher.BuildSubstitutionsMap: TDictionary<Char, String>;
var
  subs: TDictionary<Char, String>;
begin
  subs := TDictionary<Char, String>.Create;

  subs.Add('a', '4@');
  subs.Add('b', '8');
  subs.Add('c', '({[<');
  subs.Add('e', '3');
  subs.Add('g', '69');
  subs.Add('i', '1!|');
  subs.Add('l', '1|7');
  subs.Add('o', '0');
  subs.Add('s', '$5');
  subs.Add('t', '+7');
  subs.Add('x', '%');
  subs.Add('z', '2');

  Result := subs;
end;

procedure TZxcvbnL33tMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  addMatch: TZxcvbnL33tMatch;
  matches, sortedMatches: TList<TZxcvbnMatch>;
  subs: TList<TDictionary<Char, Char>>;
  subDict: TDictionary<Char, Char>;
  sub_password: String;
  matcher: IZxcvbnMatcher;
  dictMatches: TList<TZxcvbnMatch>;
  match: TZxcvbnMatch;
  token: String;
  usedSubs: TDictionary<Char, Char>;
  kv: TPair<Char, Char>;
  prevMatch: TZxcvbnL33tMatch;
begin
  matches := TList<TZxcvbnMatch>.Create;
  try
    subs := EnumerateSubtitutions(FSubstitutions);
    try
      prevMatch := nil;
      for subDict in subs do
      begin
        sub_password := TranslateString(subDict, APassword);

        for matcher in FDictionaryMatchers do
        begin
          dictMatches := TList<TZxcvbnMatch>.Create;
          try
            matcher.MatchPassword(sub_password, dictMatches);
            for match in dictMatches do
            begin
              token := APassword.Substring(match.i, match.j - match.i + 1);
              usedSubs := TDictionary<Char, Char>.Create;
              try
                for kv in subDict do
                  if token.Contains(kv.Key) then usedSubs.Add(kv.Key, kv.Value);
                if (usedSubs.Count > 0) then
                begin
                  if Assigned(prevMatch) then
                  begin
                    if (prevMatch.i = match.i) and
                       (prevMatch.j = match.j) and
                       (prevMatch.Token = token) then Continue;
                  end;
                  addMatch := TZxcvbnL33tMatch.Create(match as TZxcvbnDictionaryMatch);
                  addMatch.Token := token;
                  for kv in usedSubs do
                    addMatch.Subs.Add(kv.Key, kv.Value);
                  matches.Add(addMatch);
                  prevMatch := addMatch;
                end;
              finally
                usedSubs.Free;
              end;
            end;

            for match in dictMatches do
              match.Free;
          finally
            dictMatches.Free;
          end;
        end;
      end;

      for subDict in subs do
        subDict.Free;
    finally
      subs.Free;
    end;

    for match in matches do
      CalculateL33tEntropy(match as TZxcvbnL33tMatch);

    AMatches.AddRange(matches);
  finally
    matches.Free;
  end;
end;

end.
