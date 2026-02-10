import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = ChatService();
    final _ctrl = TextEditingController();
    Map<String, dynamic>? me;
    final PresenceService _presence = PresenceService();
    Timer? _typingTimer;

    Future<void> _loadMe() async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      me = doc.data();
    }
    _loadMe();
    return Scaffold(
      appBar: AppBar(title: const Text('Study Community')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chat.groupMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: data['fromPhoto'] != null ? CircleAvatar(backgroundImage: NetworkImage(data['fromPhoto'])) : null,
                      title: Text(data['fromName'] ?? 'Unknown'),
                      subtitle: Text(data['text'] ?? ''),
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
                  stream: _presence.typingStream('group'),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final docs = snap.data!.docs;
                    final others = docs.where((d) => d.id != FirebaseAuth.instance.currentUser?.uid).map((d) => (d.data() as Map<String,dynamic>)['userId']).toList();
                    if (others.isEmpty) return const SizedBox.shrink();
                    return Align(alignment: Alignment.centerLeft, child: Text('${others.length == 1 ? 'Someone is typing...' : 'Several people typing...'}'));
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(hintText: 'Message...'),
                        onChanged: (v) async {
                          await _presence.setTyping('group', true);
                          _typingTimer?.cancel();
                          _typingTimer = Timer(const Duration(seconds: 2), () async { await _presence.setTyping('group', false); });
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;
                        if (me == null) {
                          final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
                          me = doc.data();
                        }
                        final text = _ctrl.text.trim();
                        final msg = {
                          'from': uid,
                          'fromName': me?['name'] ?? uid,
                          'fromPhoto': me?['photoUrl'],
                          'text': text,
                        };
                        if (text.isNotEmpty) {
                          await chat.sendGroupMessage(msg);
                          _ctrl.clear();
                          await _presence.setTyping('group', false);
                        }
                      },
                      icon: const Icon(Icons.send),
                    )
                  ],
                ),
              ]),
            )
        ],
      ),
    );
  }
}
