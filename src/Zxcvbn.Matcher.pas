unit Zxcvbn.Matcher;

interface
uses
  System.Classes, System.Generics.Collections,
  Zxcvbn.Result;

type
  /// <summary>
  /// All pattern matchers must implement the IZxcvbnMatcher interface.
  /// </summary>
  IZxcvbnMatcher = interface
    /// <summary>
    /// This function is called once for each matcher for each password being evaluated. It should perform the matching process and add
    /// TZxcvbnMatch objects for each match found to AMatches list.
    /// </summary>
    /// <param name="APassword">Password</param>
    /// <param name="AMatches">Matches list</param>
    procedure MatchPassword(APassword: String; var AMatches: TList<TZxcvbnMatch>);
  end;

implementation

end.
