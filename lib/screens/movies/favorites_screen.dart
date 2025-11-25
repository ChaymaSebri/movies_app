// screens/favorites_screen.dart
import 'package:flutter/material.dart';
import '../../../services/playlist_service.dart';
import '../../../services/movie_service.dart';
import '../../models/movie_model.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String currentUserId;
  const FavoritesScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final MovieService _movieService = MovieService();
  late Future<List<Movie>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = _playlistService.getFavoriteMovies(widget.currentUserId);
  }

  void _refresh() => setState(_loadFavorites);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Ma Playlist",
          style: TextStyle(color: Colors.purple, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Movie>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.56,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return FavoriteMovieCard(
                movie: movie,
                currentUserId: widget.currentUserId,
                playlistService: _playlistService,
                movieService: _movieService,
                onRemoved: _refresh,
                onFavoriteChanged: _refresh, // <-- CLÉ MAGIQUE
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_border, size: 48, color: Colors.purple),
          ),
          const SizedBox(height: 30),
          const Text("Aucun favori", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Ajoute des films avec le cœur", style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Découvrir des films", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// CARTE IDENTIQUE À DISCOVER + CALLBACK POUR RAFRAÎCHIR
class FavoriteMovieCard extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;
  final MovieService movieService;
  final VoidCallback onRemoved;
  final VoidCallback onFavoriteChanged; // <-- NOUVEAU

  const FavoriteMovieCard({
    Key? key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
    required this.movieService,
    required this.onRemoved,
    required this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<FavoriteMovieCard> createState() => _FavoriteMovieCardState();
}

class _FavoriteMovieCardState extends State<FavoriteMovieCard> {
  bool isHovered = false;

  String get posterUrl => widget.movie.posterUrl.isNotEmpty
      ? widget.movie.posterUrl
      : "https://picsum.photos/500/750?random=${widget.movie.id}";

  void _removeFromFavorites() async {
    await widget.playlistService.removeFavorite(widget.currentUserId, widget.movie.id);
    widget.onRemoved();
    widget.onFavoriteChanged(); // <-- Rafraîchit la liste
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.movie.title} retiré des favoris"),
          backgroundColor: Colors.purple[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.movie.releaseDate?.year.toString() ?? "N/A";
    final rating = widget.movie.rating?.toStringAsFixed(1) ?? "N/A";

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          try {
            final fullMovie = await widget.movieService.getMovieDetails(widget.movie.id);
            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(
                  movie: fullMovie,
                  currentUserId: widget.currentUserId,
                  playlistService: widget.playlistService,
                  onFavoriteChanged: widget.onFavoriteChanged,
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur : $e")),
            );
          }
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: isHovered ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      posterUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                        color: Colors.grey[800],
                        height: 260,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple)),
                      ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 260,
                        color: Colors.grey[850],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isHovered ? Colors.purple : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(year, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            // Note
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // Bouton supprimer
            Positioned(
              bottom: 80,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32, shadows: [Shadow(blurRadius: 12, color: Colors.black54)]),
                onPressed: _removeFromFavorites,
              ),
            ),
          ],
        ),
      ),
    );
  }
}