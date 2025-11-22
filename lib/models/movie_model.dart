// movie_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String id;
  final String title;
  final String description;
  final String posterUrl;
  final String genre;
  final DateTime? releaseDate; // optional
  final double? rating;        // optional
  final String source;         // "api" or "manual"
  final String? addedBy;       // admin userId or null

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    this.genre = '',
    this.releaseDate,
    this.rating,
    this.source = 'manual',
    this.addedBy,
  });

  /// Create Movie from Firestore DocumentSnapshot
  factory Movie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Movie(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      posterUrl: data['posterUrl'] ?? '',
      genre: data['genre'] ?? '',
      releaseDate: _parseTimestampOrStringToDateTime(data['releaseDate']),
      rating: _toDouble(data['rating']),
      source: data['source'] ?? 'manual',
      addedBy: data['addedBy'],
    );
  }

  /// Create Movie from a plain map (e.g. when you build locally or from API JSON)
  factory Movie.fromMap(String id, Map<String, dynamic> data) {
    return Movie(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      posterUrl: data['posterUrl'] ?? '',
      genre: data['genre'] ?? '',
      releaseDate: _parseTimestampOrStringToDateTime(data['releaseDate']),
      rating: _toDouble(data['rating']),
      source: data['source'] ?? 'manual',
      addedBy: data['addedBy'],
    );
  }

  /// Create Movie from API JSON (example: RapidAPI response). Keep tolerant to missing fields.
  factory Movie.fromJson(Map<String, dynamic> json) {
    // Map fields according to the API structure — adapt names if API differs.
    return Movie(
      id: json['id']?.toString() ?? '', // API id (string/int)
      title: json['title'] ?? json['name'] ?? '',
      description: json['overview'] ?? json['description'] ?? '',
      posterUrl: json['poster_path'] != null
          ? _buildPosterUrlFromPath(json['poster_path'])
          : (json['posterUrl'] ?? ''),
      genre: (json['genre'] is String) ? json['genre'] : (json['genres'] is List && json['genres'].isNotEmpty ? json['genres'][0].toString() : ''),
      releaseDate: _parseStringToDateTime(json['release_date'] ?? json['first_air_date']),
      rating: _toDouble(json['vote_average'] ?? json['rating']),
      source: 'api',
      addedBy: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'genre': genre,
      // Store releaseDate as ISO string or Firestore Timestamp from your service.
      'releaseDate': releaseDate?.toIso8601String(),
      'rating': rating,
      'source': source,
      'addedBy': addedBy,
    };
  }

  /// Useful when writing to Firestore with an actual Timestamp
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'genre': genre,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'rating': rating,
      'source': source,
      'addedBy': addedBy,
    }..removeWhere((k, v) => v == null); // remove nulls
  }

  // ----- helpers -----
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseTimestampOrStringToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return _parseStringToDateTime(value);
    return null;
  }

  static DateTime? _parseStringToDateTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String _buildPosterUrlFromPath(String path) {
    // If you use TMDB you typically need to prepend a base URL.
    // Replace this with your own base if different.
    if (path.startsWith('http')) return path;
    return 'https://image.tmdb.org/t/p/w500$path';
  }
}
