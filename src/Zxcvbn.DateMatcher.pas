unit Zxcvbn.DateMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  TZxcvbnDateMatch = class;

  TZxcvbnSplitsArr = array[0..1] of Integer;

  TZxcvbnDmy = record
    valid: Boolean;
    day: Integer;
    month: Integer;
    year: Integer;
  end;

  TZxcvbnDm = record
    valid: Boolean;
    day: Integer;
    month: Integer;
  end;

  /// <summary>
  /// <para>This matcher attempts to guess dates, with and without date separators. e.g. 1197 (could be 1/1/97) through to 18/12/2015.</para>
  ///
  /// <para>The format for matching dates is quite particular, and only detected years in the range 00-99 and 1000-2050 are considered by
  /// this matcher.</para>
  /// </summary>
  TZxcvbnDateMatcher = class(TInterfacedObject, IZxcvbnMatcher)
  const
    DatePattern = 'date';
  private
    FDateSplits: TDictionary<Integer, TArray<TZxcvbnSplitsArr>>;
    function CalculateEntropy(AMatch: TZxcvbnDateMatch): Double;

    function MapIntsToDmy(AIntegers: TList<Integer>): TZxcvbnDmy;
    function MapIntsToDm(AIntegers: TList<Integer>): TZxcvbnDm;
    function TwoToFourDigitYear(AYear: Integer): Integer;

    function Metric(ACandidate: TZxcvbnDmy): Integer;
  public
    /// <summary>
    /// Find date matches in <paramref name="APassword"/> and adds them to <paramref name="AMatches"/>
    /// </summary>
    /// <param name="APassword">The passsword to check</param>
    /// <param name="AMatches"></param>
    /// <seealso cref="TZxcvbnDateMatch"/>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);

    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  /// A match found by the date matcher
  /// </summary>
  TZxcvbnDateMatch = class(TZxcvbnMatch)
  public
    /// <summary>
    /// The detected year
    /// </summary>
    Year: Integer;

    /// <summary>
    /// The detected month
    /// </summary>
    Month: Integer;

    /// <summary>
    /// The detected day
    /// </summary>
    Day: Integer;

    /// <summary>
    /// Where a date with separators is matched, this will contain the separator that was used (e.g. '/', '-')
    /// </summary>
    Separator: String;

    procedure CopyTo(AMatch: TZxcvbnDateMatch);
  end;

implementation
uses
  System.Math,
  System.Character,
  System.RegularExpressions,
  Zxcvbn.PasswordScoring,
  Zxcvbn.Utility;

const
  DATE_MIN_YEAR = 1000;
  DATE_MAX_YEAR = 2050;
  REFERENCE_YEAR = 2017;
  MIN_YEAR_SPACE = 10;

{ TZxcvbnDateMatch }

procedure TZxcvbnDateMatch.CopyTo(AMatch: TZxcvbnDateMatch);
begin
  AMatch.Year := Self.Year;
  AMatch.Month := Self.Month;
  AMatch.Day := Self.Day;
  AMatch.Separator := Self.Separator;
end;

{ TZxcvbnDateMatcher }

constructor TZxcvbnDateMatcher.Create;
var
  arr: TArray<TZxcvbnSplitsArr>;
begin
  FDateSplits := TDictionary<Integer, TArray<TZxcvbnSplitsArr>>.Create;

  // for length-4 strings, eg 1191 or 9111, two ways to split:
  SetLength(arr, 2);
  arr[0][0] := 1; arr[0][1] := 2; // 1 1 91 (2nd split starts at index 1, 3rd at index 2)
  arr[1][0] := 2; arr[1][1] := 3; // 91 1 1
  FDateSplits.Add(4, arr);

  arr[0][0] := 1; arr[0][1] := 3; // 1 11 91
  arr[1][0] := 2; arr[1][1] := 3; // 11 1 91
  FDateSplits.Add(5, arr);

  SetLength(arr, 3);
  arr[0][0] := 1; arr[0][1] := 2; // 1 1 1991
  arr[1][0] := 2; arr[1][1] := 4; // 11 11 91
  arr[2][0] := 4; arr[2][1] := 5; // 1991 1 1
  FDateSplits.Add(6, arr);

  SetLength(arr, 4);
  arr[0][0] := 1; arr[0][1] := 3; // 1 11 1991
  arr[1][0] := 2; arr[1][1] := 3; // 11 1 1991
  arr[2][0] := 4; arr[2][1] := 5; // 1991 1 11
  arr[3][0] := 4; arr[3][1] := 6; // 1991 11 1
  FDateSplits.Add(7, arr);

  SetLength(arr, 2);
  arr[0][0] := 2; arr[0][1] := 4; // 11 11 1991
  arr[1][0] := 4; arr[1][1] := 6; // 1991 11 11
  FDateSplits.Add(8, arr);
end;

destructor TZxcvbnDateMatcher.Destroy;
begin
  FDateSplits.Free;
  inherited;
end;

function TZxcvbnDateMatcher.CalculateEntropy(AMatch: TZxcvbnDateMatch): Double;
var
  entropy: Double;
  yearSpace: Double;
begin
  yearSpace := Max(Abs(AMatch.year - REFERENCE_YEAR), MIN_YEAR_SPACE);
  entropy := LogN(2, yearSpace * 365);
  if (AMatch.Separator <> '') then
    entropy := entropy + 2;

  Result := entropy;
end;

function TZxcvbnDateMatcher.MapIntsToDmy(AIntegers: TList<Integer>): TZxcvbnDmy;
var
  over12: Integer;
  over31: Integer;
  under1: Integer;
  i: Integer;
  possibleYearSplits: TList<TPair<Integer, TList<Integer>>>;
  itl: TList<Integer>;
  pair: TPair<Integer, TList<Integer>>;
  possibleYearSplitRef: TPair<Integer, TList<Integer>>;
  y: Integer;
  rest: TList<Integer>;
  dm: TZxcvbnDm;
begin
  Result.valid := False;

  if (AIntegers.Items[1] > 31) or
     (AIntegers.Items[1] <= 0) then Exit;

  over12 := 0;
  over31 := 0;
  under1 := 0;
  for i in AIntegers do
  begin
    if (((99 < i) and (i < DATE_MIN_YEAR)) or (i > DATE_MAX_YEAR)) then Exit;

    if (i > 31) then Inc(over31);
    if (i > 12) then Inc(over12);
    if (i <= 0) then Inc(under1);
  end;
  if (over31 >= 2) or (over12 = 3) or (under1 >= 2) then Exit;

  possibleYearSplits := TList<TPair<Integer, TList<Integer>>>.Create;
  try
    itl := TList<Integer>.Create;
    for i := 0 to 1 do
      itl.Add(AIntegers.Items[i]);
    pair := TPair<Integer, TList<Integer>>.Create(AIntegers.Items[2], itl);
    possibleYearSplits.Add(pair);
    itl := TList<Integer>.Create;
    for i := 1 to 2 do
      itl.Add(AIntegers.Items[i]);
    pair := TPair<Integer, TList<Integer>>.Create(AIntegers.Items[0], itl);
    possibleYearSplits.Add(pair);
    for possibleYearSplitRef in possibleYearSplits do
    begin
      y := possibleYearSplitRef.Key;
      rest := possibleYearSplitRef.Value;
      if ((DATE_MIN_YEAR <= y) and (y <= DATE_MAX_YEAR)) then
      begin
        dm := MapIntsToDm(rest);
        if dm.valid then
        begin
          Result.valid := True;
          Result.day := dm.day;
          Result.month := dm.month;
          Result.year := y;
        end else
          Exit;
      end;
    end;

    for possibleYearSplitRef in possibleYearSplits do
    begin
      y := possibleYearSplitRef.Key;
      rest := possibleYearSplitRef.Value;
      dm := MapIntsToDm(rest);
      if dm.valid then
      begin
        y := TwoToFourDigitYear(y);
        Result.valid := True;
        Result.day := dm.day;
        Result.month := dm.month;
        Result.year := y;
      end else
        Exit;
    end;
  finally
    for possibleYearSplitRef in possibleYearSplits do
      possibleYearSplitRef.Value.Free;
    possibleYearSplits.Free;
  end;
end;

function TZxcvbnDateMatcher.MapIntsToDm(AIntegers: TList<Integer>): TZxcvbnDm;
var
  refs: TList<TList<Integer>>;
  copy: TList<Integer>;
  ref: TList<Integer>;
  d, m: Integer;
begin
  Result.valid := False;

  copy := TList<Integer>.Create;
  try
    copy.AddRange(AIntegers);
    copy.Reverse;

    refs := TList<TList<Integer>>.Create;
    try
      refs.Add(AIntegers);
      refs.Add(copy);

      for ref in refs do
      begin
        d := ref.Items[0];
        m := ref.Items[1];
        if (((1 <= d) and (d <= 31)) and ((1 <= m) and (m <= 12))) then
        begin
          Result.valid := True;
          Result.day := d;
          Result.month := m;
          Exit;
        end;
      end;
    finally
      refs.Free;
    end;
  finally
    copy.Free;
  end;
end;

function TZxcvbnDateMatcher.Metric(ACandidate: TZxcvbnDmy): Integer;
begin
  Result := Abs(ACandidate.year - REFERENCE_YEAR);
end;

function TZxcvbnDateMatcher.TwoToFourDigitYear(AYear: Integer): Integer;
begin
  if (AYear > 99) then
    Result := AYear
  else if (AYear > 50) then
    // 87 -> 1987
    Result := AYear + 1900
  else
    // 15 -> 2015
    Result := AYear + 2000;
end;

procedure TZxcvbnDateMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  addMatch: TZxcvbnDateMatch;
  matches: TList<TZxcvbnMatch>;
  curFmt: String;
  fmt: Char;
  fail: Boolean;
  s: String;
  i, j: Integer;
  pSub: String;
  yearLen: Integer;
  prevLen: Integer;
  sep: Char;
  len: Integer;
  year, mon, day: Integer;
  p: Char;
  k, l: Integer;
  token: String;
  noSep: TRegEx;
  candidates: TList<TZxcvbnDmy>;
  arr: TArray<TZxcvbnSplitsArr>;
  date: TZxcvbnSplitsArr;
  ints: TList<Integer>;
  it: Integer;
  dmy: TZxcvbnDmy;
  bestCandidate: TZxcvbnDmy;
  candidate: TZxcvbnDmy;
  minDistance, distance: Integer;
  canIdx: Integer;
  rxMatch: System.RegularExpressions.TMatch;
  targetMatches: TList<TZxcvbnMatch>;
  match, otherMatch: TZxcvbnMatch;
  isSubmatch: Boolean;
begin
  matches := TList<TZxcvbnMatch>.Create;
  try
    for i := 0 to APassword.Length-3 do
    begin
      j := i + 3;
      while (j <= i + 7) do
      begin
        if (j >= APassword.Length) then Break;
        token := APassword.SubString(i, j - i + 1);
        try
          if not TRegEx.IsMatch(token, '^\d{4,8}$') then Continue;

          if FDateSplits.TryGetValue(token.Length, arr) then
          begin
            candidates := TList<TZxcvbnDmy>.Create;
            try
              for date in arr do
              begin
                k := date[0];
                l := date[1];
                ints := TList<Integer>.Create;
                try
                  ints.Add(token.Substring(0, k).ToInteger);
                  ints.Add(token.Substring(k, l - k).ToInteger);
                  ints.Add(token.Substring(l).ToInteger);
                  dmy := MapIntsToDmy(ints);
                  if dmy.valid then
                    candidates.Add(dmy);
                finally
                  ints.Free;
                end;
              end;
              if (candidates.Count = 0) then Continue;

              bestCandidate := candidates[0];
              minDistance := Metric(candidates[0]);
              for candidate in candidates do
              begin
                distance := Metric(candidate);
                if (distance < minDistance) then
                begin
                  bestCandidate := candidate;
                  minDistance := distance;
                end;
              end;
              addMatch := TZxcvbnDateMatch.Create;
              addMatch.Pattern := DatePattern;
              addMatch.Token := token;
              addMatch.i := i;
              addMatch.j := i + token.Length - 1;
              addMatch.Day := bestCandidate.day;
              addMatch.Month := bestCandidate.month;
              addMatch.Year := bestCandidate.year;
              addMatch.Separator := '';
              addMatch.Entropy := CalculateEntropy(addMatch);
              matches.Add(addMatch);
            finally
              candidates.Free;
            end;
          end;
        finally
          Inc(j);
        end;
      end;
    end;

    for i := 0 to APassword.Length-6 do
    begin
      j := i + 5;
      while (j <= i + 9) do
      begin
        if (j >= APassword.Length) then Break;
        token := APassword.SubString(i, j - i + 1);
        try
          rxMatch := TRegEx.Match(token, '^(\d{1,4})([\s\/\\_.-])(\d{1,2})\2(\d{1,4})$');
          if not rxMatch.Success then Continue;

          ints := TList<Integer>.Create;
          try
            ints.Add(rxMatch.Groups[1].Value.ToInteger);
            ints.Add(rxMatch.Groups[3].Value.ToInteger);
            ints.Add(rxMatch.Groups[4].Value.ToInteger);
            dmy := MapIntsToDmy(ints);
            if not dmy.valid then Continue;

            addMatch := TZxcvbnDateMatch.Create;
            addMatch.Pattern := DatePattern;
            addMatch.Token := token;
            addMatch.i := i;
            addMatch.j := i + token.Length - 1;
            addMatch.Day := dmy.day;
            addMatch.Month := dmy.month;
            addMatch.Year := dmy.year;
            addMatch.Separator := rxMatch.Groups[2].Value;
            addMatch.Entropy := CalculateEntropy(addMatch);
            matches.Add(addMatch);
          finally
            ints.Free;
          end;
        finally
          Inc(j);
        end;
      end;
    end;

    // remove submatches
    targetMatches := TList<TZxcvbnMatch>.Create;
    try
      for match in matches do
      begin
        isSubmatch := False;
        for otherMatch in matches do
        begin
          if match.Equals(otherMatch) then Continue;
          if ((otherMatch.i <= match.i) and (otherMatch.j >= match.j)) then
          begin
            isSubmatch := True;
            Break;
          end;
        end;
        if not isSubmatch then targetMatches.Add(match.Clone);
      end;

      for match in matches do
        match.Free;

      AMatches.AddRange(targetMatches);
    finally
      targetMatches.Free;
    end;
  finally
    matches.Free;
  end;
end;

end.
