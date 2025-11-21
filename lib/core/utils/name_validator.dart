/// Name validator utility for first name, last name, etc.
///
/// Validates:
/// - required (non-null, non-empty)
/// - minimum length (default 2)
/// - valid characters (letters, spaces, hyphens, apostrophes)
class NameValidatorUtil {
  final String requiredMessage;
  final String minLengthMessage;
  final String invalidCharactersMessage;
  final int minLength;

  const NameValidatorUtil({
    required this.requiredMessage,
    required this.minLengthMessage,
    required this.invalidCharactersMessage,
    this.minLength = 2,
  })  : assert(
          requiredMessage != '',
          'requiredMessage must be provided and non-empty',
        ),
        assert(
          minLengthMessage != '',
          'minLengthMessage must be provided and non-empty',
        ),
        assert(
          invalidCharactersMessage != '',
          'invalidCharactersMessage must be provided and non-empty',
        );

  /// Validates [value]. Returns `null` when valid, otherwise returns
  /// a localized/consumer-provided error message.
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }

    final name = value.trim();

    if (name.length < minLength) {
      return minLengthMessage;
    }

    // Allow letters (including Unicode), spaces, hyphens, and apostrophes
    // Examples: "Mary", "Jean-Claude", "O'Brien", "José"
    final validPattern = RegExp(r"^[\p{L}\s\-']+$", unicode: true);
    if (!validPattern.hasMatch(name)) {
      return invalidCharactersMessage;
    }

    return null;
  }

  /// A `FormFieldValidator` compatible getter for direct use in
  /// `TextFormField.validator`.
  String? Function(String?) get validator => validate;

  /// Convenience factory that returns a `FormFieldValidator<String?>` with
  /// required error messages.
  static String? Function(String?) validatorWith({
    required String requiredMessage,
    required String minLengthMessage,
    required String invalidCharactersMessage,
    int minLength = 2,
  }) {
    assert(
      requiredMessage != '',
      'requiredMessage must be provided and non-empty',
    );
    assert(
      minLengthMessage != '',
      'minLengthMessage must be provided and non-empty',
    );
    assert(
      invalidCharactersMessage != '',
      'invalidCharactersMessage must be provided and non-empty',
    );

    final util = NameValidatorUtil(
      requiredMessage: requiredMessage,
      minLengthMessage: minLengthMessage,
      invalidCharactersMessage: invalidCharactersMessage,
      minLength: minLength,
    );

    return util.validate;
  }
}
