// movie_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';
import './api_service.dart';

class MovieService {
  final CollectionReference _moviesRef =
  FirebaseFirestore.instance.collection('movies');

  final ApiService _apiService = ApiService();

  // -----------------------------------------------------------
  // 1. GET ALL MOVIES (Realtime Stream)
  // -----------------------------------------------------------
  Stream<List<Movie>> getMovies() {
    return _moviesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Movie.fromFirestore(doc))
          .toList();
    });
  }

  // -----------------------------------------------------------
  // 2. SEARCH MOVIES (Uses TMDB API)
  // -----------------------------------------------------------
  Stream<List<Movie>> searchMovies(String query) {
    return Stream.fromFuture(_searchMoviesFromApi(query));
  }

  // -----------------------------------------------------------
  // 3. POPULAR / TOP RATED / UPCOMING (Use Future, not Stream)
  // -----------------------------------------------------------
  Future<List<Movie>> getPopularMovies() {
    return _apiService.getPopularMovies();
  }

  Future<List<Movie>> getTopRatedMovies() {
    return _apiService.getTopRatedMovies();
  }

  Future<List<Movie>> getUpcomingMovies() {
    return _apiService.getUpcomingMovies();
  }

  // Helper method for searching API
  Future<List<Movie>> _searchMoviesFromApi(String query) async {
    try {
      if (query.isEmpty) {
        return await _apiService.getPopularMovies();
      } else {
        return await _apiService.searchMovies(query);
      }
    } catch (e) {
      print("Error fetching movies from API: $e");

      // fallback to Firestore
      try {
        final snapshot = await _moviesRef.get();
        final allMovies =
        snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();

        if (query.isEmpty) return allMovies;

        return allMovies
            .where((movie) =>
            movie.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } catch (firestoreError) {
        print("Firestore fallback failed: $firestoreError");
        return [];
      }
    }
  }

  // -----------------------------------------------------------
  // 4. ADD MOVIE (Admin Only)
  // -----------------------------------------------------------
  Future<String> addMovie(Movie movie) async {
    try {
      final data = movie.toFirestoreMap();
      final docRef = await _moviesRef.add(data);
      return docRef.id;
    } catch (e) {
      print("Error adding movie: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 5. UPDATE MOVIE
  // -----------------------------------------------------------
  Future<void> updateMovie(String movieId, Movie updatedMovie) async {
    try {
      await _moviesRef.doc(movieId).update(updatedMovie.toFirestoreMap());
    } catch (e) {
      print("Error updating movie: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 6. DELETE MOVIE (Admin Only)
  // -----------------------------------------------------------
  Future<void> deleteMovie(String movieId) async {
    try {
      await _moviesRef.doc(movieId).delete();
    } catch (e) {
      print("Error deleting movie: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 7. GET SINGLE MOVIE
  // -----------------------------------------------------------
  Future<Movie?> getMovieById(String movieId) async {
    try {
      final doc = await _moviesRef.doc(movieId).get();
      if (!doc.exists) return null;
      return Movie.fromFirestore(doc);
    } catch (e) {
      print("Error fetching movie by id: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 8. SEARCH ONLY FROM FIRESTORE (Admin Dashboard)
  // -----------------------------------------------------------
  Stream<List<Movie>> searchMoviesFromFirestore(String query) {
    if (query.isEmpty) return getMovies();

    return _moviesRef.snapshots().map((snapshot) {
      final allMovies =
      snapshot.docs.map((d) => Movie.fromFirestore(d)).toList();

      return allMovies
          .where((movie) =>
          movie.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // -----------------------------------------------------------
  // 9. SYNC API MOVIE TO FIRESTORE (Favorites Feature)
  // -----------------------------------------------------------
  Future<String> syncApiMovieToFirestore(Movie apiMovie) async {
    try {
      // check if exists
      final query = await _moviesRef
          .where('title', isEqualTo: apiMovie.title)
          .where('source', isEqualTo: 'api')
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      final movieToAdd = Movie(
        id: '',
        title: apiMovie.title,
        description: apiMovie.description,
        posterUrl: apiMovie.posterUrl,
        genre: apiMovie.genre,
        releaseDate: apiMovie.releaseDate,
        rating: apiMovie.rating,
        source: 'api',
        addedBy: null,
      );

      final docRef = await _moviesRef.add(movieToAdd.toFirestoreMap());
      return docRef.id;
    } catch (e) {
      print("Error syncing API movie: $e");
      rethrow;
    }
  }
}
