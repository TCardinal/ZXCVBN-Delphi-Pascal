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

  function GetTranslation(const AMatcher: string; const ATranslation: TZxcvbnTranslation): String;

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

function GetTranslation(const AMatcher: String; const ATranslation: TZxcvbnTranslation): String;
var
	i: Integer;

const
	deDE: array[0..31, 0..1] of string = (
			//Crack times
			('instant',   'unmittelbar'),
			('minutes',   'Minuten'),
			('hours',     'Stunden'),
			('days',      'Tage'),
			('months', 		'Monate'),
			('years',     'Jahre'),
			('centuries', 'Jahrhunderte'),

			//Warnings
			('Straight rows of keys are easy to guess', 'Gerade Reihen von Tasten sind leicht zu erraten'),
			('Short keyboard patterns are easy to guess', 'Kurze Tastaturmuster sind leicht zu erraten'),
			('Repeats like "aaa" are easy to guess', 'Wiederholungen wie "aaa" sind leicht zu erraten'),
			('Repeats like "abcabcabc" are only slightly harder to guess than "abc"', 'Wiederholungen wie "abcabcabc" sind nur etwas schwerer zu erraten als "abc"'),
			('Sequences like abc or 6543 are easy to guess', 'Sequenzen wie abc oder 6543 sind leicht zu erraten'),
			('Recent years are easy to guess', 'Die letzten Jahre sind leicht zu erraten'),
			('Dates are often easy to guess', 'Termine sind oft leicht zu erraten'),
			('This is a top-10 common password', 'Dies ist ein Top-10-Passwort'),
			('This is a top-100 common password', 'Dies ist ein Top-100-Passwort'),
			('This is a very common password', 'Dies ist ein sehr häufiges Passwort'),
			('This is similar to a commonly used password', 'Dies ähnelt einem häufig verwendeten Passwort'),
			('A word by itself is easy to guess', 'Ein Wort an sich ist leicht zu erraten'),
			('Names and surnames by themselves are easy to guess', 'Namen und Familiennamen sind leicht zu erraten'),
			('Common names and surnames are easy to guess', 'Allgemeine Namen und Nachnamen sind leicht zu erraten'),

			//Suggestions
			('Add another word or two. Uncommon words are better.', 'Fügen Sie ein oder zwei weitere Wörter hinzu. Ungewöhnliche Wörter sind besser.'),
			('Use a longer keyboard pattern with more turns', 'Verwenden Sie ein längeres Tastaturmuster mit mehr Drehungen'),
			('Avoid repeated words and characters', 'Vermeiden Sie wiederholte Wörter und Zeichen'),
			('Avoid sequences', 'Vermeiden Sie Sequenzen'),
			('Avoid recent years '+#10+' Avoid years that are associated with you', 'Vermeide die letzten Jahre'+#10+'Vermeiden Sie Jahre, die mit Ihnen verbunden sind'),
			('Avoid dates and years that are associated with you', 'Vermeiden Sie Daten und Jahre, die mit Ihnen verbunden sind'),
			('Capitalization doesn''t help very much', 'Die Großschreibung hilft nicht sehr'),
			('All-uppercase is almost as easy to guess as all-lowercase', 'Großbuchstaben sind fast so einfach zu erraten wie Kleinbuchstaben'),
			('Reversed words aren''t much harder to guess', 'Umgekehrte Wörter sind nicht viel schwerer zu erraten'),
			('Predictable substitutions like "@" instead of "a" don''t help very much', 'Vorhersehbare Substitutionen wie "@" anstelle von "a" helfen nicht sehr'),
			('Use a few words, avoid common phrases '+#10+' No need for symbols, digits, or uppercase letters', 'Verwenden Sie ein paar Wörter, vermeiden Sie häufige Phrasen'+#10+'Keine Notwendigkeit für Symbole, Ziffern oder Großbuchstaben')
	);

	frFR: array[0..31, 0..1] of string = (
			//Crack times
			('instant',   'instantané'),
			('minutes',   'Minutes'),
			('hours',     'Heures'),
			('days',      'Journées'),
			('months', 		'mois'),
			('years',     'Ans'),
			('centuries', 'Siècles'),

			//Warnings
			('Straight rows of keys are easy to guess', 'Des rangées droites de touches sont faciles à deviner'),
			('Short keyboard patterns are easy to guess', 'Les raccourcis clavier sont faciles à deviner'),
			('Repeats like "aaa" are easy to guess', 'Des répétitions comme "aaa" sont faciles à deviner'),
			('Repeats like "abcabcabc" are only slightly harder to guess than "abc"', 'Les répétitions comme "abcabcabc" ne sont que légèrement plus difficiles à deviner que "abc"'),
			('Sequences like abc or 6543 are easy to guess', 'Des séquences comme abc ou 6543 sont faciles à deviner'),
			('Recent years are easy to guess', 'Les dernières années sont faciles à deviner'),
			('Dates are often easy to guess', 'Les dates sont souvent faciles à deviner'),
			('This is a top-10 common password', 'Ceci est un mot de passe commun top-10'),
			('This is a top-100 common password', 'Ceci est un mot de passe commun parmi les 100 premiers'),
			('This is a very common password', 'Ceci est un mot de passe très courant'),
			('This is similar to a commonly used password', 'Ceci est similaire à un mot de passe couramment utilisé'),
			('A word by itself is easy to guess', 'Un mot en soi est facile à deviner'),
			('Names and surnames by themselves are easy to guess', 'Les noms et prénoms sont faciles à deviner'),
			('Common names and surnames are easy to guess', 'Les noms et prénoms communs sont faciles à deviner'),

			('Add another word or two. Uncommon words are better.', 'Ajouter un autre mot ou deux. Les mots peu communs sont meilleurs.'),
			('Use a longer keyboard pattern with more turns', 'Utilisez un modèle de clavier plus long avec plus de tours'),
			('Avoid repeated words and characters', 'Évitez les mots et les caractères répétés'),
			('Avoid sequences', 'asdfaÉviter les séquencessdf'),
			('Avoid recent years '+#10+' Avoid years that are associated with you', 'Éviter les dernières années'+#13#10+'Évitez les années qui vous sont associées'),
			('Avoid dates and years that are associated with you', 'Évitez les dates et les années qui vous sont associées'),
			('Capitalization doesn''t help very much', 'La capitalisation n''aide pas beaucoup'),
			('All-uppercase is almost as easy to guess as all-lowercase', 'Les majuscules sont presque aussi faciles à deviner que les minuscules'),
			('Reversed words aren''t much harder to guess', 'Les mots inversés ne sont pas beaucoup plus difficiles à deviner'),
			('Predictable substitutions like "@" instead of "a" don''t help very much', 'Les substitutions prévisibles comme "@" au lieu de "a" n''aident pas beaucoup'),
			('Use a few words, avoid common phrases '+#10+' No need for symbols, digits, or uppercase letters', 'Utilisez quelques mots, évitez les phrases courantes'+#13#10+'Pas besoin de symboles, de chiffres ou de lettres majuscules')
	);
begin
	Result := AMatcher;

	if AMatcher = '' then
		Exit;

	case ATranslation of
	ztGerman:
		begin
			for i := Low(deDE) to High(deDE) do
			begin
				if SameText(deDE[i, 0], AMatcher) then
				begin
					Result := deDE[i, 1];
					Exit;
				end;
			end;
			if IsDebuggerPresent then
				OutputDebugString(PChar('No deDE translaction for "'+AMatcher+'"'));
		end;
	ztFrench:
		begin
			for i := Low(frFR) to High(frFR) do
			begin
				if SameText(frFR[i, 0], AMatcher) then
				begin
					Result := frFR[i, 1];
					Exit;
				end;
			end;
			if IsDebuggerPresent then
				OutputDebugString(PChar('No frFR translaction for "'+AMatcher+'"'));
		end;
	end;
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
	translated: string;
begin
	case AWarning of
	zwStraightRow:            translated := 'Straight rows of keys are easy to guess';
	zwShortKeyboardPatterns:  translated := 'Short keyboard patterns are easy to guess';
	zwRepeatsLikeAaaEasy:     translated := 'Repeats like "aaa" are easy to guess';
	zwRepeatsLikeAbcSlighterHarder: translated := 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"';
	zwSequenceAbcEasy:        translated := 'Sequences like abc or 6543 are easy to guess';
	zwRecentYearsEasy:        translated := 'Recent years are easy to guess';
	zwDatesEasy:              translated := 'Dates are often easy to guess';
	zwTop10Passwords:         translated := 'This is a top-10 common password';
	zwTop100Passwords:        translated := 'This is a top-100 common password';
	zwCommonPasswords:        translated := 'This is a very common password';
	zwSimilarCommonPasswords: translated := 'This is similar to a commonly used password';
	zwWordEasy:               translated := 'A word by itself is easy to guess';
	zwNameSurnamesEasy:       translated := 'Names and surnames by themselves are easy to guess';
	zwCommonNameSurnamesEasy: translated := 'Common names and surnames are easy to guess';
	zwEmpty:                  translated := '';
	else
		translated := '';
	end;

  Result := GetTranslation(translated, ATranslation);
end;

function GetSuggestion(ASuggestion: TZxcvbnSuggestion; ATranslation: TZxcvbnTranslation = ztEnglish): String;
var
  translated: String;
begin
	case ASuggestion of
	zsAddAnotherWordOrTwo:				translated := 'Add another word or two. Uncommon words are better.';
	zsUseLongerKeyboardPattern:		translated := 'Use a longer keyboard pattern with more turns';
	zsAvoidRepeatedWordsAndChars:		translated := 'Avoid repeated words and characters';
	zsAvoidSequences:						translated := 'Avoid sequences';
	zsAvoidYearsAssociatedYou:			translated := 'Avoid recent years '+#10+' Avoid years that are associated with you';
	zsAvoidDatesYearsAssociatedYou:	translated := 'Avoid dates and years that are associated with you';
	zsCapsDontHelp:						translated := 'Capitalization doesn''t help very much';
	zsAllCapsEasy:							translated := 'All-uppercase is almost as easy to guess as all-lowercase';
	zsReversedWordEasy:					translated := 'Reversed words aren''t much harder to guess';
	zsPredictableSubstitutionsEasy:	translated := 'Predictable substitutions like "@" instead of "a" don''t help very much';
	zsEmpty: translated := '';
	else
		translated := 'Use a few words, avoid common phrases '+#10+' No need for symbols, digits, or uppercase letters';
	end;

  translated := GetTranslation(translated, ATranslation);
  Result := translated;
end;

function GetSuggestions(ASuggestions: TZxcvbnSuggestions; ATranslation: TZxcvbnTranslation = ztEnglish): string;
var
  suggestion: TZxcvbnSuggestion;
  suggestions: String;
  s: string;
begin
  suggestions := '';
  for suggestion in ASuggestions do
  begin
	 s := GetSuggestion(suggestion, ATranslation);
	 if s = '' then
		Continue;

	 if suggestions <> '' then
		 suggestions := suggestions+#13#10;
	 suggestions := suggestions+
			  '- '+s;
  end;

  Result := suggestions;
end;

end.
