import 'package:cartridge/models/quiz_category.dart';

class QuizData {
  int timeLimit;
  int questionCount;
  List<QuizCategory> categories;

  QuizData({
    this.timeLimit = 30,
    this.questionCount = 10,
    List<QuizCategory>? categories,
  }) : categories = categories ?? [];

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      timeLimit: json['timeLimit'] ?? 30,
      questionCount: json['questionCount'] ?? 10,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => QuizCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeLimit': timeLimit,
      'questionCount': questionCount,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}
