import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/age_validator.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/utils/name_validator.dart';
import '../../../../core/utils/password_validator.dart';
import '../widgets/account_prompt_row.dart';
import '../widgets/divider_with_text.dart';

class SignUpScreen extends StatefulWidget {
  static String routeName = '/sign-up';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Form key to manage form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Controls password field visibility
  bool _obscurePassword = true;
  TextEditingController passwordController = TextEditingController();
  // Controls confirm password field visibility
  bool _obscureConfirmPassword = true;
  // Loading state for signup operation
  bool _isLoading = false;

  XFile? _selectedProfilePicture;

  // Form field values
  String firstName = '';
  String lastName = '';
  int age = 0;
  String email = '';
  String password = '';

  // Focus nodes for field navigation
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _ageFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image != null) {
      setState(() {
        _selectedProfilePicture = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes and redirect


    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            spacing: 32,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Column(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _selectProfilePhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 96 / 2,
                          backgroundImage: _selectedProfilePicture != null
                              ? FileImage(File(_selectedProfilePicture!.path))
                                    as ImageProvider
                              : null,
                          backgroundColor: Colors.white,
                          child: _selectedProfilePicture != null
                              ? null
                              : Icon(Icons.person, size: 96 * 0.5),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Material(
                            color: Theme.of(context).colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _selectProfilePhoto,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Add a profile photo",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  Text("Create an Account"),
                  Text("Let's get you started and create your account."),
                ],
              ),
              Form(
                key: _formKey,
                child: Column(
                  spacing: 24,
                  children: [
                    TextFormField(
                      focusNode: _firstNameFocus,
                      decoration: const InputDecoration(
                        labelText: "First Name",
                        hintText: "Please enter your first name",
                      ),
                      validator: NameValidatorUtil.validatorWith(
                        requiredMessage: 'Please enter your first name',
                        minLengthMessage: 'Name must be at least 2 characters',
                        invalidCharactersMessage:
                            'Name can only contain letters, spaces, hyphens, and apostrophes',
                        minLength: 2,
                      ),
                      onSaved: (value) => firstName = value ?? '',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
                    ),
                    TextFormField(
                      focusNode: _lastNameFocus,
                      decoration: const InputDecoration(
                        labelText: "Last Name",
                        hintText: "Please enter your last name",
                      ),
                      validator: NameValidatorUtil.validatorWith(
                        requiredMessage: 'Please enter your last name',
                        minLengthMessage: 'Name must be at least 2 characters',
                        invalidCharactersMessage:
                            'Name can only contain letters, spaces, hyphens, and apostrophes',
                        minLength: 2,
                      ),
                      onSaved: (value) => lastName = value ?? '',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _ageFocus.requestFocus(),
                    ),
                    TextFormField(
                      focusNode: _ageFocus,
                      decoration: const InputDecoration(
                        labelText: "Age",
                        hintText: "Please enter your age",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: AgeValidatorUtil.validatorWith(
                        requiredMessage: 'Please enter your age',
                        invalidNumberMessage: 'Please enter a valid number',
                        tooYoungMessage: 'You must be at least 13 years old',
                        tooOldMessage: 'Please enter a valid age',
                        minAge: 13,
                      ),
                      onSaved: (value) => age = int.tryParse(value ?? '0') ?? 0,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                    ),
                    TextFormField(
                      focusNode: _emailFocus,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        hintText: "Please enter your email",
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: EmailValidatorUtil(
                        requiredMessage: 'Email is required',
                        invalidMessage: 'Please enter a valid email address',
                      ).validate,
                      onSaved: (value) => email = value ?? '',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    TextFormField(
                      controller: passwordController,
                      focusNode: _passwordFocus,
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
                      onSaved: (value) => password = value ?? '',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _confirmPasswordFocus.requestFocus(),
                    ),
                    TextFormField(
                      focusNode: _confirmPasswordFocus,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        hintText: "Please confirm your password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        // Unfocus to close keyboard and trigger form submission
                        _confirmPasswordFocus.unfocus();
                      },
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
                          : const Text("Sign Up"),
                    ),
                  ],
                ),
              ),
              Column(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DividerWithText(text: "Or Sign Up with"),
                  
                  AccountPromptRow(
                    promptText: "Already have an account?",
                    actionText: "Log in",
                    onActionPressed: () { Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
