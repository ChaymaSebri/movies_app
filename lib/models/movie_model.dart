// models/movie_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String id;
  final String title;
  final String description;
  final String posterUrl;
  final String? backdropUrl;
  final String category; // Nouveau champ obligatoire avec valeur par défaut
  final List<String> genres;
  final DateTime? releaseDate;
  final double? rating;
  final int? runtime;
  final String source;
  final String? addedBy;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    this.backdropUrl,
    this.category = 'Popular', // Valeur par défaut
    this.genres = const [],
    this.releaseDate,
    this.rating,
    this.runtime,
    this.source = 'manual',
    this.addedBy,
  });

  // Depuis Firestore (manuel ou API)
  factory Movie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Movie(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      posterUrl: data['posterUrl'] ?? '',
      backdropUrl: data['backdropUrl'],
      category: data['category'] as String? ?? 'Popular', // Important
      genres: List<String>.from(data['genres'] ?? []),
      releaseDate: _parseTimestampOrStringToDateTime(data['releaseDate']),
      rating: _toDouble(data['rating']),
      runtime: data['runtime'] as int?,
      source: data['source'] ?? 'manual',
      addedBy: data['addedBy'],
    );
  }

  // Depuis l’API TMDB
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['overview'] ?? '',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : '',
      backdropUrl: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w1280${json['backdrop_path']}'
          : null,
      category: 'Popular', // Les films API sont par défaut dans Popular
      genres: (json['genres'] as List<dynamic>?)
          ?.map((g) => g['name'] as String)
          .toList() ??
          [],
      releaseDate: _parseStringToDateTime(json['release_date']),
      rating: _toDouble(json['vote_average']),
      runtime: json['runtime'] as int?,
      source: 'api',
    );
  }

  // Pour sauvegarder dans Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'category': category,
      'genres': genres,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'rating': rating,
      'runtime': runtime,
      'source': source,
      'addedBy': addedBy,
    }..removeWhere((k, v) => v == null);
  }

  // Helpers
  static double? _toDouble(dynamic v) => v is num ? v.toDouble() : null;

  static DateTime? _parseTimestampOrStringToDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static DateTime? _parseStringToDateTime(String? s) =>
      s == null ? null : DateTime.tryParse(s);
}