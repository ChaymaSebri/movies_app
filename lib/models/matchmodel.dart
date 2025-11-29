import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String userId1;
  final String userId2;
  final double matchPercentage;
  final List<String> commonMovies;
  final DateTime? lastCalculated;

  Match({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchPercentage,
    required this.commonMovies,
    this.lastCalculated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'matchPercentage': matchPercentage,
      'commonMovies': commonMovies,
      'lastCalculated': lastCalculated != null
          ? Timestamp.fromDate(lastCalculated!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final last = data['lastCalculated'];
    DateTime? lastDt;
    if (last != null && last is Timestamp) {
      lastDt = last.toDate();
    }

    return Match(
      id: doc.id,
      userId1: (data['userId1'] ?? '') as String,
      userId2: (data['userId2'] ?? '') as String,
      matchPercentage: ((data['matchPercentage'] ?? 0) as num).toDouble(),
      commonMovies: List<String>.from(data['commonMovies'] ?? []),
      lastCalculated: lastDt,
    );
  }
}
