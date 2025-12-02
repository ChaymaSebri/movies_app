import 'package:flutter/material.dart';
import 'package:movies_app/services/playlist_service.dart';
import 'package:movies_app/services/movie_service.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/admin_service.dart';
import 'package:movies_app/models/movie_model.dart';
import 'package:movies_app/constants/app_routes.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String currentUserId;
  const FavoritesScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final PlaylistService _playlistService = PlaylistService();
  final MovieService _movieService = MovieService();

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    try {
      _isAdmin = await _adminService.isCurrentUserAdmin();
      setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("My Playlist"),
      ),

      body: StreamBuilder<List<Movie>>(
        stream: _playlistService.getFavoriteMoviesStream(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
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
                onRemoved: () => setState(() {}),
                onFavoriteChanged: () => setState(() {}),
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
          if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.matching);
          }
          if (index == 3 && _isAdmin) {
            Navigator.pushNamed(context, AppRoutes.adminDashboard);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Discover",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Matching",
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Admin",
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "No favorites yet",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Add movies with the heart icon",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Discover Movies",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== FAVORITE MOVIE CARD ========================

class FavoriteMovieCard extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;
  final MovieService movieService;
  final VoidCallback onRemoved;
  final VoidCallback onFavoriteChanged;

  const FavoriteMovieCard({
    super.key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
    required this.movieService,
    required this.onRemoved,
    required this.onFavoriteChanged,
  });

  @override
  State<FavoriteMovieCard> createState() => _FavoriteMovieCardState();
}

class _FavoriteMovieCardState extends State<FavoriteMovieCard> {
  bool isHovered = false;

  String get posterUrl {
    final url = widget.movie.posterUrl;
    if (url.contains('cloudinary.com')) {
      return url.replaceAll('/upload/', '/upload/w_500,c_limit,q_auto,f_auto/');
    }
    return url.isNotEmpty ? url : "https://picsum.photos/500/750?random=${widget.movie.id}";
  }

  void _removeFromFavorites() async {
    await widget.playlistService.removeFavorite(
      widget.currentUserId,
      widget.movie.id,
    );

    widget.onRemoved();
    widget.onFavoriteChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.movie.title} removed from favorites"),
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
                Text(
                  year,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 80,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                onPressed: _removeFromFavorites,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
