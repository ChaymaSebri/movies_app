/// Age validator utility for age input fields.
///
/// Validates:
/// - required (non-null, non-empty)
/// - must be a valid integer
/// - minimum age requirement (default 13)
/// - maximum age (default 120 for sanity check)
class AgeValidatorUtil {
  final String requiredMessage;
  final String invalidNumberMessage;
  final String tooYoungMessage;
  final String tooOldMessage;
  final int minAge;
  final int maxAge;

  const AgeValidatorUtil({
    required this.requiredMessage,
    required this.invalidNumberMessage,
    required this.tooYoungMessage,
    required this.tooOldMessage,
    this.minAge = 13,
    this.maxAge = 120,
  })  : assert(
          requiredMessage != '',
          'requiredMessage must be provided and non-empty',
        ),
        assert(
          invalidNumberMessage != '',
          'invalidNumberMessage must be provided and non-empty',
        ),
        assert(
          tooYoungMessage != '',
          'tooYoungMessage must be provided and non-empty',
        ),
        assert(
          tooOldMessage != '',
          'tooOldMessage must be provided and non-empty',
        );

  /// Validates [value]. Returns `null` when valid, otherwise returns
  /// a localized/consumer-provided error message.
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }

    final ageStr = value.trim();
    final age = int.tryParse(ageStr);

    if (age == null) {
      return invalidNumberMessage;
    }

    if (age < minAge) {
      return tooYoungMessage;
    }

    if (age > maxAge) {
      return tooOldMessage;
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
    required String invalidNumberMessage,
    required String tooYoungMessage,
    required String tooOldMessage,
    int minAge = 13,
    int maxAge = 120,
  }) {
    assert(
      requiredMessage != '',
      'requiredMessage must be provided and non-empty',
    );
    assert(
      invalidNumberMessage != '',
      'invalidNumberMessage must be provided and non-empty',
    );
    assert(
      tooYoungMessage != '',
      'tooYoungMessage must be provided and non-empty',
    );
    assert(
      tooOldMessage != '',
      'tooOldMessage must be provided and non-empty',
    );

    final util = AgeValidatorUtil(
      requiredMessage: requiredMessage,
      invalidNumberMessage: invalidNumberMessage,
      tooYoungMessage: tooYoungMessage,
      tooOldMessage: tooOldMessage,
      minAge: minAge,
      maxAge: maxAge,
    );

    return util.validate;
  }
}
