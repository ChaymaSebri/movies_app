import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:movies_app/services/auth_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // FIXED: Vérifier si l'utilisateur actuel est admin
  Future<bool> isCurrentUserAdmin() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return false;
    
    return await isAdmin(userId);
  }

  // FIXED: Vérifier si un utilisateur est admin par son ID
  Future<bool> isAdmin(String userId) async {
    try {
      // Use get() to avoid threading issues
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;
      
      return data['role'] == 'admin' || data['isAdmin'] == true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification admin: $e');
      return false;
    }
  }

  // Récupérer tous les utilisateurs
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des utilisateurs: $e');
      rethrow;
    }
  }

  // FIXED: Récupérer les utilisateurs avec pagination (now returns proper Stream)
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    }).handleError((error) {
      debugPrint('Erreur dans getUsersStream: $error');
      return <Map<String, dynamic>>[];
    });
  }

  // Désactiver un utilisateur
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur lors de la désactivation: $e');
      rethrow;
    }
  }

  // Activer un utilisateur
  Future<void> activateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
        'deactivatedAt': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'activation: $e');
      rethrow;
    }
  }

  // Basculer le statut d'un utilisateur
  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    if (currentStatus) {
      await deactivateUser(userId);
    } else {
      await activateUser(userId);
    }
  }

  // Ajouter un film à la base de données
  Future<String> addMovie(Map<String, dynamic> movieData) async {
    try {
      final docRef = await _firestore.collection('movies').add({
        ...movieData,
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': 'admin',
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du film: $e');
      rethrow;
    }
  }

  // FIXED: Obtenir les statistiques du dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Nombre total d'utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.size;

      // Nombre d'utilisateurs actifs
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();
      final activeUsers = activeUsersSnapshot.size;

      // Nombre total de films
      final moviesSnapshot = await _firestore.collection('movies').get();
      final totalMovies = moviesSnapshot.size;

      // Nombre de matches
      final matchesSnapshot = await _firestore.collection('matches').get();
      final totalMatches = matchesSnapshot.size;

      // Film le plus populaire
      Map<String, int> movieCount = {};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final favoriteMovies = List<String>.from(data['favoriteMovies'] ?? []);
        for (var movieId in favoriteMovies) {
          movieCount[movieId] = (movieCount[movieId] ?? 0) + 1;
        }
      }

      String? mostPopularMovie;
      int maxCount = 0;
      movieCount.forEach((movieId, count) {
        if (count > maxCount) {
          maxCount = count;
          mostPopularMovie = movieId;
        }
      });

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'inactiveUsers': totalUsers - activeUsers,
        'totalMovies': totalMovies,
        'totalMatches': totalMatches,
        'mostPopularMovie': mostPopularMovie,
        'mostPopularMovieCount': maxCount,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques: $e');
      rethrow;
    }
  }

  // Rechercher des utilisateurs
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final results = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final firstName = (data['firstName'] ?? data['prenom'] ?? '')
                .toString()
                .toLowerCase();
            final lastName = (data['lastName'] ?? data['nom'] ?? '')
                .toString()
                .toLowerCase();
            final searchQuery = query.toLowerCase();

            return firstName.contains(searchQuery) ||
                lastName.contains(searchQuery);
          })
          .map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          })
          .toList();

      return results;
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      rethrow;
    }
  }

  // Promouvoir un utilisateur en admin
  Future<void> promoteToAdmin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'isAdmin': true,
      });
    } catch (e) {
      debugPrint('Erreur lors de la promotion en admin: $e');
      rethrow;
    }
  }
}