unit Zxcvbn.MatcherFactory;

interface
uses
  System.Classes, System.Generics.Collections,
  Zxcvbn.Matcher;

type
  /// <summary>
  /// Interface that matcher factories must implement. Matcher factories return a list of the matchers
  /// that will be used to evaluate the password
  /// </summary>
  IZxcvbnMatcherFactory = interface
    /// <summary>
    /// <para>Create the matchers to be used by an instance of Zxcvbn. </para>
    ///
    /// <para>This function will be called once per each password being evaluated, to give the opportunity to provide
    /// different user inputs for each password. Matchers that are not dependent on user inputs should ideally be created
    /// once and cached so that processing (e.g. dictionary loading) will only have to be performed once, these cached
    /// matchers plus any user input matches would then be returned when CreateMatchers is called.</para>
    /// </summary>
    /// <param name="AUserInputs">List of per-password user information for this invocation</param>
    /// <returns>A list of <see cref="IZxcvbnMatcher"/> objects that will be used to pattern match this password</returns>
    function CreateMatchers(const AUserInputs: TStringList): TList<IZxcvbnMatcher>;
  end;

implementation

end.

