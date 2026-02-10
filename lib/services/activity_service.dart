import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> dailyStream(String uid) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return _db.collection('DailyActivity').where('userId', isEqualTo: uid).orderBy('date', descending: true).snapshots();
  }

  Future<void> addOrUpdate(DailyActivity act) async {
    // Look for doc with same userId & date
    final q = await _db.collection('DailyActivity').where('userId', isEqualTo: act.userId).where('date', isEqualTo: act.date).get();
    if (q.docs.isNotEmpty) {
      await _db.collection('DailyActivity').doc(q.docs.first.id).update(act.toMap());
    } else {
      await _db.collection('DailyActivity').add(act.toMap());
    }
  }

  Future<List<DailyActivity>> fetchRange(String uid, DateTime from, DateTime to) async {
    final snaps = await _db.collection('DailyActivity').where('userId', isEqualTo: uid).where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(to)).get();
    return snaps.docs.map((d) => DailyActivity.fromDoc(d)).toList();
  }
}
