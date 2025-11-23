import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import '../../constants/api_constants.dart';


class ApiService {
  final String apiKey = ApiConstants.apiKey;

  /// Search movies by query
  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.searchMovies}?api_key=$apiKey&query=$query",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch movies: ${response.statusCode}");
    }
  }

  /// Get popular movies
  Future<List<Movie>> getPopularMovies() async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.popularMovies}?api_key=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results.map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch popular movies: ${response.statusCode}");
    }
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.topRatedMovies}?api_key=$apiKey");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch top rated movies");
    }
  }

  Future<List<Movie>> getUpcomingMovies() async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.upcomingMovies}?api_key=$apiKey");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => Movie.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch upcoming movies");
    }
  }
}
