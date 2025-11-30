import 'package:flutter/material.dart';
import 'package:movies_app/services/matching_service.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/constants/app_routes.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  final MatchingService _matchingService = MatchingService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _matches = [];
        _loading = false;
      });
      return;
    }

    try {
      final results = await _matchingService.findMatchesForUser(user.uid);
      setState(() {
        _matches = results;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
          ? const Center(child: Text('Aucun match trouvé'))
          : ListView.separated(
              itemCount: _matches.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final match = _matches[index];
                final userData =
                    match['userData'] as Map<String, dynamic>? ?? {};
                final name =
                    '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                        .trim();
                final percent =
                    (match['matchPercentage'] as double?)?.toStringAsFixed(1) ??
                    '0.0';

                return ListTile(
                  title: Text(
                    name.isEmpty
                        ? (userData['email'] ?? match['userId'])
                        : name,
                  ),
                  subtitle: Text('Correspondance: $percent%'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.matchDetail,
                      arguments: match,
                    );
                  },
                );
              },
            ),
    );
  }
}
