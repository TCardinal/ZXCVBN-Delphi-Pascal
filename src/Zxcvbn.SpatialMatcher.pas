unit Zxcvbn.SpatialMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  TZxcvbnSpatialMatch = class;

  TZxcvbnPoint = record
    x: Integer;
    y: Integer;
    procedure ZxcvbnPoint(Ax, Ay: Integer);
    function ToString: String;
  end;
  TZxcvbnPoints = array of TZxcvbnPoint;

  // See build_keyboard_adjacency_graph.py in zxcvbn for how these are generated
  TZxcvbnSpatialGraph = class
  private
    FName: String;
    FAdjacencyGraph: TObjectDictionary<Char, TStringList>;
    FStartingPositions: Integer;
    FAverageDegree: Double;

    function GetSlantedAdjacent(Ac: TZxcvbnPoint): TZxcvbnPoints;
    function GetAlignedAdjacent(Ac: TZxcvbnPoint): TZxcvbnPoints;
    procedure BuildGraph(ALayout: String; ASlanted: Boolean; ATokenSize: Integer);
  public
    property Name: String read FName;
    property StartingPositions: Integer read FStartingPositions;
    property AverageDegree: Double read FAverageDegree;

    constructor Create(AName: String; ALayout: String; ASlanted: Boolean; ATokenSize: Integer);

    destructor Destroy; override;

    /// <summary>
    /// Returns true when ATestAdjacent is in Ac's adjacency list
    /// </summary>
    function IsCharAdjacent(Ac: Char; ATestAdjacent: Char): Boolean;

    /// <summary>
    /// Returns the 'direction' of the adjacent character (i.e. index in the adjacency list).
    /// If the character is not adjacent, -1 is returned
    ///
    /// Uses the 'shifted' out parameter to let the caller know if the matched character is shifted
    /// </summary>
    function GetAdjacentCharDirection(Ac: Char; AAdjacent: Char; out AShifted: Boolean): Integer;

    /// <summary>
    /// Calculate entropy for a math that was found on this adjacency graph
    /// </summary>
    function CalculateEntropy(AMatchLength: Integer; ATurns: Integer; AShiftedCount: Integer): Double;
  end;

  /// <summary>
  /// <para>A matcher that checks for keyboard layout patterns (e.g. 78523 on a keypad, or plkmn on a QWERTY keyboard).</para>
  /// <para>Has patterns for QWERTY, DVORAK, numeric keybad and mac numeric keypad</para>
  /// <para>The matcher accounts for shifted characters (e.g. qwErt or po9*7y) when detecting patterns as well as multiple changes in direction.</para>
  /// </summary>
  TZxcvbnSpatialMatcher = class(TInterfacedObject, IZxcvbnMatcher)
  const
    SpatialPattern = 'spatial';
  private
    FSpatialGraphs: TObjectList<TZxcvbnSpatialGraph>;

    /// <summary>
    /// Match the password against a single pattern and adds matching patterns to AMatches
    /// </summary>
    /// <param name="AGraph">Adjacency graph for this key layout</param>
    /// <param name="APassword">Password to match</param>
    /// <param name="AMatches"></param>
    procedure SpatialMatch(AGraph: TZxcvbnSpatialGraph; APassword: String; var AMatches: TList<TZxcvbnMatch>);

    // In the JS version these are precomputed, but for now we'll generate them here when they are first needed.
    function GenerateSpatialGraphs: TObjectList<TZxcvbnSpatialGraph>;
  public
    /// <summary>
    /// Match the password against the known keyboard layouts and adds matches to AMatches
    /// </summary>
    /// <param name="APassword">Password to match</param>
    /// <param name="AMatches"></param>
    /// <seealso cref="TZxcvbnSpatialMatch"/>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);

    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  /// A match made with the <see cref="TZxcvbnSpatialMatcher"/>. Contains additional information specific to spatial matches.
  /// </summary>
  TZxcvbnSpatialMatch = class(TZxcvbnMatch)
  public
    /// <summary>
    /// The name of the keyboard layout used to make the spatial match
    /// </summary>
    Graph: String;

    /// <summary>
    /// The number of turns made (i.e. when diretion of adjacent keys changes)
    /// </summary>
    Turns: Integer;

    /// <summary>
    /// The number of shifted characters matched in the pattern (adds to entropy)
    /// </summary>
    ShiftedCount: Integer;

    procedure CopyTo(AMatch: TZxcvbnSpatialMatch);
  end;

implementation
uses
  System.Math,
  System.StrUtils,
  Zxcvbn.PasswordScoring,
  Zxcvbn.Utility;

{ TZxcvbnPoint }

procedure TZxcvbnPoint.ZxcvbnPoint(Ax, Ay: Integer);
begin
  x := Ax;
  y := Ay;
end;

function TZxcvbnPoint.ToString: String;
begin
  Result := '{' + IntToStr(x) + ', ' + IntToStr(y) + '}';
end;

{ TZxcvbnSpatialGraph }

constructor TZxcvbnSpatialGraph.Create(AName: String; ALayout: String; ASlanted: Boolean; ATokenSize: Integer);
begin
  FName := AName;
  BuildGraph(ALayout, ASlanted, ATokenSize);
end;

destructor TZxcvbnSpatialGraph.Destroy;
begin
  if Assigned(FAdjacencyGraph) then
    FAdjacencyGraph.Free;
  inherited;
end;

function TZxcvbnSpatialGraph.IsCharAdjacent(Ac: Char; ATestAdjacent: Char): Boolean;
var
  s: String;
begin
  Result := False;
  if FAdjacencyGraph.ContainsKey(Ac) then
  begin
    for s in FAdjacencyGraph[Ac] do
    begin
      Result := s.Contains(ATestAdjacent);
      if Result then Exit;
    end;
  end;
end;

function TZxcvbnSpatialGraph.GetAdjacentCharDirection(Ac: Char; AAdjacent: Char; out AShifted: Boolean): Integer;
var
  adjacentEntry: String;
  s: String;
begin
  AShifted := False;
  Result := -1;

  if not FAdjacencyGraph.ContainsKey(Ac) then Exit;

  adjacentEntry := '';
  for s in FAdjacencyGraph[Ac] do
  begin
    if s.Contains(AAdjacent) then
      adjacentEntry := s;
  end;
  if (adjacentEntry = '') then Exit;

  AShifted := adjacentEntry.IndexOf(AAdjacent) > 0; // i.e. shifted if not first character in the adjacency
  Result := FAdjacencyGraph[Ac].IndexOf(adjacentEntry);
end;

function TZxcvbnSpatialGraph.GetSlantedAdjacent(Ac: TZxcvbnPoint): TZxcvbnPoints;
var
  x, y: Integer;
begin
  x := Ac.x;
  y := Ac.y;

  SetLength(Result, 6);
  Result[0].ZxcvbnPoint(x - 1, y);
  Result[1].ZxcvbnPoint(x, y - 1);
  Result[2].ZxcvbnPoint(x + 1, y - 1);
  Result[3].ZxcvbnPoint(x + 1, y);
  Result[4].ZxcvbnPoint(x, y + 1);
  Result[5].ZxcvbnPoint(x - 1, y + 1);
end;

function TZxcvbnSpatialGraph.GetAlignedAdjacent(Ac: TZxcvbnPoint): TZxcvbnPoints;
var
  x, y: Integer;
begin
  x := Ac.x;
  y := Ac.y;

  SetLength(Result, 8);
  Result[0].ZxcvbnPoint(x - 1, y);
  Result[1].ZxcvbnPoint(x - 1, y - 1);
  Result[2].ZxcvbnPoint(x, y - 1);
  Result[3].ZxcvbnPoint(x + 1, y - 1);
  Result[4].ZxcvbnPoint(x + 1, y);
  Result[5].ZxcvbnPoint(x + 1, y + 1);
  Result[6].ZxcvbnPoint(x, y + 1);
  Result[7].ZxcvbnPoint(x - 1, y + 1);
end;

procedure TZxcvbnSpatialGraph.BuildGraph(ALayout: String; ASlanted: Boolean; ATokenSize: Integer);
var
  positionTable: TDictionary<TZxcvbnPoint, String>;
  x, y: Integer;
  p: TZxcvbnPoint;
  lines: TStringList;
  slant: Integer;
  token: String;
  trimLine: String;
  i: Integer;
  tokens: TStrings;
  pair: TPair<TZxcvbnPoint, String>;
  c: Char;
  adjacentPoints: TZxcvbnPoints;
  adjacent: TZxcvbnPoint;
  sum: Integer;
  sl: TStringList;
  s: String;
  ss: TStringList;
begin
  positionTable := TDictionary<TZxcvbnPoint, String>.Create;
  try
    lines := TStringList.Create;
    try
      lines.Text := ALayout;
      for y := 0 to lines.Count-1 do
      begin
        if ASlanted then
          slant := y-1
        else
          slant := 0;

        tokens := TStringList.Create;
        try
          trimLine := StringReplace(lines[y], #32, '', [rfReplaceAll]);
          for i := 1 to trimLine.Length do
          begin
            if (ATokenSize = 1) then
              tokens.Add(trimLine[i])
            else
              if (i > 0) and (i mod ATokenSize = 0) then
                tokens.Add(trimLine[i-1]+trimLine[i]);
          end;
          for i := 0 to tokens.Count-1 do
          begin
            if Trim(tokens[i]).IsEmpty then Continue;

            x := (lines[y].IndexOf(tokens[i]) - slant) div (ATokenSize + 1);
            p.ZxcvbnPoint(x, y);
            positionTable.Add(p, tokens[i]);
          end;
        finally
          tokens.Free;
        end;
      end;

      FAdjacencyGraph := TObjectDictionary<Char, TStringList>.Create([doownsvalues]);
      for pair in positionTable do
      begin
        p := pair.Key;
        for c in pair.Value do
        begin
          FAdjacencyGraph.Add(c, TStringList.Create);
          if ASlanted then
            adjacentPoints := GetSlantedAdjacent(p)
          else
            adjacentPoints := GetAlignedAdjacent(p);

          for adjacent in adjacentPoints do
          begin
            // We want to include nulls so that direction is correspondent with index in the list
            if (positionTable.ContainsKey(adjacent)) then
              FAdjacencyGraph[c].Add(positionTable[adjacent])
            else
              FAdjacencyGraph[c].Add('');
          end;
        end;
      end;

      // Calculate average degree and starting positions, cf. init.coffee
      FStartingPositions := FAdjacencyGraph.Count;
      sum := 0;
      for sl in FAdjacencyGraph.Values do
      begin
        for s in sl do
          if not s.IsEmpty then Inc(sum);
      end;
      FAverageDegree := sum / StartingPositions;
    finally
      lines.Free;
    end;
  finally
    positionTable.Free;
  end;
end;

function TZxcvbnSpatialGraph.CalculateEntropy(AMatchLength: Integer; ATurns: Integer; AShiftedCount: Integer): Double;
var
  possibilities: Double;
  i, j: Integer;
  possible_turns: Integer;
  entropy: Double;
  unshifted: Integer;
  sum: Double;
begin
  possibilities := 0;
  // This is an estimation of the number of patterns with length of matchLength or less with turns turns or less
  for i := 2 to AMatchLength do
  begin
    possible_turns := Min(ATurns, i - 1);
    for j := 1 to possible_turns do
      possibilities := possibilities +
        (StartingPositions * Power(AverageDegree, j) * Zxcvbn.PasswordScoring.Binomial(i - 1, j - 1));
  end;

  entropy := LogN(2, possibilities);

  // Entropy increaeses for a mix of shifted and unshifted
  if (AShiftedCount > 0) then
  begin
    unshifted := AMatchLength - AShiftedCount;
    sum := 0;
    for i := 0 to Min(AShiftedCount, unshifted) + 1 do
      sum := sum + Zxcvbn.PasswordScoring.Binomial(AMatchLength, i);
    entropy := entropy + LogN(2, sum);
  end;

  Result := entropy;
end;

{ TZxcvbnSpatialMatch }

procedure TZxcvbnSpatialMatch.CopyTo(AMatch: TZxcvbnSpatialMatch);
begin
  AMatch.Graph := Self.Graph;
  AMatch.Turns := Self.Turns;
  AMatch.ShiftedCount := Self.ShiftedCount;
end;

{ TZxcvbnSpatialMatcher }

constructor TZxcvbnSpatialMatcher.Create;
begin
  FSpatialGraphs := GenerateSpatialGraphs;
end;

destructor TZxcvbnSpatialMatcher.Destroy;
begin
  if Assigned(FSpatialGraphs) then
    FSpatialGraphs.Free;
  inherited;
end;

procedure TZxcvbnSpatialMatcher.SpatialMatch(AGraph: TZxcvbnSpatialGraph; APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  i, j: Integer;
  turns: Integer;
  shiftedCount: Integer;
  lastDirection: Integer;
  shifted: Boolean;
  addMatch: TZxcvbnSpatialMatch;
  foundDirection: Integer;
  matches: TList<TZxcvbnMatch>;
begin
  matches := TList<TZxcvbnMatch>.Create;
  try
    i := 0;
    while (i < APassword.Length - 1) do
    begin
      turns := 0;
      shiftedCount := 0;
      lastDirection := -1;

      j := i + 1;
      while j < APassword.Length do
      begin
        foundDirection := AGraph.GetAdjacentCharDirection(APassword[j], APassword[j+1], shifted);

        if (foundDirection <> -1) then
        begin
          // Spatial match continues
          if shifted then Inc(shiftedCount);
          if (lastDirection <> foundDirection) then
          begin
            Inc(turns);
            lastDirection := foundDirection;
          end;
        end else
          Break; // This character not a spatial match

        Inc(j);
      end;

      // Only consider runs of greater than two
      if (j - i > 2) then
      begin
        addMatch := TZxcvbnSpatialMatch.Create;
        addMatch.Pattern := SpatialPattern;
        addMatch.i := i;
        addMatch.j := j - 1;
        addMatch.Token := APassword.Substring(i, j - i);
        addMatch.Graph := AGraph.Name;
        addMatch.Entropy := AGraph.CalculateEntropy(j - i, turns, shiftedCount);
        addMatch.Turns := turns;
        addMatch.ShiftedCount := shiftedCount;
        matches.Add(addMatch);
      end;

      i := j;
    end;

    AMatches.AddRange(matches);
  finally
    matches.Free;
  end;
end;

function TZxcvbnSpatialMatcher.GenerateSpatialGraphs: TObjectList<TZxcvbnSpatialGraph>;

  // Keyboard layouts
  const qwerty =
    '`~ 1! 2@ 3# 4$ 5% 6^ 7& 8* 9( 0) -_ =+'+#10+
    '    qQ wW eE rR tT yY uU iI oO pP [{ ]} \|'+#10+
    '     aA sS dD fF gG hH jJ kK lL ;: ''"'+#10+
    '      zZ xX cC vV bB nN mM ,< .> /?';

  const dvorak =
    '`~ 1! 2@ 3# 4$ 5% 6^ 7& 8* 9( 0) [{ ]}'+#10+
    '    ''" ,< .> pP yY fF gG cC rR lL /? =+ \|'+#10+
    '     aA oO eE uU iI dD hH tT nN sS -_'+#10+
    '      ;: qQ jJ kK xX bB mM wW vV zZ';

  const keypad =
    '  / * -'+#10+
    '7 8 9 +'+#10+
    '4 5 6'+#10+
    '1 2 3'+#10+
    '  0 .';

  const mac_keypad =
    '  = / *'+#10+
    '7 8 9 -'+#10+
    '4 5 6 +'+#10+
    '1 2 3'+#10+
    '  0 .';

begin
  Result := TObjectList<TZxcvbnSpatialGraph>.Create;

  Result.Add(TZxcvbnSpatialGraph.Create('qwerty', qwerty, True, 2));
  Result.Add(TZxcvbnSpatialGraph.Create('dvorak', dvorak, True, 2));
  Result.Add(TZxcvbnSpatialGraph.Create('keypad', keypad, False, 1));
  Result.Add(TZxcvbnSpatialGraph.Create('mac_keypad', mac_keypad, False, 1));
end;

procedure TZxcvbnSpatialMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  spatialGraph: TZxcvbnSpatialGraph;
begin
  for spatialGraph in FSpatialGraphs do
    SpatialMatch(spatialGraph, APassword, AMatches);
end;

end.
