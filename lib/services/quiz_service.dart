import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/quiz_data.dart';
import 'package:path_provider/path_provider.dart';

class QuizService {
  static Future<QuizData> loadData() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/quizzes.json');

    if (!(await file.exists())) {
      return QuizData();
    }

    try {
      final json = jsonDecode(await file.readAsString());
      return QuizData.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      return QuizData();
    }
  }

  static Future<void> saveData(QuizData data) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/quizzes.json');

    await file.writeAsString(jsonEncode(data.toJson()));
  }
}
