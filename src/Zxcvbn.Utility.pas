unit Zxcvbn.Utility;

interface
uses
  System.Classes,
  System.SysUtils,
  Zxcvbn.Translation,
  Zxcvbn.Result;

  /// <summary>
  /// Convert a number of seconds into a human readable form. Rounds up.
  /// To be consistent with zxcvbn, it returns the unit + 1 (i.e. 60 * 10 seconds = 10 minutes would come out as "11 minutes"
  /// this is probably to avoid ever needing to deal with plurals
  /// </summary>
  /// <param name="ASeconds">The time in seconds</param>
  /// <param name="ATranslation">The language in which the string is returned</param>
  /// <returns>A human-friendly time string</returns>
  function DisplayTime(ASeconds: Double; ATranslation: TZxcvbnTranslation = ztEnglish): String;

  function GetTranslation(AMatcher: String; ATranslation: TZxcvbnTranslation): String;

  /// <summary>
  /// Reverse a string in one call
  /// </summary>
  /// <param name="AStr">String to reverse</param>
  /// <returns>String in reverse</returns>
  function StringReverse(const AStr: String): String;

  /// <summary>
  /// A convenience for parsing a substring as an int and returning the results. Uses TryStrToInt, and so returns zero where there is no valid int
  /// </summary>
  /// <param name="AStr">String to get substring of</param>
  /// <param name="AStartIndex">Start index of substring to parse</param>
  /// <param name="ALength">Length of substring to parse</param>
  /// <param name="AResult">Substring parsed as int or zero</param>
  /// <returns>True if the parse succeeds</returns>
  function IntParseSubstring(const AStr: String; AStartIndex, ALength: Integer; out AResult: Integer): Boolean;

  /// <summary>
  /// Quickly convert a string to an integer, uses TryStrToInt so any non-integers will return zero
  /// </summary>
  /// <param name="AStr">String to parse into an int</param>
  /// <returns>Parsed int or zero</returns>
  function ToInt(const AStr: String): Integer;

  /// <summary>
  /// Returns a list of the lines of text from an embedded resource in the assembly.
  /// </summary>
  /// <param name="AResourceName">The name of the resource to get the contents of</param>
  /// <returns>A string list of text in the resource or nil if the resource does not exist</returns>
  function GetEmbeddedResourceLines(AResourceName: String): TStringList;

  /// <summary>
  /// Get a translated string of the Warning
  /// </summary>
  /// <param name="AWarning">Warning enum to get the string from</param>
  /// <param name="ATranslation">Language in which to return the string to. Default is English.</param>
  /// <returns>Warning string in the right language</returns>
  function GetWarning(AWarning: TZxcvbnWarning; ATranslation: TZxcvbnTranslation = ztEnglish): String;

  /// <summary>
  /// Get a translated string of the Suggestion
  /// </summary>
  /// <param name="ASuggestion">Suggestion enum to get the string from</param>
  /// <param name="ATranslation">Language in which to return the string to. Default is English.</param>
  /// <returns>Suggestion string in the right language</returns>
  function GetSuggestion(ASuggestion: TZxcvbnSuggestion; ATranslation: TZxcvbnTranslation = ztEnglish): String;

  /// <summary>
  /// Get a translated string of the Suggestion set
  /// </summary>
  /// <param name="ASuggestions">Set of Suggestion enum to get the string from</param>
  /// <param name="ATranslation">Language in which to return the string to. Default is English.</param>
  /// <returns>Suggestions string in the right language</returns>
  function GetSuggestions(ASuggestions: TZxcvbnSuggestions; ATranslation: TZxcvbnTranslation = ztEnglish): String;

implementation
uses
  Winapi.Windows,
  System.StrUtils,
  System.Math;

function DisplayTime(ASeconds: Double; ATranslation: TZxcvbnTranslation = ztEnglish): String;
var
  minute, hour, day, month, year, century: Int64;
begin
  minute := 60;
  hour := minute * 60;
  day := hour * 24;
  month := day * 31;
  year := month * 12;
  century := year * 100;

  if (ASeconds < minute) then Result := GetTranslation('instant', ATranslation)
  else if (ASeconds < hour) then Result := Format('%d %s', [1 + Ceil(ASeconds / minute), GetTranslation('minutes', ATranslation)])
  else if (ASeconds < day) then Result := Format('%d %s', [1 + Ceil(ASeconds / hour), GetTranslation('hours', ATranslation)])
  else if (ASeconds < month) then Result := Format('%d %s', [1 + Ceil(ASeconds / day), GetTranslation('days', ATranslation)])
  else if (ASeconds < year) then Result := Format('%d %s', [1 + Ceil(ASeconds / month), GetTranslation('months', ATranslation)])
  else if (ASeconds < century) then Result := Format('%d %s', [1 + Ceil(ASeconds / year), GetTranslation('years', ATranslation)])
  else Result := GetTranslation('centuries', ATranslation);
end;

function GetTranslation(AMatcher: String; ATranslation: TZxcvbnTranslation): String;
var
  translated: String;
begin
  if AMatcher = 'instant' then
  begin
    case ATranslation of
      ztGerman: translated := 'unmittelbar';
      ztFrench: translated := 'instantané';
      else
        translated := 'instant';
    end;
  end else
  if AMatcher = 'minutes' then
  begin
    case ATranslation of
      ztGerman: translated := 'Minuten';
      ztFrench: translated := 'Minutes';
      else
        translated := 'minutes';
    end;
  end else
  if AMatcher = 'hours' then
  begin
    case ATranslation of
      ztGerman: translated := 'Stunden';
      ztFrench: translated := 'Heures';
      else
        translated := 'hours';
    end;
  end else
  if AMatcher = 'days' then
  begin
    case ATranslation of
      ztGerman: translated := 'Tage';
      ztFrench: translated := 'Journées';
      else
        translated := 'days';
    end;
  end else
  if AMatcher = 'months' then
  begin
    case ATranslation of
      ztGerman: translated := 'Monate';
      ztFrench: translated := 'Mois';
      else
        translated := 'months';
    end;
  end else
  if AMatcher = 'years' then
  begin
    case ATranslation of
      ztGerman: translated := 'Jahre';
      ztFrench: translated := 'Ans';
      else
        translated := 'years';
    end;
  end else
  if AMatcher = 'centuries' then
  begin
    case ATranslation of
      ztGerman: translated := 'Jahrhunderte';
      ztFrench: translated := 'Siècles';
      else
        translated := 'centuries';
    end;
  end else
    translated := AMatcher;

  Result := translated;
end;

function StringReverse(const AStr: String): String;
begin
  Result := ReverseString(AStr);
end;

function IntParseSubstring(const AStr: String; AStartIndex, ALength: Integer; out AResult: Integer): Boolean;
begin
  Result := TryStrToInt(AStr.Substring(AStartIndex, ALength), AResult);
end;

function ToInt(const AStr: String): Integer;
var
  r: Integer;
begin
  r := 0;
  TryStrToInt(AStr, r);
  Result := r;
end;

function GetEmbeddedResourceLines(AResourceName: String): TStringList;
var
  rs: TResourceStream;
  lines: TStringList;
begin
  Result := nil;

  if (FindResource(hInstance, PChar(AResourceName), RT_RCDATA) = 0) then Exit;

  rs := TResourceStream.Create(hInstance, AResourceName, RT_RCDATA);
  try
    lines := TStringList.Create;
    lines.LoadFromStream(rs);
    Result := lines;
  finally
    rs.Free;
  end;
end;

function GetWarning(AWarning: TZxcvbnWarning; ATranslation: TZxcvbnTranslation = ztEnglish): String;
var
  translated: String;
begin
  case AWarning of
    zwStraightRow:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Straight rows of keys are easy to guess';
      end;

    zwShortKeyboardPatterns:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Short keyboard patterns are easy to guess';
      end;

    zwRepeatsLikeAaaEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Repeats like "aaa" are easy to guess';
      end;

    zwRepeatsLikeAbcSlighterHarder:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"';
      end;

    zwSequenceAbcEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Sequences like abc or 6543 are easy to guess';
      end;

    zwRecentYearsEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Recent years are easy to guess';
      end;

    zwDatesEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Dates are often easy to guess';
      end;

    zwTop10Passwords:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'This is a top-10 common password';
      end;

    zwTop100Passwords:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'This is a top-100 common password';
      end;

    zwCommonPasswords:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'This is a very common password';
      end;

    zwSimilarCommonPasswords:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'This is similar to a commonly used password';
      end;

    zwWordEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'A word by itself is easy to guess';
      end;

    zwNameSurnamesEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Names and surnames by themselves are easy to guess';
      end;

    zwCommonNameSurnamesEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Common names and surnames are easy to guess';
      end;

    zwEmpty:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := '';
      end;

    else
      translated := '';
  end;

  Result := translated;
end;

function GetSuggestion(ASuggestion: TZxcvbnSuggestion; ATranslation: TZxcvbnTranslation = ztEnglish): String;
var
  translated: String;
begin
  case ASuggestion of
    zsAddAnotherWordOrTwo:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Add another word or two. Uncommon words are better.';
      end;

    zsUseLongerKeyboardPattern:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Use a longer keyboard pattern with more turns';
      end;

    zsAvoidRepeatedWordsAndChars:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Avoid repeated words and characters';
      end;

    zsAvoidSequences:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Avoid sequences';
      end;

    zsAvoidYearsAssociatedYou:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Avoid recent years '+#10+' Avoid years that are associated with you';
      end;

    zsAvoidDatesYearsAssociatedYou:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Avoid dates and years that are associated with you';
      end;

    zsCapsDontHelp:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Capitalization doesn''t help very much';
      end;

    zsAllCapsEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'All-uppercase is almost as easy to guess as all-lowercase';
      end;

    zsReversedWordEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Reversed words aren''t much harder to guess';
      end;

    zsPredictableSubstitutionsEasy:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := 'Predictable substitutions like ''@'' instead of ''a'' don''t help very much';
      end;

    zsEmpty:
      case ATranslation of
        ztGerman:  translated := '';
        ztFrench:  translated := '';
        else
          translated := '';
      end;
    else
      translated := 'Use a few words, avoid common phrases '+#10+' No need for symbols, digits, or uppercase letters';
  end;

  Result := translated;
end;

function GetSuggestions(ASuggestions: TZxcvbnSuggestions; ATranslation: TZxcvbnTranslation = ztEnglish): String;
var
  suggestion: TZxcvbnSuggestion;
  suggestions: String;
begin
  suggestions := '';
  for suggestion in ASuggestions do
    suggestions := suggestions + GetSuggestion(suggestion, ATranslation) + #10;

  Result := suggestions;
end;

end.
