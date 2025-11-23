// screens/movie_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/movie_model.dart';
import '../../services/playlist_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;

  const MovieDetailScreen({
    Key? key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
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
    } catch (e) {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  void _toggleFavorite() async {
    setState(() => isLoadingFavorite = true);

    try {
      if (isFavorite) {
        await widget.playlistService.removeFavorite(widget.currentUserId, widget.movie.id);
      } else {
        await widget.playlistService.addFavorite(widget.currentUserId, widget.movie.id);
      }
      if (mounted) setState(() => isFavorite = !isFavorite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur favoris"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    // URLs avec fallback infaillible
    final String backdropUrl = movie.backdropUrl?.isNotEmpty == true
        ? movie.backdropUrl!
        : movie.posterUrl.replaceAll('w500', 'original');

    final String finalBackdrop = backdropUrl.isNotEmpty
        ? backdropUrl
        : "https://picsum.photos/1280/720?blur=2";

    final year = movie.releaseDate?.year.toString() ?? "Inconnue";
    final duration = movie.runtime != null ? "${movie.runtime} min" : "Durée inconnue";
    final rating = movie.rating != null ? movie.rating!.toStringAsFixed(1) : "N/A";

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
                    Colors.black.withOpacity(0.7),
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
                          Shadow(offset: Offset(0, 2), blurRadius: 10, color: Colors.black87),
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
                      const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(year, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(width: 30),
                      const Icon(Icons.access_time_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Genres
                  if (movie.genres.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: movie.genres.map((g) => _buildGenreChip(g)).toList(),
                    ),

                  const SizedBox(height: 30),

                  // Note
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.purpleAccent, width: 4),
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
                            const Icon(Icons.star_rounded, color: Colors.purpleAccent, size: 26),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Note moyenne", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("sur 10", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Synopsis
                  const Text("Synopsis", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    movie.description.isEmpty ? "Aucun synopsis disponible." : movie.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.7),
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
                        side: const BorderSide(color: Colors.purpleAccent, width: 2.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                        shadowColor: Colors.purple.withOpacity(0.4),
                      ),
                      child: isLoadingFavorite
                          ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.purpleAccent),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.purpleAccent : Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
      label: Text(genre, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.purpleAccent.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 3,
    );
  }
}