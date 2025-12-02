// lib/services/playlist_service.dart
// VERSION ABSOLUMENT PARFAITE — Garde ça pour toujours
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/movie_model.dart';
import 'movie_service.dart';

class PlaylistService {
  // ====================== SINGLETON ======================
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  // ====================== SERVICES ======================
  final MovieService _movieService = MovieService(); // Singleton → parfait

  // ====================== RÉFÉRENCE DYNAMIQUE (propre et rapide) ======================
  CollectionReference _userFavoritesRef(String userId) =>
      FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');

  // ====================== AJOUTER FAVORI ======================
  Future<void> addFavorite(String userId, String movieId) async {
    try {
      await _userFavoritesRef(userId).doc(movieId).set({
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true → plus safe
    } catch (e) {
      debugPrint("Error adding favorite: $e");
      rethrow;
    }
  }

  // ====================== RETIRER FAVORI ======================
  Future<void> removeFavorite(String userId, String movieId) async {
    try {
      await _userFavoritesRef(userId).doc(movieId).delete();
    } catch (e) {
      debugPrint("Error removing favorite: $e");
      rethrow;
    }
  }

  // ====================== EST FAVORI ? ======================
  Future<bool> isFavorite(String userId, String movieId) async {
    try {
      return await _userFavoritesRef(userId)
          .doc(movieId)
          .get()
          .then((doc) => doc.exists);
    } catch (e) {
      debugPrint("Error checking favorite: $e");
      return false;
    }
  }

  // ====================== STREAM TEMPS RÉEL (MAGIQUE) ======================
  Stream<List<Movie>> getFavoriteMoviesStream(String userId) {
    return _userFavoritesRef(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Movie> movies = [];
      for (final doc in snapshot.docs) {
        try {
          final movie = await _movieService.getMovieById(doc.id);
          if (movie != null) movies.add(movie);
        } catch (e) {
          debugPrint("Error loading movie ${doc.id}: $e");
          // Continue loading other movies
        }
      }
      return movies;
    });
  }

  // ====================== FUTURE (compatibilité) ======================
  Future<List<Movie>> getFavoriteMovies(String userId) async {
    try {
      final snapshot = await _userFavoritesRef(userId)
          .orderBy('addedAt', descending: true)
          .get();
      final List<Movie> movies = [];
      
      for (final doc in snapshot.docs) {
        try {
          final movie = await _movieService.getMovieById(doc.id);
          if (movie != null) movies.add(movie);
        } catch (e) {
          debugPrint("Error loading movie ${doc.id}: $e");
          // Continue loading other movies
        }
      }
      return movies;
    } catch (e) {
      debugPrint("Error getting favorite movies: $e");
      return [];
    }
  }

  // ====================== IDS SEULEMENT ======================
  Future<List<String>> getFavoriteMovieIds(String userId) async {
    try {
      final snapshot = await _userFavoritesRef(userId).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint("Error getting favorite movie IDs: $e");
      return [];
    }
  }
}