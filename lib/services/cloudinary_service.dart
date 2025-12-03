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

  /// Upload a profile picture and return its URL
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Create a unique identifier for the image
      final String publicId = 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Upload the image to Cloudinary
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_pictures',
          publicId: publicId,
        ),
      );

      // Return the secure URL
      return response.secureUrl;
    } catch (e) {
      throw 'Error while uploading image: $e';
    }
  }

  /// Generate an optimized (resized, compressed) image URL
  String getOptimizedImageUrl({
    required String imageUrl,
    int width = 400,
    int height = 400,
    String format = 'jpg',
  }) {
    try {
      // Extract the publicId from the Cloudinary URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the index after "upload/"
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return imageUrl;

      // Rebuild the URL with transformations
      final publicId = pathSegments.sublist(uploadIndex + 1).join('/');

      return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/'
          'w_$width,h_$height,c_fill,f_$format/$publicId';
    } catch (e) {
      // If there is an error, return the original URL
      return imageUrl;
    }
  }

  /// Delete an image (requires Admin API authentication)
  /// Note: Deleting requires the Admin API with API Secret
  /// This is not recommended on the client side for security reasons
  /// Better options include:
  /// 1. Keeping old images (Cloudinary offers plenty of free storage)
  /// 2. Creating a backend to handle deletions
  /// 3. Using Cloudinary webhooks to auto-clean unused files
  Future<void> deleteProfilePicture(String imageUrl) async {
    // Not implemented on the client side for security reasons
  }

  /// Check if a URL is a valid Cloudinary URL
  bool isValidCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') && url.contains('image/upload');
  }

  /// Extract the publicId from a Cloudinary URL
  String? extractPublicId(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');

      if (uploadIndex == -1) return null;

      // Join all segments after "upload/" and remove the extension
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

  /// Get a thumbnail URL
  String getThumbnailUrl(String imageUrl, {int size = 150}) {
    return getOptimizedImageUrl(imageUrl: imageUrl, width: size, height: size);
  }

  /// Get multiple responsive image URLs
  Map<String, String> getResponsiveUrls(String imageUrl) {
    return {
      'thumbnail': getThumbnailUrl(imageUrl, size: 150),
      'small': getOptimizedImageUrl(
        imageUrl: imageUrl,
        width: 400,
        height: 400,
      ),
      'medium': getOptimizedImageUrl(
        imageUrl: imageUrl,
        width: 800,
        height: 800,
      ),
      'large': getOptimizedImageUrl(
        imageUrl: imageUrl,
        width: 1200,
        height: 1200,
      ),
      'original': imageUrl,
    };
  }
}
