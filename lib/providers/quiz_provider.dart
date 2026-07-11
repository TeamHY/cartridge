import 'package:cartridge/models/quiz.dart';
import 'package:cartridge/models/quiz_category.dart';
import 'package:cartridge/models/quiz_data.dart';
import 'package:cartridge/services/quiz_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizNotifier extends ChangeNotifier {
  QuizNotifier() {
    loadData();
  }

  QuizData data = QuizData();

  int get timeLimit => data.timeLimit;
  int get questionCount => data.questionCount;
  List<QuizCategory> get categories => data.categories;

  Future<void> loadData() async {
    data = await QuizService.loadData();
    notifyListeners();
  }

  Future<void> _save() async {
    await QuizService.saveData(data);
    notifyListeners();
  }

  void setTimeLimit(int seconds) {
    data.timeLimit = seconds;
    _save();
  }

  void setQuestionCount(int count) {
    data.questionCount = count;
    _save();
  }

  QuizCategory addCategory(String name, String iconName, int colorValue) {
    final category = QuizCategory(
      name: name,
      iconName: iconName,
      colorValue: colorValue,
    );
    data.categories.add(category);
    _save();
    return category;
  }

  void updateCategory(
    String id, {
    String? name,
    String? iconName,
    int? colorValue,
  }) {
    final category = data.categories.firstWhere((e) => e.id == id);
    if (name != null) category.name = name;
    if (iconName != null) category.iconName = iconName;
    if (colorValue != null) category.colorValue = colorValue;
    _save();
  }

  void removeCategory(String id) {
    data.categories.removeWhere((e) => e.id == id);
    _save();
  }

  QuizCategory? findCategory(String id) {
    for (final category in data.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Quiz addQuiz(String categoryId) {
    final category = data.categories.firstWhere((e) => e.id == categoryId);
    final quiz = Quiz.empty();
    category.quizzes.add(quiz);
    _save();
    return quiz;
  }

  void updateQuiz(String categoryId, Quiz quiz) {
    final category = data.categories.firstWhere((e) => e.id == categoryId);
    final index = category.quizzes.indexWhere((e) => e.id == quiz.id);
    if (index == -1) return;
    category.quizzes[index] = quiz;
    _save();
  }

  void removeQuiz(String categoryId, String quizId) {
    final category = data.categories.firstWhere((e) => e.id == categoryId);
    category.quizzes.removeWhere((e) => e.id == quizId);
    _save();
  }
}

final quizProvider = ChangeNotifierProvider<QuizNotifier>((ref) {
  return QuizNotifier();
});
