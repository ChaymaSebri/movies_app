import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  
  // Upload Preset "unsigned" (pas besoin d'API Secret)
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'profile_pictures';
  
  // Transformations par défaut pour les photos de profil
  static const int profilePictureWidth = 400;
  static const int profilePictureHeight = 400;
  static const String profilePictureFormat = 'jpg';
  
  // URL de base pour Cloudinary
  static String get baseUrl => 'https://res.cloudinary.com/$cloudName';
  
  // Limite de taille pour les uploads (5 MB)
  static const int maxFileSizeInMB = 5;
  static const int maxFileSizeInBytes = maxFileSizeInMB * 1024 * 1024;
  
  // Formats acceptés
  static const List<String> acceptedFormats = ['jpg', 'jpeg', 'png', 'webp'];
}