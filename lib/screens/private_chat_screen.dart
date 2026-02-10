import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateChatScreen extends StatefulWidget {
  final String chatId;
  final String peerName;
  const PrivateChatScreen({super.key, required this.chatId, required this.peerName});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final ChatService _chat = ChatService();
  final _ctrl = TextEditingController();
  Timer? _typingTimer;
  final PresenceService _presence = PresenceService();

  void _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // fetch sender profile
    final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    final me = doc.data();
    final msg = {
      'from': user.uid,
      'fromName': me?['name'] ?? user.email ?? user.uid,
      'fromPhoto': me?['photoUrl'],
      'text': _ctrl.text.trim(),
      'to': widget.chatId.replaceAll(user.uid + '_', ''),
      'delivered': false,
      'seen': false,
    };
    await _chat.sendPrivateMessage(widget.chatId, msg);
    _ctrl.clear();
    // stop typing
    _typingTimer?.cancel();
    await _presence.setTyping(widget.chatId, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(children: [
        Expanded(
          child: StreamBuilder(
            stream: _chat.privateChatStream(widget.chatId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              // Mark delivered & seen where appropriate
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                if (d['to'] == uid && (d['delivered'] == null || d['delivered'] == false)) {
                  _chat.markDelivered(widget.chatId, docId);
                }
                if (d['to'] == uid && (d['seen'] == null || d['seen'] == false)) {
                  // mark seen when messages are shown in this chat
                  _chat.markSeen(widget.chatId, docId);
                }
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map<String, dynamic>;
                  final isMine = d['from'] == uid;
                  Widget? leading;
                  Widget? trailing;
                  if (!isMine && d['fromPhoto'] != null) leading = CircleAvatar(backgroundImage: NetworkImage(d['fromPhoto']));
                  if (isMine && d['fromPhoto'] != null) trailing = CircleAvatar(backgroundImage: NetworkImage(d['fromPhoto']));
                  return ListTile(
                    leading: leading,
                    trailing: trailing,
                    title: Align(alignment: isMine ? Alignment.centerRight : Alignment.centerLeft, child: Text(d['text'] ?? '')),
                    subtitle: Align(alignment: isMine ? Alignment.centerRight : Alignment.centerLeft, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(d['fromName'] ?? ''), const SizedBox(width: 8), if (isMine) Icon(d['seen'] == true ? Icons.done_all : (d['delivered'] == true ? Icons.done : Icons.access_time), size: 16)])),
                  );
                },
              );
            },
          ),
        ),
          Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            StreamBuilder(
              stream: _presence.typingStream(widget.chatId),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final docs = snap.data!.docs;
                final others = docs.where((d) => d.id != FirebaseAuth.instance.currentUser?.uid).map((d) => (d.data() as Map<String,dynamic>)['userId']).toList();
                if (others.isEmpty) return const SizedBox.shrink();
                return Align(alignment: Alignment.centerLeft, child: Text('${others.length == 1 ? 'Typing...' : 'Several people typing...'}'));
              },
            ),
            Row(children: [
              Expanded(child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(hintText: 'Message'),
                onChanged: (v) async {
                  await _presence.setTyping(widget.chatId, true);
                  _typingTimer?.cancel();
                  _typingTimer = Timer(const Duration(seconds: 2), () async { await _presence.setTyping(widget.chatId, false); });
                },
              )),
              IconButton(onPressed: _send, icon: const Icon(Icons.send))
            ])
          ]),
        )
      ]),
    );
  }
}
