// services/movie_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';
import './api_service.dart';

class MovieService {
  // Singleton pattern
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  final CollectionReference _moviesRef = FirebaseFirestore.instance.collection('movies');
  final ApiService _apiService = ApiService();

  // ====================== CACHE DES LISTES ======================
  List<Movie>? _cachedPopular;
  List<Movie>? _cachedTopRated;
  List<Movie>? _cachedUpcoming;

  Future<List<Movie>>? _popularFuture;
  Future<List<Movie>>? _topRatedFuture;
  Future<List<Movie>>? _upcomingFuture;

  // ====================== LISTES CACHÉES ======================
  Future<List<Movie>> getPopularMovies() async {
    if (_cachedPopular != null) return _cachedPopular!;
    if (_popularFuture != null) return _popularFuture!;

    _popularFuture = _apiService.getPopularMovies().then((rawList) {
      final movies = rawList.map((json) => Movie.fromJson(json)).toList();
      _cachedPopular = movies;
      _popularFuture = null;
      return movies;
    }).catchError((e) {
      _popularFuture = null;
      throw e;
    });

    return _popularFuture!;
  }

  Future<List<Movie>> getTopRatedMovies() async {
    if (_cachedTopRated != null) return _cachedTopRated!;
    if (_topRatedFuture != null) return _topRatedFuture!;

    _topRatedFuture = _apiService.getTopRatedMovies().then((rawList) {
      final movies = rawList.map((json) => Movie.fromJson(json)).toList();
      _cachedTopRated = movies;
      _topRatedFuture = null;
      return movies;
    }).catchError((e) {
      _topRatedFuture = null;
      throw e;
    });

    return _topRatedFuture!;
  }

  Future<List<Movie>> getUpcomingMovies() async {
    if (_cachedUpcoming != null) return _cachedUpcoming!;
    if (_upcomingFuture != null) return _upcomingFuture!;

    _upcomingFuture = _apiService.getUpcomingMovies().then((rawList) {
      final movies = rawList.map((json) => Movie.fromJson(json)).toList();
      _cachedUpcoming = movies;
      _upcomingFuture = null;
      return movies;
    }).catchError((e) {
      _upcomingFuture = null;
      throw e;
    });

    return _upcomingFuture!;
  }

  void clearCache() {
    _cachedPopular = _cachedTopRated = _cachedUpcoming = null;
    _popularFuture = _topRatedFuture = _upcomingFuture = null;
  }

  // ====================== DÉTAILS D'UN FILM ======================
  Future<Movie> getMovieDetails(String movieId) async {
    final json = await _apiService.getMovieDetails(movieId);
    return Movie.fromJson(json);
  }

  // ====================== FIRESTORE ======================
  Stream<List<Movie>> getMovies() {
    return _moviesRef.snapshots().map(
          (snapshot) => snapshot.docs.map(Movie.fromFirestore).toList(),
    );
  }

  Future<Movie?> getMovieById(String movieId) async {
    final doc = await _moviesRef.doc(movieId).get();
    if (!doc.exists) return null;
    return Movie.fromFirestore(doc);
  }

  Future<void> syncApiMovieToFirestore(Movie movie) async {
    await _moviesRef.doc(movie.id).set(movie.toFirestoreMap(), SetOptions(merge: true));
  }
}