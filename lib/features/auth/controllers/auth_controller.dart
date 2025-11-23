import 'dart:io';
import 'package:flutter/material.dart';
import 'package:movies_app/core/services/auth_service.dart';
import 'package:movies_app/core/services/user_service.dart';
import 'package:movies_app/core/services/cloudinary_service.dart';
import 'package:movies_app/features/auth/models/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // ✅ Ne pas créer CloudinaryService dans le constructeur
  CloudinaryService? _cloudinaryService;
  CloudinaryService get _getCloudinaryService {
    _cloudinaryService ??= CloudinaryService();
    return _cloudinaryService!;
  }

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;

  // Inscription
  Future<bool> signUp({
    required String nom,
    required String prenom,
    required int age,
    required String email,
    required String password,
    File? profilePicture,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Créer le compte Firebase Auth
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // 2. Upload la photo de profil sur Cloudinary (si fournie)
      String? photoUrl;
      if (profilePicture != null) {
        photoUrl = await _getCloudinaryService.uploadProfilePicture(
          userId: userId,
          imageFile: profilePicture,
        );
      }

      // 3. Créer le document utilisateur dans Firestore
      final user = UserModel(
        id: userId,
        nom: nom,
        prenom: prenom,
        age: age,
        email: email,
        photoUrl: photoUrl,
        isActive: true,
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _userService.createUser(user);

      // 4. Charger l'utilisateur actuel
      _currentUser = user;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Connexion
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Se connecter avec Firebase Auth
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      // 2. Récupérer les données utilisateur depuis Firestore
      final userId = credential.user!.uid;
      final user = await _userService.getUserById(userId);

      if (user == null) {
        throw 'Utilisateur non trouvé dans la base de données';
      }

      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  // Charger l'utilisateur actuel
  Future<void> loadCurrentUser() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _currentUser = await _userService.getUserById(userId);
      notifyListeners();
    }
  }

  // Mettre à jour le profil
  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    int? age,
    File? newProfilePicture,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      String? newPhotoUrl = _currentUser!.photoUrl;

      // Upload nouvelle photo sur Cloudinary si fournie
      if (newProfilePicture != null) {
        newPhotoUrl = await _getCloudinaryService.uploadProfilePicture(
          userId: _currentUser!.id,
          imageFile: newProfilePicture,
        );
      }

      // Créer l'utilisateur mis à jour
      final updatedUser = _currentUser!.copyWith(
        nom: nom,
        prenom: prenom,
        age: age,
        photoUrl: newPhotoUrl,
      );

      // Mettre à jour dans Firestore
      await _userService.updateUser(updatedUser);

      _currentUser = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Supprimer le compte
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Supprimer de Firestore
      await _userService.deleteUser(_currentUser!.id);

      // 2. Supprimer de Firebase Auth
      await _authService.deleteAccount();

      _currentUser = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Obtenir l'URL optimisée d'une image
  String? getOptimizedProfilePicture({int size = 400}) {
    if (_currentUser?.photoUrl == null) return null;
    
    return _getCloudinaryService.getOptimizedImageUrl(
      imageUrl: _currentUser!.photoUrl!,
      width: size,
      height: size,
    );
  }

  // Helper pour gérer l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}