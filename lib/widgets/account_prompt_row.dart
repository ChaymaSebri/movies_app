import 'package:flutter/material.dart';

/// Row with text prompt and action button for navigating between auth screens.
///
/// Example: "Don't have an account? Sign up"
class AccountPromptRow extends StatelessWidget {
  final String promptText;
  final String actionText;
  final VoidCallback onActionPressed;

  const AccountPromptRow({
    super.key,
    required this.promptText,
    required this.actionText,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(promptText),
        TextButton(onPressed: onActionPressed, child: Text(actionText)),
      ],
    );
  }
}
