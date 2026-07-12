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
  List<String> get bgmPaths => data.bgmPaths;
  double get bgmVolume => data.bgmVolume;
  String? get correctSfxPath => data.correctSfxPath;
  String? get wrongSfxPath => data.wrongSfxPath;
  List<QuizCategory> get categories => data.categories;
  Set<String> get usedQuizIds => data.usedQuizIds;

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

  void addBgmPath(String path) {
    if (data.bgmPaths.contains(path)) return;
    data.bgmPaths.add(path);
    _save();
  }

  void removeBgmPath(String path) {
    data.bgmPaths.remove(path);
    _save();
  }

  void setCorrectSfxPath(String? path) {
    data.correctSfxPath = path;
    _save();
  }

  void setWrongSfxPath(String? path) {
    data.wrongSfxPath = path;
    _save();
  }

  void markQuizUsed(String quizId) {
    if (data.usedQuizIds.add(quizId)) {
      _save();
    }
  }

  void resetUsedQuizzes() {
    if (data.usedQuizIds.isEmpty) return;
    data.usedQuizIds.clear();
    _save();
  }

  void setBgmVolume(double volume) {
    data.bgmVolume = volume;
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
    final index = data.categories.indexWhere((e) => e.id == id);
    if (index == -1) return;
    for (final quiz in data.categories[index].quizzes) {
      for (final path in quiz.imagePaths) {
        QuizService.deleteImage(path);
      }
    }
    data.categories.removeAt(index);
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
    final newPaths = quiz.imagePaths.toSet();
    for (final path in category.quizzes[index].imagePaths) {
      if (!newPaths.contains(path)) {
        QuizService.deleteImage(path);
      }
    }
    category.quizzes[index] = quiz;
    _save();
  }

  void removeQuiz(String categoryId, String quizId) {
    final category = data.categories.firstWhere((e) => e.id == categoryId);
    final index = category.quizzes.indexWhere((e) => e.id == quizId);
    if (index == -1) return;
    for (final path in category.quizzes[index].imagePaths) {
      QuizService.deleteImage(path);
    }
    category.quizzes.removeAt(index);
    _save();
  }
}

final quizProvider = ChangeNotifierProvider<QuizNotifier>((ref) {
  return QuizNotifier();
});
