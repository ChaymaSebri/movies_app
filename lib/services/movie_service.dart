// lib/services/movie_service.dart
// VERSION FINALE ULTIME → Singleton + Cache partagé + Films manuels parfaits
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';
import './api_service.dart';

class MovieService {
  // ====================== SINGLETON (garde ça !) ======================
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  // ====================== RÉFÉRENCES ======================
  final CollectionReference _moviesRef = FirebaseFirestore.instance.collection('movies');
  final ApiService _apiService = ApiService();

  // ====================== CACHE API (maintenant partagé partout !) ======================
  List<Movie>? _cachedPopular;
  List<Movie>? _cachedTopRated;
  List<Movie>? _cachedUpcoming;

  // ====================== ANCIENNES MÉTHODES (compatibilité) ======================
  Future<List<Movie>> getPopularMovies() async {
    if (_cachedPopular != null) return _cachedPopular!;
    final raw = await _apiService.getPopularMovies();
    _cachedPopular = raw.map((json) => Movie.fromJson(json)).toList();
    return _cachedPopular!;
  }

  Future<List<Movie>> getTopRatedMovies() async {
    if (_cachedTopRated != null) return _cachedTopRated!;
    final raw = await _apiService.getTopRatedMovies();
    _cachedTopRated = raw.map((json) => Movie.fromJson(json)).toList();
    return _cachedTopRated!;
  }

  Future<List<Movie>> getUpcomingMovies() async {
    if (_cachedUpcoming != null) return _cachedUpcoming!;
    final raw = await _apiService.getUpcomingMovies();
    _cachedUpcoming = raw.map((json) => Movie.fromJson(json)).toList();
    return _cachedUpcoming!;
  }

  Future<Movie> getMovieDetails(String movieId) async {
    final doc = await _moviesRef.doc(movieId).get();
    if (doc.exists) {
      return Movie.fromFirestore(doc);
    }
    final json = await _apiService.getMovieDetails(movieId);
    return Movie.fromJson(json);
  }

  // ====================== NOUVELLES MÉTHODES (fusion manuels + API) ======================
  Stream<List<Movie>> getMoviesByCategory(String category) {
    return _moviesRef
        .where('category', isEqualTo: category)
        .snapshots()
        .asyncMap((snapshot) async {
      final manualMovies = snapshot.docs.map(Movie.fromFirestore).toList();

      List<Movie> apiMovies = [];
      switch (category) {
        case 'Popular':
          apiMovies = await getPopularMovies();
          break;
        case 'Top Rated':
          apiMovies = await getTopRatedMovies();
          break;
        case 'Upcoming':
          apiMovies = await getUpcomingMovies();
          break;
      }

      final Map<String, Movie> map = {};
      for (var m in apiMovies) map[m.id] = m;
      for (var m in manualMovies) map[m.id] = m; // manuel écrase API

      return map.values.toList();
    });
  }

  Stream<List<Movie>> getAllMovies() {
    return _moviesRef.snapshots().map((s) => s.docs.map(Movie.fromFirestore).toList());
  }

  Future<Movie?> getMovieById(String id) async {
    final doc = await _moviesRef.doc(id).get();
    if (doc.exists) return Movie.fromFirestore(doc);
    try {
      return await getMovieDetails(id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _cachedPopular = _cachedTopRated = _cachedUpcoming = null;
  }
}