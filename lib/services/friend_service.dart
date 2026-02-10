import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> discoverUsers() => _db.collection('Users').snapshots();

  Future<void> sendRequest(String fromUid, String toUid) async {
    final ref = _db.collection('FriendRequests').doc();
    await ref.set({
      'from': fromUid,
      'to': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptRequest(String requestId) async {
    final req = await _db.collection('FriendRequests').doc(requestId).get();
    if (!req.exists) return;
    final data = req.data()!;
    await _db.collection('Friends').add({'userA': data['from'], 'userB': data['to'], 'createdAt': FieldValue.serverTimestamp()});
    await _db.collection('FriendRequests').doc(requestId).update({'status': 'accepted'});
  }

  Future<void> rejectRequest(String requestId) async {
    await _db.collection('FriendRequests').doc(requestId).update({'status': 'rejected'});
  }

  Stream<QuerySnapshot> incomingRequests(String uid) {
    return _db.collection('FriendRequests').where('to', isEqualTo: uid).where('status', isEqualTo: 'pending').snapshots();
  }

  Stream<QuerySnapshot> friendsOf(String uid) {
    return _db.collection('Friends').where('userA', isEqualTo: uid).snapshots();
  }
}
