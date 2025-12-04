// lib/screens/movie_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:movies_app/models/movie_model.dart';
import 'package:movies_app/services/movie_service.dart';
import 'package:movies_app/services/playlist_service.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/constants/app_routes.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({Key? key}) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final AuthService _authService = AuthService();
  final MovieService _movieService = MovieService();
  final PlaylistService _playlistService = PlaylistService();

  String? _currentUserId;
  Movie? _movie;
  bool _isLoadingUser = true;
  bool _isLoadingMovie = true;
  String? _errorMessage;

  bool isFavorite = false;
  bool isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUserId != null) {
      await _loadMovieDetails();
      if (_movie != null) {
        await _checkFavorite();
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
      return;
    }
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadMovieDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final movieId = args?['movieId'] as String?;

    if (movieId == null) {
      setState(() {
        _errorMessage = "No movie ID provided";
        _isLoadingMovie = false;
      });
      return;
    }

    try {
      final movie = await _movieService.getMovieDetails(movieId);
      if (mounted) {
        setState(() {
          _movie = movie;
          _isLoadingMovie = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading movie details";
          _isLoadingMovie = false;
        });
      }
    }
  }

  Future<void> _checkFavorite() async {
    if (_movie == null || _currentUserId == null) return;

    try {
      final fav = await _playlistService.isFavorite(
        _currentUserId!,
        _movie!.id,
      );
      if (mounted) {
        setState(() {
          isFavorite = fav;
          isLoadingFavorite = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  void _toggleFavorite() async {
    if (_movie == null || _currentUserId == null) return;

    setState(() => isLoadingFavorite = true);
    try {
      if (isFavorite) {
        await _playlistService.removeFavorite(_currentUserId!, _movie!.id);
      } else {
        await _playlistService.addFavorite(_currentUserId!, _movie!.id);
      }
      if (mounted) setState(() => isFavorite = !isFavorite);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? "Added to favorites!" : "Removed from favorites",
            ),
            backgroundColor: isFavorite 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Favorites error"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading while checking user or loading movie
    if (_isLoadingUser || _isLoadingMovie) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // User not logged in (should not happen due to redirect)
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            "Authentication error",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    // Error loading movie or movie not found
    if (_movie == null || _errorMessage != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? "Movie not found",
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
          ),
        ),
      );
    }

    final movie = _movie!;

    // Backdrop URL logic (TMDB + Cloudinary)
    String getBackdropUrl() {
      if (movie.backdropUrl != null && movie.backdropUrl!.isNotEmpty) {
        return movie.backdropUrl!;
      }
      // Otherwise, generate a large poster based on source
      final poster = movie.posterUrl;
      if (poster.contains('cloudinary.com')) {
        return poster.replaceAll('/upload/', '/upload/w_1280,c_limit,q_auto,f_auto/');
      } else if (poster.contains('image.tmdb.org') || poster.contains('themoviedb.org')) {
        return poster.replaceAll(RegExp(r'w\d+'), 'original');
      } else {
        return poster;
      }
    }

    final String finalBackdrop = getBackdropUrl();
    final year = movie.releaseDate?.year.toString() ?? "Unknown";
    final duration = movie.runtime != null ? "${movie.runtime} min" : "Unknown duration";
    final rating = movie.rating != null ? movie.rating!.toStringAsFixed(1) : "N/A";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === BACKDROP IMAGE ===
            Container(
              height: 440,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(finalBackdrop),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha((0.7 * 255).round()),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Text(
                      movie.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 10,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Year + Duration
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        year,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Icon(
                        Icons.access_time_rounded,
                        color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Genres
                  if (movie.genres.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: movie.genres
                          .map((g) => _buildGenreChip(g, colorScheme))
                          .toList(),
                    ),
                  const SizedBox(height: 30),
                  // Rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              rating,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.star_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Average rating",
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "out of 10",
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Synopsis
                  Text(
                    "Synopsis",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.description.isEmpty
                        ? "No synopsis available."
                        : movie.description,
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Favorites Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: isLoadingFavorite ? null : _toggleFavorite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: colorScheme.primary.withAlpha(
                          (0.4 * 255).round(),
                        ),
                      ),
                      child: isLoadingFavorite
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: colorScheme.primary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  isFavorite
                                      ? "Remove from favorites"
                                      : "Add to favorites",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        genre,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colorScheme.primary.withAlpha((0.85 * 255).round()),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      elevation: 3,
    );
  }
}