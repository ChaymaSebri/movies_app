import 'package:flutter/material.dart';
import 'package:movies_app/services/movie_service.dart';

class MatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  const MatchDetailScreen({super.key, this.data});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final MovieService _movieService = MovieService();

  final Map<String, String> _movieTitles = {};
  bool _loading = true;

  late final Map<String, dynamic>? _args;

  @override
  void initState() {
    super.initState();
    _args =
        widget.data ??
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _loadTitles();
  }

  Future<void> _loadTitles() async {
    final commonMovies = List<String>.from(_args?['commonMovies'] ?? []);
    for (final id in commonMovies) {
      try {
        // Try Firestore first
        final movie = await _movieService.getMovieById(id);
        if (movie != null) {
          _movieTitles[id] = movie.title;
          continue;
        }

        // Fallback to API
        final apiMovie = await _movieService.getMovieDetails(id);
        _movieTitles[id] = apiMovie.title.isNotEmpty ? apiMovie.title : id;
      } catch (_) {
        _movieTitles[id] = id;
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final userData = args?['userData'] as Map<String, dynamic>? ?? {};
    final commonMovies = List<String>.from(args?['commonMovies'] ?? []);
    final matchPercentage =
        (args?['matchPercentage'] as double?)?.toStringAsFixed(1) ?? '0.0';

    final name = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
        .trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Match Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? (userData['email'] ?? '') : name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Match Percentage: $matchPercentage%'),
            const SizedBox(height: 12),
            const Text(
              'Common movies:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : commonMovies.isEmpty
                  ? const Text('No common movies found.')
                  : ListView.separated(
                      itemCount: commonMovies.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final movieId = commonMovies[index];
                        final title = _movieTitles[movieId] ?? movieId;
                        return ListTile(title: Text(title));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
