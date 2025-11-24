// favorite_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;
  final String userId;
  final String movieId;
  final DateTime addedAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.addedAt,
  });

  /// Create Favorite from Firestore doc
  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Favorite(
      id: doc.id,
      userId: data['userId'] ?? '',
      movieId: data['movieId'] ?? '',
      addedAt: _parseTimestampOrStringToDateTime(data['addedAt']) ?? DateTime.now(),
    );
  }

  factory Favorite.fromMap(String id, Map<String, dynamic> data) {
    return Favorite(
      id: id,
      userId: data['userId'] ?? '',
      movieId: data['movieId'] ?? '',
      addedAt: _parseTimestampOrStringToDateTime(data['addedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'movieId': movieId,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'movieId': movieId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  static DateTime? _parseTimestampOrStringToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
