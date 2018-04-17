/// <summary>
/// Some useful shared functions used for evaluating passwords
/// </summary>
unit Zxcvbn.PasswordScoring;

interface
uses
  System.Classes, System.SysUtils, System.RegularExpressions;

const
  StartUpper = '^[A-Z][^A-Z]+$';
  EndUpper = '^[^A-Z]+[A-Z]$';
  AllUpper = '^[^a-z]+$';
  AllLower = '^[^A-Z]+$';

  /// <summary>
  /// Calculate the cardinality of the minimal character sets necessary to brute force the password (roughly)
  /// (e.g. lowercase = 26, numbers = 10, lowercase + numbers = 36)
  /// </summary>
  /// <param name="password">THe password to evaluate</param>
  /// <returns>An estimation of the cardinality of charactes for this password</returns>
  function PasswordCardinality(APassword: String): Integer;

  /// <summary>
  /// Calculate a rough estimate of crack time for entropy, see zxcbn scoring.coffee for more information on the model used
  /// </summary>
  /// <param name="entropy">Entropy of password</param>
  /// <returns>An estimation of seconts taken to crack password</returns>
  function EntropyToCrackTime(AEntropy: Double): Double;

  /// <summary>
  /// Return a score for password strength from the crack time. Scores are 0..4, 0 being minimum and 4 maximum strength.
  /// </summary>
  /// <param name="crackTimeSeconds">Number of seconds estimated for password cracking</param>
  /// <returns>Password strength. 0 to 4, 0 is minimum</returns>
  function CrackTimeToScore(ACrackTimeSeconds: Double): Integer;

  /// <summary>
  /// Caclulate binomial coefficient (i.e. nCk)
  /// Uses same algorithm as zxcvbn (cf. scoring.coffee), from http://blog.plover.com/math/choose.html
  /// </summary>
  /// <param name="k">k</param>
  /// <param name="n">n</param>
  /// <returns>Binomial coefficient; nCk</returns>
  function Binomial(n, k: Integer): Integer;

  /// <summary>
  /// Estimate the extra entropy in a token that comes from mixing upper and lowercase letters.
  /// This has been moved to a static function so that it can be used in multiple entropy calculations.
  /// </summary>
  /// <param name="word">The word to calculate uppercase entropy for</param>
  /// <returns>An estimation of the entropy gained from casing in <paramref name="word"/></returns>
  function CalculateUppercaseEntropy(AWord: String): Double;

implementation
uses
  Winapi.Windows, System.Math;

function PasswordCardinality(APassword: String): Integer;
var
  cl: Integer;
  i: Integer;
  c: Char;
  charType: Integer;
begin
  cl := 0;
  charType := 0;

  for i := 1 to APassword.Length do
  begin
    c := APassword[i];
    if CharInSet(c, ['a'..'z']) then charType := charType or 1 // Lowercase
    else if CharInSet(c, ['A'..'Z']) then charType := charType or 2 // Uppercase
    else if CharInSet(c, ['0'..'9']) then charType := charType or 4 // Numbers
    else if (c <= '/') or
       ((':' <= c) and (c <= '@')) or
       (('[' <= c) and (c <= '`')) or
       (('{' <= c) and (Ord(c) <= $7F)) then charType := charType or 8 // Symbols
    else if Ord(c) > $7F then charType := charType or 16; // 'Unicode'
  end;

  if (charType and 1) = 1   then cl := cl + 26;
  if (charType and 2) = 2   then cl := cl + 26;
  if (charType and 4) = 4   then cl := cl + 10;
  if (charType and 8) = 8   then cl := cl + 33;
  if (charType and 16) = 16 then cl := cl + 100;

  Result := cl;
end;

function EntropyToCrackTime(AEntropy: Double): Double;
const
  SingleGuess: Double = 0.01;
  NumAttackers: Double = 100;
var
  SecondsPerGuess: Double;
begin
  SecondsPerGuess := SingleGuess / NumAttackers;

  Result := 0.5 * Power(2, AEntropy) * SecondsPerGuess;
end;

function CrackTimeToScore(ACrackTimeSeconds: Double): Integer;
begin
  if (ACrackTimeSeconds < Power(10, 2)) then Result := 0
  else if (ACrackTimeSeconds < Power(10, 4)) then Result := 1
  else if (ACrackTimeSeconds < Power(10, 6)) then Result := 2
  else if (ACrackTimeSeconds < Power(10, 8)) then Result := 3
  else Result := 4;
end;

function Binomial(n, k: Integer): Integer;
var
  d: Integer;
begin
  if k > n then
  begin
    Result := 0;
    Exit;
  end;
  if k = 0 then
  begin
    Result := 1;
    Exit;
  end;

  if k > n - k then
    k := n - k;
  Result := 1;
  d := 0;
  while d < k do
  begin
    Result := Result * (n - d);
    Inc(d);
    Result := Result div d;
  end;
end;

function CalculateUppercaseEntropy(AWord: String): Double;
var
  lowers, uppers: Integer;
  i: Integer;
  sum: Double;
begin
  Result := 0;
  if TRegEx.IsMatch(AWord, AllLower) then Exit;

  // If the word is all uppercase add's only one bit of entropy, add only one bit for initial/end single cap only
  if TRegEx.IsMatch(AWord, StartUpper) or
     TRegEx.IsMatch(AWord, EndUpper) or
     TRegEx.IsMatch(AWord, AllUpper) then
  begin
    Result := 1;
    Exit;
  end;

  lowers := 0;
  uppers := 0;
  for i := 1 to AWord.Length do
  begin
    if CharInSet(AWord[i], ['a'..'z']) then Inc(lowers)
    else if CharInSet(AWord[i], ['A'..'Z']) then Inc(uppers);
  end;

  // Calculate numer of ways to capitalise (or inverse if there are fewer lowercase chars) and return lg for entropy
  sum := 0;
  for i := 0 to Min(uppers, lowers) do
    sum := sum + Binomial(uppers + lowers, i);

  Result := LogN(2, sum);
end;

end.
