import 'package:flutter/material.dart';
import 'package:movies_app/services/movie_service.dart';

class MatchDetailPage extends StatefulWidget {
  final Map<String, dynamic>? data;

  const MatchDetailPage({super.key, this.data});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  final MovieService _movieService = MovieService();

  Map<String, String> _movieTitles = {};
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
      appBar: AppBar(title: const Text('Match Detail')),
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
            Text('Correspondance: $matchPercentage%'),
            const SizedBox(height: 12),
            const Text(
              'Films en commun:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : commonMovies.isEmpty
                  ? const Text('Aucun film en commun')
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
