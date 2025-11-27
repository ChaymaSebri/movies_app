// lib/services/playlist_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_model.dart';
import '../models/movie_model.dart';
import 'movie_service.dart';

class PlaylistService {
  // Changement important : on stocke les favoris dans une sous-collection par utilisateur
  // → Plus rapide, plus scalable, plus propre
  CollectionReference _userFavoritesRef(String userId) =>
      FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');

  final MovieService _movieService = MovieService();

  // -----------------------------------------------------------
  // 1. AJOUTER AUX FAVORIS
  // -----------------------------------------------------------
  Future<void> addFavorite(String userId, String movieId) async {
    final ref = _userFavoritesRef(userId).doc(movieId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'movieId': movieId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // -----------------------------------------------------------
  // 2. RETIRER DES FAVORIS
  // -----------------------------------------------------------
  Future<void> removeFavorite(String userId, String movieId) async {
    await _userFavoritesRef(userId).doc(movieId).delete();
  }

  // -----------------------------------------------------------
  // 3. VÉRIFIER SI UN FILM EST EN FAVORIS
  // -----------------------------------------------------------
  Future<bool> isFavorite(String userId, String movieId) async {
    final doc = await _userFavoritesRef(userId).doc(movieId).get();
    return doc.exists;
  }

  // -----------------------------------------------------------
  // 4. STREAM EN TEMPS RÉEL DES FILMS FAVORIS (CLÉ MAGIQUE)
  // -----------------------------------------------------------
  Stream<List<Movie>> getFavoriteMoviesStream(String userId) {
    return _userFavoritesRef(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Movie> movies = [];
      for (var doc in snapshot.docs) {
        final movieId = doc.id;
        try {
          final movie = await _movieService.getMovieById(movieId);
          if (movie != null) {
            movies.add(movie);
          }
        } catch (e) {
          // Si le film a été supprimé ou erreur → on ignore
          continue;
        }
      }
      return movies;
    });
  }

  // -----------------------------------------------------------
  // 5. FUTURE (ancienne méthode conservée pour compatibilité)
  // -----------------------------------------------------------
  Future<List<Movie>> getFavoriteMovies(String userId) async {
    final snapshot = await _userFavoritesRef(userId).get();
    final List<Movie> movies = [];

    for (var doc in snapshot.docs) {
      final movieId = doc.id;
      try {
        final movie = await _movieService.getMovieById(movieId);
        if (movie != null) movies.add(await movie);
      } catch (_) {}
    }
    return movies;
  }

  // -----------------------------------------------------------
  // 6. LISTE DES IDS (utile si besoin)
  // -----------------------------------------------------------
  Future<List<String>> getFavoriteMovieIds(String userId) async {
    final snapshot = await _userFavoritesRef(userId).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}