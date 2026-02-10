import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _feedback = '';
  bool _loading = false;

  Future<void> _generateFeedback() async {
    setState(() => _loading = true);
    final fn = FirebaseFunctions.instance.httpsCallable('generateWeeklyFeedback');
    try {
      final res = await fn();
      setState(() => _feedback = (res.data['feedback'] ?? '').toString());
    } catch (e) {
      setState(() => _feedback = 'Error generating feedback');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<DocumentSnapshot>> _fetchWeekly(String uid) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final snap = await FirebaseFirestore.instance.collection('DailyActivity').where('userId', isEqualTo: uid).where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo)).get();
    return snap.docs;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          ElevatedButton(onPressed: _loading ? null : _generateFeedback, child: const Text('Generate AI Feedback')),
          const SizedBox(height: 12),
          if (_loading) const CircularProgressIndicator(),
          if (_feedback.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(12.0), child: Text(_feedback))),
          const SizedBox(height: 12),
          const Text('Weekly study chart'),
          const SizedBox(height: 8),
          FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchWeekly(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final data = snapshot.data!;
              if (data.isEmpty) return const Text('No activity');
              final chartData = data.map((d) {
                final m = d.data() as Map<String, dynamic>;
                final date = (m['date'] as Timestamp).toDate();
                double total = 0;
                (m['studyHours'] ?? {}).forEach((k, v) { total += (v as num).toDouble(); });
                return {'date': date, 'hours': total};
              }).toList();
              final series = [
                charts.Series<Map<String, dynamic>, String>(
                  id: 'Study',
                  domainFn: (d, _) => (d['date'] as DateTime).toIso8601String().split('T').first,
                  measureFn: (d, _) => d['hours'] as double,
                  data: chartData,
                )
              ];
              return SizedBox(height: 200, child: charts.BarChart(series, animate: true));
            },
          )
        ]),
      ),
    );
  }
}
