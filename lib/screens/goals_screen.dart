import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goals_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _hoursCtrl = TextEditingController();
  final GoalsService _svc = GoalsService();
  String _period = 'weekly';

  void _save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final hrs = double.tryParse(_hoursCtrl.text.trim()) ?? 0;
    if (hrs <= 0) return;
    await _svc.setGoal(uid, _period, hrs);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal saved')));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(children: [
            Expanded(child: DropdownButton<String>(value: _period, items: const [DropdownMenuItem(value: 'weekly', child: Text('Weekly')), DropdownMenuItem(value: 'monthly', child: Text('Monthly'))], onChanged: (v) => setState(() => _period = v!))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _hoursCtrl, decoration: const InputDecoration(labelText: 'Target study hours'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Save Goal')),
          const SizedBox(height: 16),
          const Text('Your current goals'),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: _svc.goalsFor(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text('No goals set');
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    return ListTile(title: Text('${d['period']} goal'), subtitle: Text('Target: ${d['targetStudyHours']} hrs'));
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
