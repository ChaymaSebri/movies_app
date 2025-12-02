// lib/screens/movies_list_screen.dart
import 'package:flutter/material.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/admin_service.dart';
import 'package:movies_app/services/user_service.dart';
import 'package:movies_app/services/movie_service.dart';
import 'package:movies_app/services/playlist_service.dart';
import 'package:movies_app/models/movie_model.dart';
import 'package:movies_app/constants/app_routes.dart';

import 'movie_detail_screen.dart';
import 'favorites_screen.dart';

class MoviesListScreen extends StatefulWidget {
  final String currentUserId;
  const MoviesListScreen({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final UserService _userService = UserService();

  final MovieService _movieService = MovieService();
  final PlaylistService _playlistService = PlaylistService();

  late TabController _tabController;

  String _searchQuery = "";
  String? _currentUserId;
  String? userPhotoUrl;
  bool _isLoadingUser = true;
  bool _isAdmin = false;

  late Future<List<Movie>> _popularFuture;
  late Future<List<Movie>> _topRatedFuture;
  late Future<List<Movie>> _upcomingFuture;

  final List<String> _categories = ['Popular', 'Top Rated', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _loadCurrentUser();

    _popularFuture = _movieService.getPopularMovies();
    _topRatedFuture = _movieService.getTopRatedMovies();
    _upcomingFuture = _movieService.getUpcomingMovies();
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
      final user = await _userService.getUserById(userId);
      final isAdmin = await _adminService.isCurrentUserAdmin();

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        userPhotoUrl = user?.photoUrl;
        _isAdmin = isAdmin;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userPhotoUrl = null;
        _isLoadingUser = false;
      });
    }
  }

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
          child: Text(
            "Authentication error",
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          "MovieMates",
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  backgroundImage: (userPhotoUrl != null &&
                          userPhotoUrl!.isNotEmpty)
                      ? NetworkImage(userPhotoUrl!)
                      : null,
                  child: (userPhotoUrl == null || userPhotoUrl!.isEmpty)
                      ? Icon(Icons.person,
                          color: colorScheme.onSurface, size: 24)
                      : null,
                ),
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Search for a movie...",
                    hintStyle: TextStyle(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(Icons.search,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: "Popular"),
                  Tab(text: "Top Rated"),
                  Tab(text: "Upcoming"),
                ],
                labelColor: colorScheme.primary,
                unselectedLabelColor:
                    colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 4,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovieGrid(_popularFuture),
          _buildMovieGrid(_topRatedFuture),
          _buildMovieGrid(_upcomingFuture),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor:
            colorScheme.onSurface.withValues(alpha: 0.5),
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FavoritesScreen(currentUserId: widget.currentUserId)),
            );
          }
          if (i == 2) {
            Navigator.pushNamed(context, AppRoutes.matching);
          }
          if (i == 3 && _isAdmin) {
            Navigator.pushNamed(context, AppRoutes.adminDashboard);
          }
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.search), label: "Discover"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorites"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Matching"),
          if (_isAdmin)
            const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: "Admin"),
        ],
      ),
    );
  }

  // ======= MOVIES GRID =======
  Widget _buildMovieGrid(Future<List<Movie>> future) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Movie>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator(color: colorScheme.primary));
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Text(
              "No movies found",
              style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          );
        }

        var movies = snap.data!;
        if (_searchQuery.isNotEmpty) {
          movies = movies
              .where((m) =>
                  m.title.toLowerCase().contains(_searchQuery))
              .toList();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.56,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: movies.length,
          itemBuilder: (context, i) => MovieGridCard(
            movie: movies[i],
            currentUserId: widget.currentUserId,
            playlistService: _playlistService,
            movieService: _movieService,
          ),
        );
      },
    );
  }
}

// ==================== MOVIE GRID CARD (merged + stable) ====================
class MovieGridCard extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;
  final MovieService movieService;

  const MovieGridCard({
    Key? key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
    required this.movieService,
  }) : super(key: key);

  @override
  State<MovieGridCard> createState() => _MovieGridCardState();
}

class _MovieGridCardState extends State<MovieGridCard> {
  bool isFavorite = false;
  bool isHovered = false;
  bool isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final fav = await widget.playlistService
        .isFavorite(widget.currentUserId, widget.movie.id);
    if (mounted) setState(() => isFavorite = fav);
  }

  void _toggleFavorite() async {
    setState(() => isLoadingFavorite = true);
    try {
      if (isFavorite) {
        await widget.playlistService
            .removeFavorite(widget.currentUserId, widget.movie.id);
      } else {
        await widget.playlistService
            .addFavorite(widget.currentUserId, widget.movie.id);
      }
      setState(() => isFavorite = !isFavorite);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error updating favorites"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } finally {
      setState(() => isLoadingFavorite = false);
    }
  }

  String get posterUrl =>
      widget.movie.posterUrl.isNotEmpty
          ? widget.movie.posterUrl.replaceAll(
              '/upload/',
              '/upload/w_500,c_limit,q_auto,f_auto/')
          : "https://picsum.photos/500/750?random=${widget.movie.id}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final year = widget.movie.releaseDate?.year.toString() ?? "N/A";
    final rating =
        widget.movie.rating?.toStringAsFixed(1) ?? "N/A";

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final fullMovie =
              await widget.movieService.getMovieDetails(widget.movie.id);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(
                movie: fullMovie,
                currentUserId: widget.currentUserId,
                playlistService: widget.playlistService,
              ),
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
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Favorite button
            Positioned(
              bottom: 80,
              right: 8,
              child: IconButton(
                iconSize: 32,
                icon: isLoadingFavorite
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        shadows: const [
                          Shadow(
                              blurRadius: 12, color: Colors.black54)
                        ],
                      ),
                onPressed: isLoadingFavorite ? null : _toggleFavorite,
              ),
            )
          ],
        ),
      ),
    );
  }
}
