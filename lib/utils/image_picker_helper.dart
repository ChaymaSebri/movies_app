import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionner une image depuis la galerie (sans dialog)
  static Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  /// Vérifier si l'image est valide (taille, format)
  static Future<bool> isValidImage(File imageFile) async {
    try {
      // Vérifier la taille (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        return false;
      }

      // Vérifier l'extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      
      return validExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }

  /// Obtenir la taille du fichier en MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }
}