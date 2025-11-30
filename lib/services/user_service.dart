import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movies_app/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // Create a user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw 'Error while creating user: $e';
    }
  }

  // Get a user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error while retrieving user: $e';
    }
  }

  // Get a user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw 'Error while searching for user: $e';
    }
  }

  // Update an entire user document
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw 'Error while updating user: $e';
    }
  }

  // Update specific fields of a user
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .update(fields);
    } catch (e) {
      throw 'Error while updating fields: $e';
    }
  }

  // Stream to listen to live changes of a user
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error while retrieving users: $e';
    }
  }

  // Check if an email already exists
  Future<bool> emailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Error while checking email: $e';
    }
  }
}