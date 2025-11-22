// movie_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';

class MovieService {
  final CollectionReference _moviesRef =
  FirebaseFirestore.instance.collection('movies');

  // -----------------------------------------------------------
  // 1. GET ALL MOVIES (Realtime Stream)
  // -----------------------------------------------------------
  Stream<List<Movie>> getMovies() {
    return _moviesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Movie.fromFirestore(doc);
      }).toList();
    });
  }

  // -----------------------------------------------------------
  // 2. ADD MOVIE (Admin Only)
  // -----------------------------------------------------------
  Future<String> addMovie(Movie movie) async {
    try {
      // Use Firestore-friendly map
      final data = movie.toFirestoreMap();

      final docRef = await _moviesRef.add(data);

      return docRef.id; // return the id of the new movie
    } catch (e) {
      print("Error adding movie: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 3. UPDATE MOVIE
  // -----------------------------------------------------------
  Future<void> updateMovie(String movieId, Movie updatedMovie) async {
    try {
      final data = updatedMovie.toFirestoreMap();
      await _moviesRef.doc(movieId).update(data);
    } catch (e) {
      print("Error updating movie: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // 4. DELETE MOVIE (Admin Only)
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
  // OPTIONAL: GET SINGLE MOVIE
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
  // OPTIONAL: SEARCH MOVIES BY TITLE
  // -----------------------------------------------------------
  Stream<List<Movie>> searchMovies(String query) {
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
}
