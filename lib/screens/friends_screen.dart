import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final bool online = d['online'] ?? false;
              final lastSeen = d['lastSeen'];
              String status = '';
              if (online) status = 'Online';
              else if (lastSeen != null) {
                final dt = (lastSeen as Timestamp).toDate();
                status = 'Last seen ${_timeAgo(dt)}';
              }

              final avatar = d['photoUrl'] != null
                  ? CircleAvatar(backgroundImage: NetworkImage(d['photoUrl']))
                  : CircleAvatar(child: Text(d['name'] != null ? d['name'][0] : '?'));

              return ListTile(
                isThreeLine: true,
                leading: Stack(children: [
                  avatar,
                  if (online)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)),
                      ),
                    ),
                ]),
                title: Text(d['name'] ?? ''),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['username'] ?? ''), const SizedBox(height: 4), Text(status, style: TextStyle(fontSize: 12, color: online ? Colors.green : Colors.grey))]),
                trailing: ElevatedButton(onPressed: () {}, child: const Text('Add')),
              );
            },
          );
        },
      ),
    );
  }
}
