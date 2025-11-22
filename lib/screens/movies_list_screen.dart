import 'package:flutter/material.dart';
import '../../services/movie_service.dart';
import '../../services/playlist_service.dart';
import '../models/movie_model.dart';
import '../models/favorite_model.dart';

class MoviesListScreen extends StatefulWidget {
  final String currentUserId;

  const MoviesListScreen({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  final MovieService _movieService = MovieService();
  final PlaylistService _playlistService = PlaylistService();

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movies"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search movies...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Movie>>(
        stream: _movieService.searchMovies(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No movies found"));
          }

          final movies = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                movie: movie,
                currentUserId: widget.currentUserId,
                playlistService: _playlistService,
              );
            },
          );
        },
      ),
    );
  }
}

class MovieCard extends StatefulWidget {
  final Movie movie;
  final String currentUserId;
  final PlaylistService playlistService;

  const MovieCard({
    Key? key,
    required this.movie,
    required this.currentUserId,
    required this.playlistService,
  }) : super(key: key);

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final fav = await widget.playlistService
        .isFavorite(widget.currentUserId, widget.movie.id);
    setState(() {
      isFavorite = fav;
    });
  }

  void _toggleFavorite() async {
    if (isFavorite) {
      await widget.playlistService
          .removeFavorite(widget.currentUserId, widget.movie.id);
    } else {
      await widget.playlistService
          .addFavorite(widget.currentUserId, widget.movie.id);
    }
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: widget.movie.posterUrl.isNotEmpty
            ? Image.network(
          widget.movie.posterUrl,
          width: 50,
          fit: BoxFit.cover,
        )
            : const SizedBox(width: 50),
        title: Text(widget.movie.title),
        subtitle: Text("Rating: ${widget.movie.rating ?? 'N/A'}"),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
          onPressed: _toggleFavorite,
        ),
        onTap: () {
          // Optional: Navigate to movie details page
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Clicked on ${widget.movie.title}")));
        },
      ),
    );
  }
}
