import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:movies_app/models/matchmodel.dart';

// Lower-case constant name to follow linter conventions
const double minMatchPercentage = 75.0;

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseFirestore _firestore declared below

  // Calculer le pourcentage de correspondance entre deux listes de films
  double calculateMatchPercentage(
    List<String> userMovies,
    List<String> otherUserMovies,
  ) {
    if (userMovies.isEmpty || otherUserMovies.isEmpty) {
      return 0.0;
    }

    // Trouver les films en commun
    final commonMovies = userMovies
        .where((movie) => otherUserMovies.contains(movie))
        .toList();

    // Calculer le pourcentage basé sur l'union des deux listes
    final totalUniqueMovies = {...userMovies, ...otherUserMovies}.length;

    if (totalUniqueMovies == 0) return 0.0;

    return (commonMovies.length / totalUniqueMovies) * 100;
  }

  // Trouver les films en commun
  List<String> findCommonMovies(
    List<String> userMovies,
    List<String> otherUserMovies,
  ) {
    return userMovies
        .where((movie) => otherUserMovies.contains(movie))
        .toList();
  }

  // Trouver tous les matches pour un utilisateur
  Future<List<Map<String, dynamic>>> findMatchesForUser(String userId) async {
    try {
      // Récupérer l'utilisateur actuel
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!currentUserDoc.exists) {
        throw Exception('Utilisateur non trouvé');
      }

      final currentUserData = currentUserDoc.data()!;
      final currentUserMovies = List<String>.from(
        currentUserData['favoriteMovies'] ?? [],
      );

      // Récupérer tous les autres utilisateurs actifs
      final usersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> matches = [];

      for (var userDoc in usersSnapshot.docs) {
        // Ignorer l'utilisateur actuel
        if (userDoc.id == userId) continue;

        final otherUserData = userDoc.data();
        final otherUserMovies = List<String>.from(
          otherUserData['favoriteMovies'] ?? [],
        );

        // Calculer le pourcentage de correspondance
        final matchPercentage = calculateMatchPercentage(
          currentUserMovies,
          otherUserMovies,
        );

        // Ne garder que les matches >= seuil configurable
        if (matchPercentage >= minMatchPercentage) {
          final commonMovies = findCommonMovies(
            currentUserMovies,
            otherUserMovies,
          );

          matches.add({
            'userId': userDoc.id,
            'userData': otherUserData,
            'matchPercentage': matchPercentage,
            'commonMovies': commonMovies,
          });
        }
      }

      // Trier par pourcentage décroissant
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

  // Sauvegarder un match dans la collection (optionnel - pour cache)
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

  // Récupérer un match existant
  Future<Match?> getMatch(String userId1, String userId2) async {
    try {
      final matchDoc = await _firestore
          .collection('matches')
          .doc('${userId1}_$userId2')
          .get();

      if (matchDoc.exists) {
        return Match.fromFirestore(matchDoc);
      }

      // Essayer l'inverse
      final reverseMatchDoc = await _firestore
          .collection('matches')
          .doc('${userId2}_$userId1')
          .get();

      if (reverseMatchDoc.exists) {
        return Match.fromFirestore(reverseMatchDoc);
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du match: $e');
      return null;
    }
  }

  // Recalculer tous les matches d'un utilisateur
  Future<void> recalculateMatchesForUser(String userId) async {
    try {
      final matches = await findMatchesForUser(userId);

      for (var matchData in matches) {
        final match = Match(
          id: '${userId}_${matchData['userId']}',
          userId1: userId,
          userId2: matchData['userId'],
          matchPercentage: (matchData['matchPercentage'] as num).toDouble(),
          commonMovies: List<String>.from(matchData['commonMovies'] ?? []),
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
