import 'package:cloud_firestore/cloud_firestore.dart';

class GoalsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> goalsFor(String uid) {
    return _db.collection('Goals').where('userId', isEqualTo: uid).snapshots();
  }

  Future<void> setGoal(String uid, String period, double targetHours) async {
    final q = await _db.collection('Goals').where('userId', isEqualTo: uid).where('period', isEqualTo: period).get();
    final data = {'userId': uid, 'period': period, 'targetStudyHours': targetHours, 'createdAt': FieldValue.serverTimestamp()};
    if (q.docs.isNotEmpty) {
      await _db.collection('Goals').doc(q.docs.first.id).update(data);
    } else {
      await _db.collection('Goals').add(data);
    }
  }

  Future<DocumentSnapshot?> getGoalOnce(String uid, String period) async {
    final q = await _db.collection('Goals').where('userId', isEqualTo: uid).where('period', isEqualTo: period).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first;
  }
}
