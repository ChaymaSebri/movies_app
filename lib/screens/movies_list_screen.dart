// screens/movies_list_screen.dart
import 'package:flutter/material.dart';
import '../../services/movie_service.dart';
import '../../services/playlist_service.dart';
import '../models/movie_model.dart';

class MoviesListScreen extends StatefulWidget {
  final String currentUserId;
  const MoviesListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen>
    with SingleTickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  final PlaylistService _playlistService = PlaylistService();

  late TabController _tabController;
  String _searchQuery = "";

  final List<Tab> _tabs = const [
    Tab(text: "Popular"),
    Tab(text: "Top Rated"),
    Tab(text: "Upcoming"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          "MOVIES",
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                "https://via.placeholder.com/150",
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
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: _tabs,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.red,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: Colors.red, width: 4),
                  insets: EdgeInsets.symmetric(horizontal: 40),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovieFutureGrid(_movieService.getPopularMovies()),
          _buildMovieFutureGrid(_movieService.getTopRatedMovies()),
          _buildMovieFutureGrid(_movieService.getUpcomingMovies()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoris"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Matching"),
        ],
      ),
    );
  }

  Widget _buildMovieFutureGrid(Future<List<Movie>> movieFuture) {
    return FutureBuilder<List<Movie>>(
      future: movieFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No movies found", style: TextStyle(color: Colors.white)),
          );
        }

        final movies = snapshot.data!;
        final filtered = _searchQuery.isEmpty
            ? movies
            : movies
            .where((m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.56,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return MovieGridCard(
              movie: filtered[index],
              currentUserId: widget.currentUserId,
              playlistService: _playlistService,
            );
          },
        );
      },
    );
  }
}

// Make sure MovieGridCard is **outside** of the State class
class MovieGridCard extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;

  const MovieGridCard({
    Key? key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
  }) : super(key: key);

  @override
  State<MovieGridCard> createState() => _MovieGridCardState();
}

class _MovieGridCardState extends State<MovieGridCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final fav = await widget.playlistService.isFavorite(widget.currentUserId, widget.movie.id);
    if (mounted) setState(() => isFavorite = fav);
  }

  void _toggleFavorite() async {
    if (isFavorite) {
      await widget.playlistService.removeFavorite(widget.currentUserId, widget.movie.id);
    } else {
      await widget.playlistService.addFavorite(widget.currentUserId, widget.movie.id);
    }
    setState(() => isFavorite = !isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.movie.releaseDate?.year.toString() ?? "N/A";
    final rating = widget.movie.rating?.toStringAsFixed(1) ?? "N/A";

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.movie.posterUrl.isNotEmpty
                    ? widget.movie.posterUrl
                    : "https://via.placeholder.com/500x750?text=No+Image",
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              year,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 8,
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
              shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
            ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
    );
  }
}
