import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/quiz_data.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class QuizService {
  static Future<String> importImage(String sourcePath) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(p.join(appSupportDir.path, 'quiz_images'));
    await imagesDir.create(recursive: true);

    final destPath = p.join(
      imagesDir.path,
      '${const Uuid().v4()}${p.extension(sourcePath)}',
    );
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    await FileImage(file).evict();

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
        return;
      } on FileSystemException {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

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
