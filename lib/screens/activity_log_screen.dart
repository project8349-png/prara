import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final ActivityService _svc = ActivityService();
  final _subjectCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _sleepCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _mood = '😊';

  void _addStudy() async {
    final subj = _subjectCtrl.text.trim();
    final hrs = double.tryParse(_hoursCtrl.text.trim()) ?? 0;
    if (subj.isEmpty || hrs <= 0) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final act = DailyActivity(id: '', userId: uid, date: today, studyHours: {subj: hrs}, sleepHours: double.tryParse(_sleepCtrl.text.trim()) ?? 0, mood: _mood, notes: _notesCtrl.text.trim());
    await _svc.addOrUpdate(act);
    _subjectCtrl.clear(); _hoursCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Activity')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
          TextField(controller: _hoursCtrl, decoration: const InputDecoration(labelText: 'Hours'), keyboardType: TextInputType.number),
          TextField(controller: _sleepCtrl, decoration: const InputDecoration(labelText: 'Sleep hours (today)'), keyboardType: TextInputType.number),
          Row(children: [
            const Text('Mood: '),
            DropdownButton<String>(value: _mood, items: const ["😊","😐","😔","😴"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _mood = v!))
          ]),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _addStudy, child: const Text('Save today')),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Recent entries'),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: _svc.dailyStream(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    final date = (d['date'] as Timestamp).toDate();
                    final study = Map<String, dynamic>.from(d['studyHours'] ?? {});
                    return ListTile(
                      title: Text('${date.toLocal().toIso8601String().split('T').first} — ${study.entries.map((e) => '${e.key}: ${e.value}h').join(', ')}'),
                      subtitle: Text('Sleep: ${d['sleepHours'] ?? 0}h • Mood: ${d['mood'] ?? ''}\n${d['notes'] ?? ''}'),
                    );
                  },
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}
