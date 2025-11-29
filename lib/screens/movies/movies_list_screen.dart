import 'package:flutter/material.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/movie_service.dart';
import 'package:movies_app/services/playlist_service.dart';
import 'package:movies_app/services/user_service.dart';
import 'package:movies_app/models/movie_model.dart';
import 'package:movies_app/constants/app_routes.dart';
import 'movie_detail_screen.dart';
import 'favorites_screen.dart';

class MoviesListScreen extends StatefulWidget {
  const MoviesListScreen({super.key});

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final MovieService _movieService = MovieService();
  final PlaylistService _playlistService = PlaylistService();

  late TabController _tabController;

  String _searchQuery = "";
  String? _currentUserId;
  String? userPhotoUrl;
  bool _isLoadingUser = true;

  late final Future<List<Movie>> _popularFuture;
  late final Future<List<Movie>> _topRatedFuture;
  late final Future<List<Movie>> _upcomingFuture;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _tabController = TabController(length: 3, vsync: this);

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

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        userPhotoUrl = user?.photoUrl;
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text(
            "Erreur d'authentification",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          "MOVIES",
          style: TextStyle(
            color: Colors.purple,
            fontSize: 26,
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
                backgroundColor: Colors.purple.withAlpha((0.2 * 255).round()),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                      (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                      ? NetworkImage(userPhotoUrl!)
                      : null,
                  child: (userPhotoUrl == null || userPhotoUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Rechercher un film...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
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
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.purple,
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
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
            return;
          }

          // Navigate to matching page when tapping the Matching tab
          if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.matching);
            return;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoris"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Matching"),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(Future<List<Movie>> future) {
    return FutureBuilder<List<Movie>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Aucun film", style: TextStyle(color: Colors.white70)),
          );
        }

        var movies = snapshot.data!;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery;
          movies = movies
              .where((m) => m.title.toLowerCase().contains(query))
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
            currentUserId: _currentUserId!,
            playlistService: _playlistService,
            movieService: _movieService,
          ),
        );
      },
    );
  }
}

// ======================== MOVIE GRID CARD ========================

class MovieGridCard extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;
  final MovieService movieService;

  const MovieGridCard({
    super.key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
    required this.movieService,
  });

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
    try {
      final fav = await widget.playlistService.isFavorite(
        widget.currentUserId,
        widget.movie.id,
      );
      if (mounted) setState(() => isFavorite = fav);
    } catch (_) {}
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de la modification des favoris"),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingFavorite = false);
    }
  }

  String get posterUrl => widget.movie.posterUrl.isNotEmpty
      ? widget.movie.posterUrl
      : "https://picsum.photos/500/750?random=${widget.movie.id}";

  @override
  Widget build(BuildContext context) {
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
                              color: Colors.grey[800],
                              height: 260,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 260,
                        color: Colors.grey[850],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
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
                  style: TextStyle(
                    color: isHovered ? Colors.purple : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  year,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            // ⭐ Rating
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

            // ❤️ Favorite button
            Positioned(
              bottom: 80,
              right: 8,
              child: IconButton(
                iconSize: 32,
                icon: isLoadingFavorite
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.purple,
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.purple : Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 12, color: Colors.black54),
                        ],
                      ),
                onPressed: isLoadingFavorite ? null : _toggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
