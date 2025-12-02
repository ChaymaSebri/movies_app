// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class ApiService {
  final String apiKey = ApiConstants.apiKey;

  // ==================== LISTES (retourne des Map) ====================
  Future<List<Map<String, dynamic>>> _fetchList(String endpoint) async {
    final url = Uri.parse("$endpoint?api_key=$apiKey&language=fr-FR");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      throw Exception("Erreur ${response.statusCode} : $endpoint");
    }
  }

  Future<List<Map<String, dynamic>>> getPopularMovies() async =>
      _fetchList("${ApiConstants.baseUrl}${ApiConstants.popularMovies}");

  Future<List<Map<String, dynamic>>> getTopRatedMovies() async =>
      _fetchList("${ApiConstants.baseUrl}${ApiConstants.topRatedMovies}");

  Future<List<Map<String, dynamic>>> getUpcomingMovies() async =>
      _fetchList("${ApiConstants.baseUrl}${ApiConstants.upcomingMovies}");

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.searchMovies}?api_key=$apiKey&query=${Uri.encodeComponent(query)}&language=fr-FR",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      throw Exception("Recherche échouée");
    }
  }

  // ==================== DÉTAILS D'UN FILM (retourne un Map) ====================
  Future<Map<String, dynamic>> getMovieDetails(String movieId) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/movie/$movieId?api_key=$apiKey&language=fr-FR",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Détails introuvables pour le film $movieId");
    }
  }
}