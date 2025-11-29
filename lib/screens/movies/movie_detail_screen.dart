// movie_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../models/movie_model.dart';
import '../../../services/playlist_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/movie_service.dart';
import '../../../constants/app_routes.dart';

class MovieDetailScreen extends StatefulWidget {
  // Only accept movieId - simpler and cleaner
  final String? movieId;
  final VoidCallback? onFavoriteChanged;

  const MovieDetailScreen({Key? key, this.movieId, this.onFavoriteChanged})
    : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // Use singleton instances
  final _authService = AuthService();
  final _playlistService = PlaylistService();
  final _movieService = MovieService();

  bool isFavorite = false;
  bool isLoadingFavorite = true;
  String? _currentUserId;
  bool _isLoadingUser = true;
  Movie? _movie;
  bool _isLoadingMovie = true;
  String? _errorMessage;

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
    // Get movieId from widget or route arguments
    final movieId =
        widget.movieId ??
        (ModalRoute.of(context)?.settings.arguments as Map?)?['movieId']
            as String?;

    if (movieId == null) {
      setState(() {
        _errorMessage = "Aucun ID de film fourni";
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
          _errorMessage = "Erreur lors du chargement du film";
          _isLoadingMovie = false;
        });
      }
    }
  }

  Future<void> _checkFavorite() async {
    if (_currentUserId == null || _movie == null) return;

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
    if (_currentUserId == null || _movie == null) return;

    setState(() => isLoadingFavorite = true);
    try {
      if (isFavorite) {
        await _playlistService.removeFavorite(_currentUserId!, _movie!.id);
      } else {
        await _playlistService.addFavorite(_currentUserId!, _movie!.id);
      }

      if (mounted) {
        setState(() => isFavorite = !isFavorite);
      }

      widget.onFavoriteChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? "Ajouté aux favoris !" : "Retiré des favoris",
            ),
            backgroundColor: isFavorite ? Colors.purple[700] : Colors.grey[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur favoris"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking user or loading movie
    if (_isLoadingUser || _isLoadingMovie) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    // User not logged in (should not happen due to redirect)
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Erreur d'authentification",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Error loading movie or movie not found
    if (_movie == null || _errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? "Film introuvable",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final movie = _movie!;
    final String backdropUrl = movie.backdropUrl?.isNotEmpty == true
        ? movie.backdropUrl!
        : movie.posterUrl.replaceAll('w500', 'original');
    final String finalBackdrop = backdropUrl.isNotEmpty
        ? backdropUrl
        : "https://picsum.photos/1280/720?blur=2";

    final year = movie.releaseDate?.year.toString() ?? "Inconnue";
    final duration = movie.runtime != null
        ? "${movie.runtime} min"
        : "Durée inconnue";
    final rating = movie.rating != null
        ? movie.rating!.toStringAsFixed(1)
        : "N/A";

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === BACKDROP ===
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        shadows: [
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
                  // Année + Durée
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        year,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 30),
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.grey,
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
                          .map((g) => _buildGenreChip(g))
                          .toList(),
                    ),

                  const SizedBox(height: 30),

                  // Note
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.purpleAccent,
                            width: 4,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              rating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.purpleAccent,
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Note moyenne",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "sur 10",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Synopsis
                  const Text(
                    "Synopsis",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.description.isEmpty
                        ? "Aucun synopsis disponible."
                        : movie.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Bouton Favoris
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isLoadingFavorite ? null : _toggleFavorite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.purpleAccent,
                          width: 2.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.purple.withAlpha(
                          (0.4 * 255).round(),
                        ),
                      ),
                      child: isLoadingFavorite
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.purpleAccent,
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
                                      ? Colors.purpleAccent
                                      : Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  isFavorite
                                      ? "Retirer des favoris"
                                      : "Ajouter aux favoris",
                                  style: const TextStyle(
                                    fontSize: 19,
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

  Widget _buildGenreChip(String genre) {
    return Chip(
      label: Text(
        genre,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.purpleAccent.withAlpha((0.85 * 255).round()),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 3,
    );
  }
}
