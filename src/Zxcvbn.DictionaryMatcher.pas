unit Zxcvbn.DictionaryMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  TZxcvbnDictionaryMatch = class;

  /// <summary>
  /// <para>This matcher reads in a list of words (in frequency order) and matches substrings of the password against that dictionary.</para>
  ///
  /// <para>The dictionary to be used can be specified directly by passing an enumerable of strings through the constructor (e.g. for
  /// matching agains user inputs). Most dictionaries will be in word list files.</para>
  ///
  /// <para>Using external files is a departure from the JS version of Zxcvbn which bakes in the word lists, so the default dictionaries
  /// have been included in the Zxcvbn assembly as embedded resources (to remove the external dependency). Thus when a word list is specified
  /// by name, it is first checked to see if it matches and embedded resource and if not is assumed to be an external file. </para>
  ///
  /// <para>Thus custom dictionaries can be included by providing the name of an external text file, but the built-in dictionaries (english.lst,
  /// female_names.lst, male_names.lst, passwords.lst, surnames.lst) can be used without concern about locating a dictionary file in an accessible
  /// place.</para>
  ///
  /// <para>Dictionary word lists must be in decreasing frequency order and contain one word per line with no additional information.</para>
  /// </summary>
  TZxcvbnDictionaryMatcher = class(TInterfacedObject, IZxcvbnMatcher)
  const
    DictionaryPattern = 'dictionary';
  private
    FDictionaryName: String;
    FRankedDictionary: TDictionary<String, Integer>;

    procedure CalculateEntropyForMatch(AMatch: TZxcvbnDictionaryMatch);
    function BuildRankedDictionary(AWordListFile: String): TDictionary<String, Integer>; overload;
    function BuildRankedDictionary(AWordList: TStringList): TDictionary<String, Integer>; overload;
  public
    /// <summary>
    /// Creates a new dictionary matcher. <paramref name="AWordListPath"/> must be the path (relative or absolute) to a file containing one word per line,
    /// entirely in lowercase, ordered by frequency (decreasing); or <paramref name="AWordListPath"/> must be the name of a built-in dictionary.
    /// </summary>
    /// <param name="AName">The name provided to the dictionary used</param>
    /// <param name="AWordListPath">The filename of the dictionary (full or relative path) or name of built-in dictionary</param>
    constructor Create(AName: String; AWordListPath: String); overload;

    /// <summary>
    /// Creates a new dictionary matcher from the passed in word list. If there is any frequency order then they should be in
    /// decreasing frequency order.
    /// </summary>
    constructor Create(AName: String; AWordList: TStringList); overload;

    destructor Destroy; override;

    /// <summary>
    /// Match substrings of password agains the loaded dictionary. Adds dictionary matches to AMatches
    /// </summary>
    /// <param name="APassword">The password to match</param>
    /// <param name="AMatches"></param>
    /// <seealso cref="TZxcvbnDictionaryMatch"/>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
  end;

  /// <summary>
  /// Matches found by the dictionary matcher contain some additional information about the matched word.
  /// </summary>
  TZxcvbnDictionaryMatch = class(TZxcvbnMatch)
  public
    /// <summary>
    /// The dictionary word matched
    /// </summary>
    MatchedWord: String;

    /// <summary>
    /// The rank of the matched word in the dictionary (i.e. 1 is most frequent, and larger numbers are less common words)
    /// </summary>
    Rank: Integer;

    /// <summary>
    /// The name of the dictionary the matched word was found in
    /// </summary>
    DictionaryName: String;

    /// <summary>
    /// The base entropy of the match, calculated from frequency rank
    /// </summary>
    BaseEntropy: Double;

    /// <summary>
    /// Additional entropy for this match from the use of mixed case
    /// </summary>
    UppercaseEntropy: Double;

    procedure CopyTo(AMatch: TZxcvbnDictionaryMatch);
  end;

implementation
uses
  System.Math,
  Zxcvbn.PasswordScoring,
  Zxcvbn.Utility;

{ TZxcvbnDictionaryMatch }

procedure TZxcvbnDictionaryMatch.CopyTo(AMatch: TZxcvbnDictionaryMatch);
begin
  AMatch.MatchedWord := Self.MatchedWord;
  AMatch.Rank := Self.Rank;
  AMatch.DictionaryName := Self.DictionaryName;
  AMatch.BaseEntropy := Self.BaseEntropy;
  AMatch.UppercaseEntropy := Self.UppercaseEntropy;
end;

{ TZxcvbnDictionaryMatcher }

constructor TZxcvbnDictionaryMatcher.Create(AName: String; AWordListPath: String);
begin
  FDictionaryName := AName;
  FRankedDictionary := BuildRankedDictionary(AWordListPath);
end;

constructor TZxcvbnDictionaryMatcher.Create(AName: String; AWordList: TStringList);
var
  wordListToLower: TStringList;
  i: Integer;
begin
  FDictionaryName := AName;

  // Must ensure that the dictionary is using lowercase words only
  wordListToLower := TStringList.Create;
  try
    if Assigned(AWordList) then
    begin
      for i := 0 to AWordList.Count-1 do
        wordListToLower.Add(AWordList[i].ToLower);
    end;
    FRankedDictionary := BuildRankedDictionary(wordListToLower);
  finally
    wordListToLower.Free;
  end;
end;

destructor TZxcvbnDictionaryMatcher.Destroy;
begin
  FRankedDictionary.Free;
  inherited;
end;

function TZxcvbnDictionaryMatcher.BuildRankedDictionary(AWordListFile: String): TDictionary<String, Integer>;
var
  lines: TStringList;
begin
  // Look first to wordlists embedded in assembly (i.e. default dictionaries) otherwise treat as file path

  lines := Zxcvbn.Utility.GetEmbeddedResourceLines(Format('ZxcvbnDictionaries_%s', [ChangeFileExt(AWordListFile, '')]));
  try
    if not Assigned(lines) then
    begin
      lines := TStringList.Create;
      lines.LoadFromFile(AWordListFile);
    end;

    Result := BuildRankedDictionary(lines);
  finally
    if Assigned(lines) then
      lines.Free;
  end;
end;

function TZxcvbnDictionaryMatcher.BuildRankedDictionary(AWordList: TStringList): TDictionary<String, Integer>;
var
  dict: TDictionary<String, Integer>;
  i: Integer;
begin
  dict := TDictionary<String, Integer>.Create;

  for i := 0 to AWordList.Count-1 do
  begin
    // The word list is assumed to be in increasing frequency order
    dict.Add(AWordList[i], i+1);
  end;

  Result := dict;
end;

procedure TZxcvbnDictionaryMatcher.CalculateEntropyForMatch(AMatch: TZxcvbnDictionaryMatch);
begin
  AMatch.BaseEntropy := LogN(2, AMatch.Rank);
  AMatch.UppercaseEntropy := Zxcvbn.PasswordScoring.CalculateUppercaseEntropy(AMatch.Token);

  AMatch.Entropy := AMatch.BaseEntropy + AMatch.UppercaseEntropy;
end;

procedure TZxcvbnDictionaryMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  passwordLower: String;
  addMatch: TZxcvbnDictionaryMatch;
  match: TZxcvbnMatch;
  matches: TList<TZxcvbnMatch>;
  i, j: Integer;
  passSub: String;
begin
  passwordLower := APassword.ToLower;

  matches := TList<TZxcvbnMatch>.Create;
  try
    for i := 0 to APassword.Length-1 do
    begin
      for j := i to APassword.Length-1 do
      begin
        passSub := passwordLower.Substring(i, j - i + 1);
        if FRankedDictionary.ContainsKey(passSub) then
        begin
          addMatch := TZxcvbnDictionaryMatch.Create;
          addMatch.Pattern := DictionaryPattern;
          addMatch.i := i;
          addMatch.j := j;
          addMatch.Token := APassword.Substring(i, j - i + 1); // Could have different case so pull from password
          addMatch.MatchedWord := passSub;
          addMatch.Rank := FRankedDictionary.Items[passSub];
          addMatch.DictionaryName := FDictionaryName;
          addMatch.Cardinality := FRankedDictionary.Values.Count;
          matches.Add(addMatch);
        end;
      end;
    end;

    for match in matches do
      CalculateEntropyForMatch(match as TZxcvbnDictionaryMatch);

    AMatches.AddRange(matches);
  finally
    matches.Free;
  end;
end;

end.
