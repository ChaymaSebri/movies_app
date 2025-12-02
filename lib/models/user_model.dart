import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final int age;
  final String email;
  final String? photoUrl;
  final bool isActive;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.age,
    required this.email,
    this.photoUrl,
    this.isActive = true,
    this.role = 'user',
    required this.createdAt,
  });

  // Convertir depuis Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      age: data['age'] ?? 0,
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'age': age,
      'email': email,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // CopyWith pour modification
  UserModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    int? age,
    String? email,
    String? photoUrl,
    bool? isActive,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      age: age ?? this.age,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nom: $nom, prenom: $prenom, email: $email)';
  }
}