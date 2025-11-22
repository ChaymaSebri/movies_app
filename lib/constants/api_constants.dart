class ApiConstants {
  // TMDB base URL
  static const String baseUrl = "https://api.themoviedb.org/3";

  //  TMDB API key
  static const String apiKey = "7ffc38531685c82f4e4e0c3e42fa7602";

  // Endpoints
  static const String searchMovies = "/search/movie";
  static const String popularMovies = "/movie/popular";
  static const String movieDetails = "/movie"; // append /{movie_id}
}
