import 'package:cartridge/models/quiz_category.dart';

class QuizData {
  int timeLimit;
  int questionCount;
  String? bgmPath;
  double bgmVolume;
  List<QuizCategory> categories;

  QuizData({
    this.timeLimit = 30,
    this.questionCount = 10,
    this.bgmPath,
    this.bgmVolume = 0.7,
    List<QuizCategory>? categories,
  }) : categories = categories ?? [];

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      timeLimit: json['timeLimit'] ?? 30,
      questionCount: json['questionCount'] ?? 10,
      bgmPath: json['bgmPath'],
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 0.7,
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
      'bgmPath': bgmPath,
      'bgmVolume': bgmVolume,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}
