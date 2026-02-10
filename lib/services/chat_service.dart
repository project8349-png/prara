import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> groupMessagesStream() {
    return _db.collection('GroupMessages').orderBy('createdAt', descending: false).snapshots();
  }

  Stream<QuerySnapshot> privateChatStream(String chatId) {
    return _db.collection('Messages').doc(chatId).collection('Threads').orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> sendGroupMessage(Map<String, dynamic> msg) async {
    await _db.collection('GroupMessages').add({...msg, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> sendPrivateMessage(String chatId, Map<String, dynamic> msg) async {
    await _db.collection('Messages').doc(chatId).collection('Threads').add({...msg, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> markDelivered(String chatId, String messageId) async {
    await _db.collection('Messages').doc(chatId).collection('Threads').doc(messageId).update({'delivered': true, 'deliveredAt': FieldValue.serverTimestamp()});
  }

  Future<void> markSeen(String chatId, String messageId) async {
    await _db.collection('Messages').doc(chatId).collection('Threads').doc(messageId).update({'seen': true, 'seenAt': FieldValue.serverTimestamp()});
  }
}
