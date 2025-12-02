import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/cloudinary_service.dart';
import 'package:movies_app/services/user_service.dart';
import 'package:movies_app/models/user_model.dart';
import 'package:movies_app/utils/validators/age_validator.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _ageController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Image handling
  File? _newProfileImage; // Stocke temporairement l'image sélectionnée
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final user = await _userService.getUserById(userId);
      if (user == null) throw 'User not found';

      setState(() {
        _currentUser = user;
        _prenomController.text = user.prenom;
        _nomController.text = user.nom;
        _ageController.text = user.age.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// ==================== SELECT PROFILE IMAGE ====================
  /// L'image est juste sélectionnée, pas encore uploadée
  Future<void> _selectProfilePicture() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _newProfileImage = File(picked.path);
    });
  }

  /// ==================== SAVE PROFILE ====================
  /// Upload l'image ET sauvegarde toutes les modifications
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUser!.uid;
      String? newPhotoUrl = _currentUser!.photoUrl;

      // 1. Upload la nouvelle photo si sélectionnée
      if (_newProfileImage != null) {
        newPhotoUrl = await _cloudinaryService.uploadProfilePicture(
          userId: userId,
          imageFile: _newProfileImage!,
        );
      }

      // 2. Créer l'utilisateur mis à jour
      final updatedUser = _currentUser!.copyWith(
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        photoUrl: newPhotoUrl,
      );

      // 3. Sauvegarder dans Firestore
      await _userService.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle),
                const SizedBox(width: 12),
                Text('Profile updated!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Retourner true pour indiquer qu'il faut refresh le ProfileScreen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView(scheme)
          : _buildForm(scheme),
    );
  }

  Widget _buildForm(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// ==================== PROFILE AVATAR ====================
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _newProfileImage != null
                          ? scheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage: _getProfileImage(),
                    child:
                        _currentUser!.photoUrl == null &&
                            _newProfileImage == null
                        ? const Icon(Icons.person, size: 65)
                        : null,
                  ),
                ),

                // CAMERA BUTTON
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _isSaving ? null : _selectProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: scheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Badge "New" si une nouvelle image est sélectionnée
                if (_newProfileImage != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'NEW',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            /// ==================== FORM FIELDS ====================
            _buildField(
              controller: _prenomController,
              label: "First Name",
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.isEmpty ? "Enter your first name" : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _nomController,
              label: "Last Name",
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.isEmpty ? "Enter your last name" : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _ageController,
              label: "Age",
              icon: Icons.cake_outlined,
              keyboard: TextInputType.number,
              validator: AgeValidatorUtil.validatorWith(
                requiredMessage: "Enter your age",
                invalidNumberMessage: "Age must be a valid number",
                tooYoungMessage: "You must be at least 13 years old",
                tooOldMessage: "Invalid age, maximum allowed is 120",
                minAge: 13,
                maxAge: 120,
              ),
            ),

            const SizedBox(height: 24),

            /// ==================== SAVE BUTTON ====================
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                label: Text(
                  _isSaving ? "Saving..." : "Save Changes",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retourne l'image à afficher (nouvelle ou existante)
  ImageProvider? _getProfileImage() {
    if (_newProfileImage != null) {
      // Afficher la nouvelle image sélectionnée
      return FileImage(_newProfileImage!);
    } else if (_currentUser!.photoUrl != null) {
      // Afficher l'image existante
      return CachedNetworkImageProvider(_currentUser!.photoUrl!);
    }
    return null;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildErrorView(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 60, color: scheme.error),
            const SizedBox(height: 10),
            Text(_errorMessage ?? "Error"),
            const SizedBox(height: 20),
            FilledButton(onPressed: _loadUserData, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
