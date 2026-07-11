import 'package:uuid/uuid.dart';

class Quiz {
  final String id;
  String question;
  List<String> choices;
  int answerIndex;

  Quiz({
    String? id,
    required this.question,
    required this.choices,
    required this.answerIndex,
  }) : id = id ?? const Uuid().v4();

  factory Quiz.empty() {
    return Quiz(
      question: '',
      choices: List<String>.filled(5, ''),
      answerIndex: 0,
    );
  }

  bool get isComplete =>
      question.trim().isNotEmpty &&
      choices.length == 5 &&
      choices.every((c) => c.trim().isNotEmpty) &&
      answerIndex >= 0 &&
      answerIndex < choices.length;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      question: json['question'],
      choices: (json['choices'] as List<dynamic>).cast<String>(),
      answerIndex: json['answerIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'choices': choices,
      'answerIndex': answerIndex,
    };
  }
}
