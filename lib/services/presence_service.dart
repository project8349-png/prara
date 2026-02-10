import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _heartbeat;

  Future<void> goOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('Users').doc(user.uid).update({'online': true, 'lastSeen': FieldValue.serverTimestamp()});
    _startHeartbeat(user.uid);
  }

  Future<void> goOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('Users').doc(user.uid).update({'online': false, 'lastSeen': FieldValue.serverTimestamp()});
    _stopHeartbeat();
  }

  void _startHeartbeat(String uid) {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _db.collection('Users').doc(uid).update({'lastSeen': FieldValue.serverTimestamp(), 'online': true});
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  // Typing indicators: write a small doc under Typing/{chatId}/{uid}
  Future<void> setTyping(String chatId, bool typing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _db.collection('Typing').doc(chatId).collection('users').doc(user.uid);
    if (typing) {
      await ref.set({'userId': user.uid, 'timestamp': FieldValue.serverTimestamp(), 'typing': true});
    } else {
      // remove doc
      await ref.delete().catchError((_) {});
    }
  }

  Stream<QuerySnapshot> typingStream(String chatId) {
    return _db.collection('Typing').doc(chatId).collection('users').snapshots();
  }
}
