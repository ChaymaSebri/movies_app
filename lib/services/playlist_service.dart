// lib/services/playlist_service.dart
// VERSION ABSOLUMENT PARFAITE — Garde ça pour toujours
import 'package:cloud_firestore/cloud_firestore.dart';
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
    await _userFavoritesRef(userId).doc(movieId).set({
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge: true → plus safe
  }

  // ====================== RETIRER FAVORI ======================
  Future<void> removeFavorite(String userId, String movieId) async {
    await _userFavoritesRef(userId).doc(movieId).delete();
  }

  // ====================== EST FAVORI ? ======================
  Future<bool> isFavorite(String userId, String movieId) async {
    return await _userFavoritesRef(userId).doc(movieId).get().then((doc) => doc.exists);
  }

  // ====================== STREAM TEMPS RÉEL (MAGIQUE) ======================
  Stream<List<Movie>> getFavoriteMoviesStream(String userId) {
    return _userFavoritesRef(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Movie> movies = [];
      for (final doc in snapshot.docs) {
        final movie = await _movieService.getMovieById(doc.id);
        if (movie != null) movies.add(movie);
      }
      return movies;
    });
  }

  // ====================== FUTURE (compatibilité) ======================
  Future<List<Movie>> getFavoriteMovies(String userId) async {
    final snapshot = await _userFavoritesRef(userId).get();
    final List<Movie> movies = [];
    for (final doc in snapshot.docs) {
      final movie = await _movieService.getMovieById(doc.id);
      if (movie != null) movies.add(movie);
    }
    return movies;
  }

  // ====================== IDS SEULEMENT ======================
  Future<List<String>> getFavoriteMovieIds(String userId) async {
    final snapshot = await _userFavoritesRef(userId).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}