import 'package:cartridge/constants/quiz_category_options.dart';
import 'package:cartridge/models/quiz.dart';
import 'package:uuid/uuid.dart';

class QuizCategory {
  final String id;
  String name;
  String iconName;
  int colorValue;
  List<Quiz> quizzes;

  QuizCategory({
    String? id,
    required this.name,
    this.iconName = defaultQuizCategoryIcon,
    this.colorValue = defaultQuizCategoryColor,
    List<Quiz>? quizzes,
  })  : id = id ?? const Uuid().v4(),
        quizzes = quizzes ?? [];

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'],
      name: json['name'],
      iconName: json['iconName'] ?? defaultQuizCategoryIcon,
      colorValue: json['colorValue'] ?? defaultQuizCategoryColor,
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((e) => Quiz.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'quizzes': quizzes.map((e) => e.toJson()).toList(),
    };
  }
}
