import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:movies_app/config/cloudinary_config.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  /// Upload une photo de profil et retourne l'URL
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Créer un identifiant unique pour l'image
      final String publicId = 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Upload l'image sur Cloudinary
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_pictures',
          publicId: publicId,
        ),
      );

      // Retourner l'URL sécurisée
      return response.secureUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload de l\'image: $e';
    }
  }

  /// Générer une URL transformée (redimensionnée, optimisée)
  String getOptimizedImageUrl({
    required String imageUrl,
    int width = 400,
    int height = 400,
    String format = 'jpg',
  }) {
    try {
      // Extraire le publicId depuis l'URL Cloudinary
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Trouver l'index après "upload/"
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return imageUrl;

      // Reconstruire l'URL avec les transformations
      final publicId = pathSegments.sublist(uploadIndex + 1).join('/');

      return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/'
          'w_$width,h_$height,c_fill,f_$format/$publicId';
    } catch (e) {
      // En cas d'erreur, retourner l'URL originale
      return imageUrl;
    }
  }

  /// Supprimer une image (nécessite l'API avec authentification)
  /// Note : Pour supprimer, il faut utiliser l'API Admin avec API Secret
  /// Ce n'est pas recommandé côté client pour des raisons de sécurité
  /// Mieux vaut garder les anciennes images ou utiliser un backend
  Future<void> deleteProfilePicture(String imageUrl) async {
    // ⚠️ La suppression nécessite l'API Admin de Cloudinary
    // Pour des raisons de sécurité, ne pas exposer l'API Secret côté client
    // Options :
    // 1. Garder les anciennes images (Cloudinary a beaucoup d'espace gratuit)
    // 2. Créer un backend qui gère la suppression
    // 3. Utiliser les webhooks Cloudinary pour nettoyer automatiquement

    // Pour l'instant, nous n'implémentons pas la suppression
    // Les images restent sur Cloudinary mais ne sont plus référencées
    print('Note: Image suppression non implémentée côté client pour sécurité');
  }

  /// Vérifier si une URL est valide
  bool isValidCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') && url.contains('image/upload');
  }

  /// Extraire le publicId depuis une URL Cloudinary
  String? extractPublicId(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');

      if (uploadIndex == -1) return null;

      // Joindre tous les segments après "upload/" et retirer l'extension
      final publicIdWithExt = pathSegments.sublist(uploadIndex + 1).join('/');
      final lastDotIndex = publicIdWithExt.lastIndexOf('.');

      if (lastDotIndex != -1) {
        return publicIdWithExt.substring(0, lastDotIndex);
      }

      return publicIdWithExt;
    } catch (e) {
      return null;
    }
  }

  /// Obtenir une URL de thumbnail
  String getThumbnailUrl(String imageUrl, {int size = 150}) {
    return getOptimizedImageUrl(
      imageUrl: imageUrl,
      width: size,
      height: size,
    );
  }

  /// Obtenir différentes tailles d'image
  Map<String, String> getResponsiveUrls(String imageUrl) {
    return {
      'thumbnail': getThumbnailUrl(imageUrl, size: 150),
      'small': getOptimizedImageUrl(imageUrl: imageUrl, width: 400, height: 400),
      'medium': getOptimizedImageUrl(imageUrl: imageUrl, width: 800, height: 800),
      'large': getOptimizedImageUrl(imageUrl: imageUrl, width: 1200, height: 1200),
      'original': imageUrl,
    };
  }
}
