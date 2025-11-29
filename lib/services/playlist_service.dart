// playlist_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite_model.dart';
import '../models/movie_model.dart';
import 'movie_service.dart';

class PlaylistService {
  // Singleton pattern
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  final CollectionReference _favoritesRef = FirebaseFirestore.instance
      .collection('favorites');

  // -----------------------------------------------------------
  // 1. ADD FAVORITE
  // -----------------------------------------------------------
  Future<void> addFavorite(String userId, String movieId) async {
    try {
      // Check if favorite already exists to avoid duplicates
      final query = await _favoritesRef
          .where('userId', isEqualTo: userId)
          .where('movieId', isEqualTo: movieId)
          .get();

      if (query.docs.isEmpty) {
        final favorite = Favorite(
          id: '',
          userId: userId,
          movieId: movieId,
          addedAt: DateTime.now(),
        );
        await _favoritesRef.add(favorite.toFirestoreMap());
      }
    } catch (e) {
      debugPrint("Error adding favorite: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 2. REMOVE FAVORITE
  // -----------------------------------------------------------
  Future<void> removeFavorite(String userId, String movieId) async {
    try {
      final query = await _favoritesRef
          .where('userId', isEqualTo: userId)
          .where('movieId', isEqualTo: movieId)
          .get();

      for (final doc in query.docs) {
        await _favoritesRef.doc(doc.id).delete();
      }
    } catch (e) {
      debugPrint("Error removing favorite: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 3. GET ALL FAVORITES FOR A USER
  // -----------------------------------------------------------
  Stream<List<Favorite>> getUserFavorites(String userId) {
    return _favoritesRef
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Favorite.fromFirestore(doc)).toList(),
        );
  }

  // -----------------------------------------------------------
  // 4. CHECK IF A MOVIE IS FAVORITE
  // -----------------------------------------------------------
  Future<bool> isFavorite(String userId, String movieId) async {
    final query = await _favoritesRef
        .where('userId', isEqualTo: userId)
        .where('movieId', isEqualTo: movieId)
        .get();

    return query.docs.isNotEmpty;
  }

  // -----------------------------------------------------------
  // OPTIONAL: GET FAVORITE MOVIE IDS (useful for batch fetching movies)
  // -----------------------------------------------------------
  Future<List<String>> getFavoriteMovieIds(String userId) async {
    final query = await _favoritesRef.where('userId', isEqualTo: userId).get();

    return query.docs.map((doc) => doc['movieId'] as String).toList();
  }

  // ------------------------
  // New: Get full Movie objects for a user
  // ------------------------
  Future<List<Movie>> getFavoriteMovies(String userId) async {
    final movieIds = await getFavoriteMovieIds(userId);
    List<Movie> movies = [];

    final movieService = MovieService(); // instance of your service

    for (final id in movieIds) {
      try {
        final movie = await movieService.getMovieDetails(id);
        movies.add(movie);
      } catch (_) {
        // ignore errors for missing movies
      }
    }

    return movies;
  }
}
