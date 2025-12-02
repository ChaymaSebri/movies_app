import 'package:flutter/material.dart';
import '../../models/movie_model.dart';
import '../../services/playlist_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;
  final VoidCallback? onFavoriteChanged;

  const MovieDetailScreen({
    Key? key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
    this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;
  bool isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final fav = await widget.playlistService.isFavorite(
        widget.currentUserId,
        widget.movie.id,
      );
      if (mounted) {
        setState(() {
          isFavorite = fav;
          isLoadingFavorite = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  void _toggleFavorite() async {
    setState(() => isLoadingFavorite = true);

    try {
      if (isFavorite) {
        await widget.playlistService.removeFavorite(
          widget.currentUserId,
          widget.movie.id,
        );
      } else {
        await widget.playlistService.addFavorite(
          widget.currentUserId,
          widget.movie.id,
        );
      }

      if (mounted) setState(() => isFavorite = !isFavorite);
      widget.onFavoriteChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? "Ajouté aux favoris !"
                  : "Retiré des favoris",
            ),
            backgroundColor:
                isFavorite ? Colors.purple[700] : Colors.grey[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
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

  // === BACKDROP LOGIC FROM YOUR FRIEND (KEEP THIS) ===
  String _getBackdropUrl(Movie movie) {
    if (movie.backdropUrl != null && movie.backdropUrl!.isNotEmpty) {
      return movie.backdropUrl!;
    }

    final poster = movie.posterUrl;

    if (poster.contains('cloudinary.com')) {
      return poster.replaceAll(
        '/upload/',
        '/upload/w_1280,c_limit,q_auto,f_auto/',
      );
    } else if (poster.contains('image.tmdb.org') ||
        poster.contains('themoviedb.org')) {
      return poster.replaceAll(RegExp(r'w\d+'), 'original');
    } else {
      return poster;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final finalBackdrop = _getBackdropUrl(movie);
    final year = movie.releaseDate?.year.toString() ?? "Inconnue";
    final duration =
        movie.runtime != null ? "${movie.runtime} min" : "Durée inconnue";
    final rating =
        movie.rating != null ? movie.rating!.toStringAsFixed(1) : "N/A";

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
            // Backdrop
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
                  // Year + Duration
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(year,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(width: 30),
                      const Icon(Icons.access_time_rounded,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(duration,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Genres
                  if (movie.genres.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          movie.genres.map((g) => _buildGenreChip(g)).toList(),
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
                            style:
                                TextStyle(color: Colors.grey, fontSize: 16),
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

                  // Favorite Button
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
                        shadowColor:
                            Colors.purple.withAlpha((0.4 * 255).round()),
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
