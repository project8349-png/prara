import 'package:cloud_firestore/cloud_firestore.dart';

class DailyActivity {
  final String id;
  final String userId;
  final Timestamp date;
  final Map<String, dynamic> studyHours; // subject -> hours
  final double sleepHours;
  final String mood; // emoji or text
  final String notes;

  DailyActivity({required this.id, required this.userId, required this.date, required this.studyHours, required this.sleepHours, required this.mood, required this.notes});

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'date': date,
    'studyHours': studyHours,
    'sleepHours': sleepHours,
    'mood': mood,
    'notes': notes,
  };

  factory DailyActivity.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DailyActivity(
      id: doc.id,
      userId: d['userId'],
      date: d['date'],
      studyHours: Map<String, dynamic>.from(d['studyHours'] ?? {}),
      sleepHours: (d['sleepHours'] ?? 0).toDouble(),
      mood: d['mood'] ?? '',
      notes: d['notes'] ?? '',
    );
  }
}
