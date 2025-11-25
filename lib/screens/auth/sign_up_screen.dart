import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movies_app/constants/app_routes.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/user_service.dart';
import 'package:movies_app/services/cloudinary_service.dart';
import 'package:movies_app/models/user_model.dart';
import 'package:movies_app/utils/image_picker_helper.dart';
import 'package:movies_app/utils/validators/age_validator.dart';
import 'package:movies_app/utils/validators/email_validator.dart';
import 'package:movies_app/utils/validators/name_validator.dart';
import 'package:movies_app/utils/validators/password_validator.dart';
import '../../widgets/account_prompt_row.dart';
import '../../widgets/divider_with_text.dart';

class SignUpScreen extends StatefulWidget {
  static String routeName = '/sign-up';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  File? _selectedProfilePicture;

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
    final image = await ImagePickerHelper.pickImage();
    
    if (image != null) {
      // Vérifier la validité de l'image
      final isValid = await ImagePickerHelper.isValidImage(image);
      
      if (!isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image invalide ou trop grande (max 5MB)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedProfilePicture = image;
      });
    }
  }

  Future<void> _handleSignUp() async {
    // Validate form
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    form.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create Firebase Auth account
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // 2. Upload profile picture to Cloudinary (if provided)
      String? photoUrl;
      if (_selectedProfilePicture != null) {
        photoUrl = await _cloudinaryService.uploadProfilePicture(
          userId: userId,
          imageFile: _selectedProfilePicture!,
        );
      }

      // 3. Create user document in Firestore
      final user = UserModel(
        id: userId,
        nom: lastName,
        prenom: firstName,
        age: age,
        email: email,
        photoUrl: photoUrl,
        isActive: true,
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _userService.createUser(user);

      // 4. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // 5. Navigate to login
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Profile Photo Section
              Column(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : _selectProfilePhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: _selectedProfilePicture != null
                              ? FileImage(_selectedProfilePicture!)
                              : null,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: _selectedProfilePicture != null
                              ? null
                              : Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.add_a_photo,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Add a profile photo (optional)",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),

              // Header
              const Column(
                children: [
                  Text(
                    "Create an Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Let's get you started and create your account.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  spacing: 24,
                  children: [
                    // First Name
                    TextFormField(
                      focusNode: _firstNameFocus,
                      decoration: const InputDecoration(
                        labelText: "First Name",
                        hintText: "Please enter your first name",
                        prefixIcon: Icon(Icons.person_outline),
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

                    // Last Name
                    TextFormField(
                      focusNode: _lastNameFocus,
                      decoration: const InputDecoration(
                        labelText: "Last Name",
                        hintText: "Please enter your last name",
                        prefixIcon: Icon(Icons.person_outline),
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

                    // Age
                    TextFormField(
                      focusNode: _ageFocus,
                      decoration: const InputDecoration(
                        labelText: "Age",
                        hintText: "Please enter your age",
                        prefixIcon: Icon(Icons.cake_outlined),
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

                    // Email
                    TextFormField(
                      focusNode: _emailFocus,
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
                      onSaved: (value) => email = value ?? '',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      focusNode: _passwordFocus,
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

                    // Confirm Password
                    TextFormField(
                      focusNode: _confirmPasswordFocus,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        hintText: "Please confirm your password",
                        prefixIcon: const Icon(Icons.lock_outline),
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
                        _confirmPasswordFocus.unfocus();
                      },
                    ),

                    // Error Message
                    if (_errorMessage != null)
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
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Sign Up Button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSignUp,
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

              // Footer
              Column(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DividerWithText(text: "Or Sign Up with"),
                  AccountPromptRow(
                    promptText: "Already have an account?",
                    actionText: "Log in",
                    onActionPressed: () {
                      Navigator.pop(context);
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