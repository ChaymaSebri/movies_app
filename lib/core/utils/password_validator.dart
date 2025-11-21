/// Password validator utility.
///
/// Validates:
/// - required (non-null, non-empty)
/// - minimum length (default 8)
/// - at least one uppercase letter
/// - at least one numeric digit
/// - at least one special character
class PasswordValidatorUtil {
  final String requiredMessage;
  final String minLengthMessage;
  final String uppercaseMessage;
  final String numberMessage;
  final String specialCharMessage;
  final int minLength;

  const PasswordValidatorUtil({
    required this.requiredMessage,
    required this.minLengthMessage,
    required this.uppercaseMessage,
    required this.numberMessage,
    required this.specialCharMessage,
    this.minLength = 8,
  }) : assert(
         requiredMessage != '',
         'requiredMessage must be provided and non-empty',
       ),
       assert(
         minLengthMessage != '',
         'minLengthMessage must be provided and non-empty',
       ),
       assert(
         uppercaseMessage != '',
         'uppercaseMessage must be provided and non-empty',
       ),
       assert(
         numberMessage != '',
         'numberMessage must be provided and non-empty',
       ),
       assert(
         specialCharMessage != '',
         'specialCharMessage must be provided and non-empty',
       );

  /// Validate the provided [value]. Returns `null` if valid, otherwise an
  /// error message (consumer-provided or default).
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }

    if (value.length < minLength) {
      return minLengthMessage;
    }

    // At least one uppercase letter
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    if (!hasUpper) return uppercaseMessage;

    // At least one number
    final hasNumber = RegExp(r'\d').hasMatch(value);
    if (!hasNumber) return numberMessage;

    // At least one special character
    final hasSpecial = RegExp(
      r'[!@#\$%\^&\*()_+\-=[\]{};:\"\\|,.<>\/?~`]',
    ).hasMatch(value);
    if (!hasSpecial) return specialCharMessage;

    return null;
  }

  /// A `FormFieldValidator<String?>` compatible getter for direct use in
  /// `TextFormField.validator`.
  String? Function(String?) get validator => validate;

  /// Convenience factory returning a validator function
  static String? Function(String?) validatorWith({
    required String requiredMessage,
    required String minLengthMessage,
    required String uppercaseMessage,
    required String numberMessage,
    required String specialCharMessage,
    int minLength = 8,
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
      uppercaseMessage != '',
      'uppercaseMessage must be provided and non-empty',
    );
    assert(numberMessage != '', 'numberMessage must be provided and non-empty');
    assert(
      specialCharMessage != '',
      'specialCharMessage must be provided and non-empty',
    );

    final util = PasswordValidatorUtil(
      requiredMessage: requiredMessage,
      minLengthMessage: minLengthMessage,
      uppercaseMessage: uppercaseMessage,
      numberMessage: numberMessage,
      specialCharMessage: specialCharMessage,
      minLength: minLength,
    );

    return util.validate;
  }

  // /// Convenience factory for validating a confirm password field.
  // ///
  // /// Validates that the confirmation is not empty and matches [password].
  // /// Returns a validator function suitable for TextFormField.validator.
  // static String? Function(String?) confirmPasswordValidatorWith({
  //   required String password,
  //   required String requiredMessage,
  //   required String mismatchMessage,
  // }) {
  //   assert(
  //     requiredMessage != '',
  //     'requiredMessage must be provided and non-empty',
  //   );
  //   assert(
  //     mismatchMessage != '',
  //     'mismatchMessage must be provided and non-empty',
  //   );

  //   return (String? value) {
  //     if (value == null || value.isEmpty) {
  //       return requiredMessage;
  //     }
  //     if (value != password) {
  //       return mismatchMessage;
  //     }
  //     return null;
  //   };
  // }
}
