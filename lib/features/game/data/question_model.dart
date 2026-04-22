import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String prompt;
  final List<String> items; // Correct order
  final String category;

  Question({
    required this.id,
    required this.prompt,
    required this.items,
    required this.category,
  });

  factory Question.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      prompt: d['prompt'] as String? ?? '',
      items: List<String>.from(d['items'] ?? []),
      category: d['category'] as String? ?? '',
    );
  }
}
