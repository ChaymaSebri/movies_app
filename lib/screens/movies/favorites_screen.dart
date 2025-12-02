import 'package:flutter/material.dart';
import 'package:movies_app/services/playlist_service.dart';
import 'package:movies_app/services/movie_service.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/admin_service.dart';
import 'package:movies_app/models/movie_model.dart';
import 'package:movies_app/constants/app_routes.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final PlaylistService _playlistService = PlaylistService();
  final MovieService _movieService = MovieService();

  late Future<List<Movie>> _favoritesFuture;
  String? _currentUserId;
  bool _isLoadingUser = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
      return;
    }

    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();

      setState(() {
        _currentUserId = userId;
        _isAdmin = isAdmin;
        _isLoadingUser = false;
      });

      _loadFavorites();
    } catch (_) {
      setState(() {
        _currentUserId = userId;
        _isLoadingUser = false;
      });
      _loadFavorites();
    }
  }

  void _loadFavorites() {
    if (_currentUserId != null) {
      _favoritesFuture = _playlistService.getFavoriteMovies(_currentUserId!);
    }
  }

  void _refresh() => setState(_loadFavorites);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingUser) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text("Authentication error", style: theme.textTheme.bodyLarge),
        ),
      );
    }

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
      body: FutureBuilder<List<Movie>>(
        future: _favoritesFuture,
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
                currentUserId: _currentUserId!,
                playlistService: _playlistService,
                movieService: _movieService,
                onRemoved: _refresh,
                onFavoriteChanged: _refresh,
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }

          if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.matching);
            return;
          }

          if (index == 3 && _isAdmin) {
            Navigator.pushNamed(context, AppRoutes.adminDashboard);
            return;
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
              color: colorScheme.primary.withValues(alpha: 0.2),
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
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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

  String get posterUrl => widget.movie.posterUrl.isNotEmpty
      ? widget.movie.posterUrl
      : "https://picsum.photos/500/750?random=${widget.movie.id}";

  void _removeFromFavorites() async {
    final theme = Theme.of(context);
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
          backgroundColor: theme.colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final year = widget.movie.releaseDate?.year.toString() ?? "N/A";
    final rating = widget.movie.rating?.toStringAsFixed(1) ?? "N/A";

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movieId: widget.movie.id),
            ),
          );
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
                              color: colorScheme.surfaceContainerHighest,
                              height: 260,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                      errorBuilder: (_, _, _) => Container(
                        height: 260,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isHovered
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  year,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            // Rating badge
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
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
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

            // Remove button
            Positioned(
              bottom: 80,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurface,
                  size: 32,
                  shadows: const [
                    Shadow(blurRadius: 12, color: Colors.black54),
                  ],
                ),
                onPressed: _removeFromFavorites,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
