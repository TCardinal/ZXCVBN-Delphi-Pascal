unit Zxcvbn.DefaultMatcherFactory;

interface
uses
  System.Classes, System.Generics.Collections,
  Zxcvbn.Matcher,
  Zxcvbn.MatcherFactory;

type
  /// <summary>
  /// <para>This matcher factory will use all of the default password matchers.</para>
  ///
  /// <para>Default dictionary matchers use the built-in word lists: passwords, english, male_names, female_names, surnames</para>
  /// <para>Also matching against: user data, all dictionaries with l33t substitutions</para>
  /// <para>Other default matchers: repeats, sequences, digits, years, dates, spatial</para>
  ///
  /// <para>See <see cref="Zxcvbn.Matcher.IZxcvbnMatcher"/> and the classes that implement it for more information on each kind of pattern matcher.</para>
  /// </summary>
  TZxcvbnDefaultMatcherFactory = class(TInterfacedObject, IZxcvbnMatcherFactory)
  private
    FMatchers: TList<IZxcvbnMatcher>;
    FDictionaryMatchers: TList<IZxcvbnMatcher>;
    FCustomMatchers: TList<IZxcvbnMatcher>;
  public
    /// <summary>
    /// Create a matcher factory that uses the default list of pattern matchers
    /// </summary>
    constructor Create(ADictionariesPath: String);

    destructor Destroy; override;

    /// <summary>
    /// Get instances of pattern matchers, adding in per-password matchers on userInputs (and userInputs with l33t substitutions)
    /// </summary>
    /// <param name="AUserInputs">String list of user information</param>
    /// <returns>List of matchers to use</returns>
    function CreateMatchers(const AUserInputs: TStringList): TList<IZxcvbnMatcher>;
  end;

implementation
uses
  Zxcvbn.DictionaryMatcher,
  Zxcvbn.RepeatMatcher,
  Zxcvbn.SequenceMatcher,
  Zxcvbn.RegexMatcher,
  Zxcvbn.DateMatcher,
  Zxcvbn.L33tMatcher,
  Zxcvbn.SpatialMatcher;

{ TZxcvbnDefaultMatcherFactory }

constructor TZxcvbnDefaultMatcherFactory.Create(ADictionariesPath: String);
begin
  FMatchers := TList<IZxcvbnMatcher>.Create;
  FDictionaryMatchers := TList<IZxcvbnMatcher>.Create;
  FCustomMatchers := TList<IZxcvbnMatcher>.Create;

  FDictionaryMatchers.Add(TZxcvbnDictionaryMatcher.Create('passwords', ADictionariesPath + 'passwords.lst'));
  FDictionaryMatchers.Add(TZxcvbnDictionaryMatcher.Create('english', ADictionariesPath + 'english.lst'));
  FDictionaryMatchers.Add(TZxcvbnDictionaryMatcher.Create('male_names', ADictionariesPath + 'male_names.lst'));
  FDictionaryMatchers.Add(TZxcvbnDictionaryMatcher.Create('female_names', ADictionariesPath + 'female_names.lst'));
  FDictionaryMatchers.Add(TZxcvbnDictionaryMatcher.Create('surnames', ADictionariesPath + 'surnames.lst'));
  FMatchers.Add(TZxcvbnRepeatMatcher.Create);
  FMatchers.Add(TZxcvbnSequenceMatcher.Create);
  FMatchers.Add(TZxcvbnRegexMatcher.Create('\d{3,}', 10, True, 'digits'));
  FMatchers.Add(TZxcvbnRegexMatcher.Create('19\d\d|200\d|201\d', 119, False, 'year'));
  FMatchers.Add(TZxcvbnDateMatcher.Create);
  FMatchers.Add(TZxcvbnSpatialMatcher.Create);
  FMatchers.Add(TZxcvbnL33tMatcher.Create(FDictionaryMatchers));
end;

destructor TZxcvbnDefaultMatcherFactory.Destroy;
begin
  FMatchers.Free;
  FDictionaryMatchers.Free;
  FCustomMatchers.Clear;
  FCustomMatchers.Free;
  inherited;
end;

function TZxcvbnDefaultMatcherFactory.CreateMatchers(const AUserInputs: TStringList): TList<IZxcvbnMatcher>;
var
  userInputDict: IZxcvbnMatcher;
begin
  FCustomMatchers.Clear;
  FCustomMatchers.AddRange(FMatchers);
  FCustomMatchers.AddRange(FDictionaryMatchers);

  userInputDict := TZxcvbnDictionaryMatcher.Create('user_inputs', AUserInputs);
  FCustomMatchers.Add(userInputDict);
  FCustomMatchers.Add(TZxcvbnL33tMatcher.Create(userInputDict));

  Result := FCustomMatchers;
end;

end.
