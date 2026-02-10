import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'activity_log_screen.dart';
import 'goals_screen.dart';
import '../services/activity_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final actSvc = ActivityService();
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityLogScreen())), child: const Text('Log Today'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())), child: const Text('Goals'))),
          ]),
          const SizedBox(height: 12),
          const Text('Recent activity'),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: actSvc.dailyStream(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No activity yet'));
                final latest = docs.first.data() as Map<String, dynamic>;
                final study = Map<String, dynamic>.from(latest['studyHours'] ?? {});
                return ListView(children: [
                  ListTile(title: const Text('Today'), subtitle: Text('Study: ${study.entries.map((e) => '${e.key}: ${e.value}h').join(', ')}')),
                  ListTile(title: const Text('Sleep'), subtitle: Text('${latest['sleepHours'] ?? 0}h')),
                ]);
              },
            ),
          )
        ]),
      ),
    );
  }
}
