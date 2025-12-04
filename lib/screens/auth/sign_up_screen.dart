import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Validate the image
      final isValid = await ImagePickerHelper.isValidImage(image);

      if (!isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid image or file too large (max 5MB)'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          SnackBar(
            content: const Text('Account created successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                ),
  
                const SizedBox(height: 40),

                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Create an account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join MovieMates and start discovering movies",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Profile Photo Section
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _selectProfilePhoto,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: _selectedProfilePicture != null
                                    ? FileImage(_selectedProfilePicture!)
                                    : null,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                child: _selectedProfilePicture != null
                                    ? null
                                    : Icon(
                                        Icons.person_rounded,
                                        size: 56,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedProfilePicture != null 
                            ? "Tap to change photo" 
                            : "Add a profile photo (optional)",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name fields row
                      Row(
                        children: [
                          // First Name
                          Expanded(
                            child: TextFormField(
                              focusNode: _firstNameFocus,
                              decoration: InputDecoration(
                                labelText: "First Name",
                                hintText: "John",
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: colorScheme.primary,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                              ),
                              validator: NameValidatorUtil.validatorWith(
                                requiredMessage: 'Required',
                                minLengthMessage: 'At least 2 characters',
                                invalidCharactersMessage:
                                    'Only letters, spaces, hyphens, and apostrophes',
                                minLength: 2,
                              ),
                              onSaved: (value) => firstName = value ?? '',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Last Name
                          Expanded(
                            child: TextFormField(
                              focusNode: _lastNameFocus,
                              decoration: InputDecoration(
                                labelText: "Last Name",
                                hintText: "Doe",
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: colorScheme.primary,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                              ),
                              validator: NameValidatorUtil.validatorWith(
                                requiredMessage: 'Required',
                                minLengthMessage: 'At least 2 characters',
                                invalidCharactersMessage:
                                    'Only letters, spaces, hyphens, and apostrophes',
                                minLength: 2,
                              ),
                              onSaved: (value) => lastName = value ?? '',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _ageFocus.requestFocus(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Age
                      TextFormField(
                        focusNode: _ageFocus,
                        decoration: InputDecoration(
                          labelText: "Age",
                          hintText: "Enter your age",
                          prefixIcon: Icon(
                            Icons.cake_outlined,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 1,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: AgeValidatorUtil.validatorWith(
                          requiredMessage: 'Age is required',
                          invalidNumberMessage: 'Please enter a valid number',
                          tooYoungMessage: 'You must be at least 13 years old',
                          tooOldMessage: 'Invalid age, maximum allowed is 120',
                          minAge: 13,
                        ),
                        onSaved: (value) => age = int.tryParse(value ?? '0') ?? 0,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                      ),

                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        focusNode: _emailFocus,
                        decoration: InputDecoration(
                          labelText: "Email",
                          hintText: "Enter your email",
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 1,
                            ),
                          ),
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

                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: passwordController,
                        focusNode: _passwordFocus,
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "Create a strong password",
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 1,
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

                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        focusNode: _confirmPasswordFocus,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          hintText: "Re-enter your password",
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 1,
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

                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Sign In Prompt
                AccountPromptRow(
                  promptText: "Already have an account?",
                  actionText: "Sign in",
                  onActionPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
