import 'package:flutter/material.dart';

import '../../../../core/utils/email_validator.dart';
import '../../../../core/utils/password_validator.dart';
import '../widgets/account_prompt_row.dart';
import '../widgets/divider_with_text.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key to manage form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Controls password field visibility
  bool _obscurePassword = true;
  // Loading state for login operation
  bool _isLoading = false;

  // Form field values
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 48,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Column(
              children: [
                Text("Welcome Back!"),
                Text("Please login to your account to continue."),
              ],
            ),
            Form(
              key: _formKey,
              child: Column(
                spacing: 32,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "Please enter your email",
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: EmailValidatorUtil(
                      requiredMessage: 'Email is required',
                      invalidMessage: 'Please enter a valid email address',
                    ).validate,
                    onSaved: (newValue) => email = newValue ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: "Please enter your password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: PasswordValidatorUtil.validatorWith(
                      requiredMessage: 'Please enter your password',
                      minLengthMessage:
                          'Password must be at least 8 characters',
                      uppercaseMessage:
                          'Password must contain an uppercase letter',
                      numberMessage: 'Password must contain a number',
                      specialCharMessage:
                          'Password must contain a special character',
                      minLength: 8,
                    ),
                    onSaved: (newValue) => password = newValue ?? '',
                  ),
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            // Validate and save form
                            final form = _formKey.currentState;
                            if (form == null || !form.validate()) {
                              return;
                            }
                            form.save();

                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Log in"),
                  ),
                ],
              ),
            ),
            Column(
              spacing: 24,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DividerWithText(text: "Or Log in with"),
              
                AccountPromptRow(
                  promptText: "Don't have an account?",
                  actionText: "Sign up",
                  onActionPressed: () { Navigator.pushNamed(context, LoginScreen.routeName);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
