import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:movies_app/models/matchmodel.dart';

const double minMatchPercentage = 75.0;

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper: read favorite movie IDs from the user's `favorites` subcollection.
  Future<List<String>> _getFavoriteIdsForUser(String userId) async {
    try {
      final favSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      return favSnapshot.docs.map((d) => d.id).toList();
    } catch (e) {
      debugPrint('Error fetching favorites for $userId: $e');
      return [];
    }
  }

  // Calculates Jaccard similarity (common / union) as percentage.
  double calculateMatchPercentage(
    List<String> userMovies,
    List<String> otherUserMovies,
  ) {
    if (userMovies.isEmpty || otherUserMovies.isEmpty) return 0.0;

    final common = userMovies.where((m) => otherUserMovies.contains(m)).length;
    final union = {...userMovies, ...otherUserMovies}.length;
    if (union == 0) return 0.0;
    return (common / union) * 100.0;
  }

  List<String> findCommonMovies(List<String> a, List<String> b) {
    return a.where((m) => b.contains(m)).toList();
  }

  // Find all matches for a user by reading favorites from favorites subcollections.
  Future<List<Map<String, dynamic>>> findMatchesForUser(String userId) async {
    try {
      // Get current user's favorite ids from subcollection
      final currentUserMovies = await _getFavoriteIdsForUser(userId);

      // Get all active users
      final usersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> matches = [];

      for (var userDoc in usersSnapshot.docs) {
        if (userDoc.id == userId) continue;

        // Read other user's favorites from their subcollection
        final otherUserMovies = await _getFavoriteIdsForUser(userDoc.id);

        final matchPercentage = calculateMatchPercentage(
          currentUserMovies,
          otherUserMovies,
        );

        if (matchPercentage >= minMatchPercentage) {
          final commonMovies = findCommonMovies(
            currentUserMovies,
            otherUserMovies,
          );
          matches.add({
            'userId': userDoc.id,
            'userData': userDoc.data(),
            'matchPercentage': matchPercentage,
            'commonMovies': commonMovies,
          });
        }
      }

      matches.sort(
        (a, b) => (b['matchPercentage'] as double).compareTo(
          a['matchPercentage'] as double,
        ),
      );

      return matches;
    } catch (e) {
      debugPrint('Erreur lors de la recherche de matches: $e');
      rethrow;
    }
  }

  // Save and retrieval methods kept for compatibility (optional caching)
  Future<void> saveMatch(Match match) async {
    try {
      await _firestore
          .collection('matches')
          .doc('${match.userId1}_${match.userId2}')
          .set(match.toFirestore());
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du match: $e');
      rethrow;
    }
  }

  Future<Match?> getMatch(String userId1, String userId2) async {
    try {
      final matchDoc = await _firestore
          .collection('matches')
          .doc('${userId1}_$userId2')
          .get();
      if (matchDoc.exists) return Match.fromFirestore(matchDoc);

      final reverse = await _firestore
          .collection('matches')
          .doc('${userId2}_$userId1')
          .get();
      if (reverse.exists) return Match.fromFirestore(reverse);

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du match: $e');
      return null;
    }
  }

  Future<void> recalculateMatchesForUser(String userId) async {
    try {
      final matches = await findMatchesForUser(userId);
      for (var m in matches) {
        final match = Match(
          id: '${userId}_${m['userId']}',
          userId1: userId,
          userId2: m['userId'],
          matchPercentage: (m['matchPercentage'] as num).toDouble(),
          commonMovies: List<String>.from(m['commonMovies'] ?? []),
          lastCalculated: DateTime.now(),
        );
        await saveMatch(match);
      }
    } catch (e) {
      debugPrint('Erreur lors du recalcul des matches: $e');
      rethrow;
    }
  }
}
