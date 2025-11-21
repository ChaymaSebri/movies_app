import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart' as email_validator;

/// Utility for validating email input in forms.
class EmailValidatorUtil {
  /// Message returned when the value is null/empty.
  final String requiredMessage;

  /// Message returned when the value is not a valid email.
  final String invalidMessage;

  const EmailValidatorUtil({
    required this.requiredMessage,
    required this.invalidMessage,
  }) : assert(
         requiredMessage != '',
         'requiredMessage must be provided and non-empty',
       ),
       assert(
         invalidMessage != '',
         'invalidMessage must be provided and non-empty',
       );

  /// Validates [value]. Returns `null` when valid, otherwise returns
  /// a localized/consumer-provided error message.
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }

    final email = value.trim();
    final isValid = email_validator.EmailValidator.validate(email);
    return isValid ? null : invalidMessage;
  }

  /// A `FormFieldValidator` compatible getter for direct use in
  /// `TextFormField.validator`.
  FormFieldValidator<String?> get validator => validate;

  /// Convenience factory that returns a `FormFieldValidator<String?>` with
  /// optional custom messages.
  static FormFieldValidator<String?> validatorWith({
    required String requiredMessage,
    required String invalidMessage,
  }) {
    assert(
      requiredMessage != '',
      'requiredMessage must be provided and non-empty',
    );
    assert(
      invalidMessage != '',
      'invalidMessage must be provided and non-empty',
    );
    final util = EmailValidatorUtil(
      requiredMessage: requiredMessage,
      invalidMessage: invalidMessage,
    );
    return util.validate;
  }
}
