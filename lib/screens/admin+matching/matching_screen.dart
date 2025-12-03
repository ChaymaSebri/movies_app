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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? Center(
                  child: Text(
                    'No matches found',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
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
                        (match['matchPercentage'] as double?)
                                ?.toStringAsFixed(1) ??
                            '0.0';

                    return ListTile(
                      title: Text(
                        name.isEmpty
                            ? (userData['email'] ?? match['userId'])
                            : name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        'Match: $percent%',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        currentIndex: 2, // Matching tab is selected
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }

          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/favorites');
            return;
          }

          // index == 2 is already selected (Matching)

          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
            return;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Admin"),
        ],
      ),
    );
  }
}