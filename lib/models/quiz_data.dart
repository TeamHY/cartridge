import 'package:cartridge/models/quiz_category.dart';

class QuizData {
  int timeLimit;
  int questionCount;
  List<String> bgmPaths;
  double bgmVolume;
  String? correctSfxPath;
  String? wrongSfxPath;
  List<QuizCategory> categories;
  Set<String> usedQuizIds;

  QuizData({
    this.timeLimit = 30,
    this.questionCount = 10,
    List<String>? bgmPaths,
    this.bgmVolume = 0.7,
    this.correctSfxPath,
    this.wrongSfxPath,
    List<QuizCategory>? categories,
    Set<String>? usedQuizIds,
  })  : bgmPaths = bgmPaths ?? [],
        categories = categories ?? [],
        usedQuizIds = usedQuizIds ?? {};

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      timeLimit: json['timeLimit'] ?? 30,
      questionCount: json['questionCount'] ?? 10,
      bgmPaths: (json['bgmPaths'] as List<dynamic>?)?.cast<String>() ??
          [if (json['bgmPath'] != null) json['bgmPath'] as String],
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 0.7,
      correctSfxPath: json['correctSfxPath'],
      wrongSfxPath: json['wrongSfxPath'],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => QuizCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usedQuizIds:
          (json['usedQuizIds'] as List<dynamic>?)?.cast<String>().toSet() ??
              {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeLimit': timeLimit,
      'questionCount': questionCount,
      'bgmPaths': bgmPaths,
      'bgmVolume': bgmVolume,
      'correctSfxPath': correctSfxPath,
      'wrongSfxPath': wrongSfxPath,
      'categories': categories.map((e) => e.toJson()).toList(),
      'usedQuizIds': usedQuizIds.toList(),
    };
  }
}
