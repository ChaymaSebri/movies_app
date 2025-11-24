import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movies_app/core/constants/app_routes.dart';
import 'package:movies_app/features/auth/controllers/auth_controller.dart';
import '../../../../core/utils/validators/email_validator.dart';
import '../../../../core/utils/validators/password_validator.dart';
import '../widgets/account_prompt_row.dart';
import '../widgets/divider_with_text.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

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
            // Header
            Column(
              children: const [
                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Please login to your account to continue.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            // Form
            Form(
              key: _formKey,
              child: Column(
                spacing: 32,
                children: [
                  // Email Field
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "Please enter your email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: EmailValidatorUtil(
                      requiredMessage: 'Email is required',
                      invalidMessage: 'Please enter a valid email address',
                    ).validate,
                    onSaved: (newValue) => email = newValue ?? '',
                  ),

                  // Password Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: "Please enter your password",
                      prefixIcon: const Icon(Icons.lock_outline),
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
                      minLengthMessage: 'Password must be at least 8 characters',
                      uppercaseMessage: 'Password must contain an uppercase letter',
                      numberMessage: 'Password must contain a number',
                      specialCharMessage: 'Password must contain a special character',
                      minLength: 8,
                    ),
                    onSaved: (newValue) => password = newValue ?? '',
                  ),

                  // Error Message
                  if (authController.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authController.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Login Button
                  FilledButton(
                    onPressed: authController.isLoading
                        ? null
                        : () async {
                            // Validate form
                            final form = _formKey.currentState;
                            if (form == null || !form.validate()) {
                              return;
                            }
                            form.save();

                            // Attempt login
                            final success = await authController.signIn(
                              email: email,
                              password: password,
                            );

                            if (success && mounted) {
                              // Navigate to home or profile
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.profile,
                              );
                            }
                          },
                    child: authController.isLoading
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

            // Footer
            Column(
              spacing: 24,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DividerWithText(text: "Or Log in with"),
                AccountPromptRow(
                  promptText: "Don't have an account?",
                  actionText: "Sign up",
                  onActionPressed: () {
                    Navigator.pushNamed(context, AppRoutes.signUp);
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