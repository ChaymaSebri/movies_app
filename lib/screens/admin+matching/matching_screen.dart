import 'package:flutter/material.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movies_app/services/matching_service.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/admin_service.dart';
import 'package:movies_app/constants/app_routes.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final MatchingService _matchingService = MatchingService();
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSub;

  bool _loading = true;
  bool _isLoadingUser = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMatches();
    _setupFavoritesListener();
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    super.dispose();
  }

  void _setupFavoritesListener() {
    final user = _authService.currentUser;
    if (user != null) {
      _favoritesSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .snapshots()
          .listen((_) => _loadMatches());
    }
  }

  Future<void> _loadCurrentUser() async {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
      return;
    }

    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
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
      if (mounted) {
        setState(() {
          _matches = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Matches'),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : _matches.isEmpty
              ? _buildEmptyState()
              : _buildMatchesList(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        onTap: _handleNavigation,
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
            label: "Matches",
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

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.favorites);
    } else if (index == 3 && _isAdmin) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    }
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
              Icons.people_outline,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'No matches yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add movies to your favorites to find people with similar taste!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
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
              'Discover Movies',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _matches.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _MatchCard(match: match);
      },
    );
  }
}

// ======================== MATCH CARD ========================

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userData = match['userData'] as Map<String, dynamic>? ?? {};

    final firstName = userData['firstName'] as String? ?? '';
    final lastName = userData['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final displayName = name.isEmpty
        ? (userData['email'] as String? ?? match['userId'] ?? 'Unknown User')
        : name;

    final matchPercentage =
        (match['matchPercentage'] as double?)?.toStringAsFixed(1) ?? '0.0';
    final matchScore = match['matchPercentage'] as double? ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.matchDetail,
            arguments: match,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(displayName),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name and match info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$matchPercentage% match',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Match percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getMatchColor(matchScore, colorScheme),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$matchPercentage%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getMatchColor(double score, ColorScheme colorScheme) {
    if (score >= 90) return Colors.green;
    if (score >= 85) return Colors.lightGreen;
    if (score >= 80) return Colors.orange;
    return Colors.deepOrange;
  }
}