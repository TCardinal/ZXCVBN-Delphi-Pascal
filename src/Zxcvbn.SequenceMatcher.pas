unit Zxcvbn.SequenceMatcher;

interface
uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Zxcvbn.Matcher,
  Zxcvbn.Result;

type
  TZxcvbnSequenceMatch = class;

  /// <summary>
  /// This matcher detects lexicographical sequences (and in reverse) e.g. abcd, 4567, PONML etc.
  /// </summary>
  TZxcvbnSequenceMatcher = class(TInterfacedObject, IZxcvbnMatcher)

    // Sequences should not overlap, sequences here must be ascending, their reverses will be checked automatically
    const Sequences: array[0..2] of String = (
      'abcdefghijklmnopqrstuvwxyz',
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      '01234567890');

    const SequenceNames: array[0..2] of String = (
      'lower',
      'upper',
      'digits');

    const
      SequencePattern = 'sequence';
  private
    function CalculateEntropy(AMatch: String; AAscending: Boolean): Double;
  public
    /// <summary>
    /// Find matching sequences in <paramref name="APassword"/> and adds them to <paramref name="AMatches"/>
    /// </summary>
    /// <param name="APassword">The password to check</param>
    /// <param name="AMatches"></param>
    /// <seealso cref="SequenceMatch"/>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
  end;

  /// <summary>
  /// A match made using the <see cref="TZxcvbnSequenceMatcher"/> containing some additional sequence information.
  /// </summary>
  TZxcvbnSequenceMatch = class(TZxcvbnMatch)
  public
    /// <summary>
    /// The name of the sequence that the match was found in (e.g. 'lower', 'upper', 'digits')
    /// </summary>
    SequenceName: String;

    /// <summary>
    /// The size of the sequence the match was found in (e.g. 26 for lowercase letters)
    /// </summary>
    SequenceSize: Integer;

    /// <summary>
    /// Whether the match was found in ascending order (cdefg) or not (zyxw)
    /// </summary>
    Ascending: Boolean;

    procedure CopyTo(AMatch: TZxcvbnSequenceMatch);
  end;

implementation
uses
  System.Math,
  Zxcvbn.Utility;

{ TZxcvbnSequenceMatch }

procedure TZxcvbnSequenceMatch.CopyTo(AMatch: TZxcvbnSequenceMatch);
begin
  AMatch.SequenceName := Self.SequenceName;
  AMatch.SequenceSize := Self.SequenceSize;
  AMatch.Ascending := Self.Ascending;
end;

{ TZxcvbnSequenceMatcher }

function TZxcvbnSequenceMatcher.CalculateEntropy(AMatch: String; AAscending: Boolean): Double;
var
  firstChar: Char;
  baseEntropy: Double;
begin
  firstChar := AMatch[1];

  // XXX: This entropy calculation is hard coded, ideally this would (somehow) be derived from the sequences above
  if ((firstChar = 'a') or (firstChar = '1')) then baseEntropy := 1
  else if (('0' <= firstChar) and (firstChar <= '9')) then baseEntropy := LogN(2, 10) // Numbers
  else if (('a' <= firstChar) and (firstChar <= 'z')) then baseEntropy := LogN(2, 26) // Lowercase
  else baseEntropy := LogN(1, 26) + 1; // + 1 for uppercase

  if (not AAscending) then baseEntropy := baseEntropy + 1; // Descending instead of ascending give + 1 bit of entropy

  Result := baseEntropy + LogN(2, AMatch.Length);
end;

procedure TZxcvbnSequenceMatcher.MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
var
  seqs: TStringList;
  s: String;
  matches: TList<TZxcvbnMatch>;
  i, j: Integer;
  seq: String;
  ixI, ixJ: Integer;
  ascending: Boolean;
  startIndex: Integer;
  len: Integer;
  seqIndex: Integer;
  addMatch: TZxcvbnSequenceMatch;
  match: String;
begin
  seqs := TStringList.Create;
  try
    // Sequences to check should be the set of sequences and their reverses (i.e. want to match "abcd" and "dcba")
    for s in Sequences do
      seqs.Add(s);
    for s in Sequences do
      seqs.Add(StringReverse(s));

    matches := TList<TZxcvbnMatch>.Create;
    try
      i := 0;
      while i < APassword.Length - 1 do
      begin
        j := i + 1;

        seq := '';
        // Find a sequence that the current and next characters could be part of
        for s in seqs do
        begin
          ixI := s.IndexOf(APassword[i+1]);
          ixJ := s.IndexOf(APassword[j+1]);
          if (ixJ = ixI + 1) then
          begin
            seq := s;
            Break;
          end;
        end;

        // This isn't an ideal check, but we want to know whether the sequence is ascending/descending to keep entropy
        //   calculation consistent with zxcvbn
        ascending := False;
        for s in Sequences do
        begin
          if (seq = s) then
          begin
            ascending := True;
            Break;
          end;
        end;

        // seq will be empty when there are no matching sequences
        if (seq <> '') then
        begin
          startIndex := seq.IndexOf(APassword[i+1]);

          // Find length of matching sequence (j should be the character after the end of the matching subsequence)
          while (j < APassword.Length) and (startIndex + j - i < seq.Length) and (seq[startIndex + j - i+1] = APassword[j+1]) do
          begin
            Inc(j);
          end;

          len := j - i;

          // Only want to consider sequences that are longer than two characters
          if (len > 2) then
          begin
            // Find the sequence index so we can match it up with its name
            seqIndex := seqs.IndexOf(seq);
            if (seqIndex >= Length(Sequences)) then seqIndex := seqIndex - Length(Sequences); // match reversed sequence with its original

            match := APassword.Substring(i, len);

            addMatch := TZxcvbnSequenceMatch.Create;
            addMatch.i := i;
            addMatch.j := j - 1;
            addMatch.Token := match;
            addMatch.Pattern := SequencePattern;
            addMatch.Entropy := CalculateEntropy(match, ascending);
            addMatch.Ascending := ascending;
            addMatch.SequenceName := SequenceNames[seqIndex];
            addMatch.SequenceSize := Sequences[seqIndex].Length;
            matches.Add(addMatch);
          end;
        end;

        i := j;
      end;

      AMatches.AddRange(matches);
    finally
      matches.Free;
    end;
  finally
    seqs.Free;
  end;
end;

end.
