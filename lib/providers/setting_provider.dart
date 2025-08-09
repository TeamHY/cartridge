import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class SettingNotifier extends ChangeNotifier {
  SettingNotifier() {
    loadSetting();
  }

  String _isaacPath =
      'C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth';

  String get isaacPath => _isaacPath;

  int rerunDelay = 1000;
  String? languageCode;

  void loadSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    _isaacPath = json['isaacPath'] as String? ?? _isaacPath;
    rerunDelay = json['rerunDelay'] as int? ?? 1000;
    languageCode = json['languageCode'] as String?;

    notifyListeners();
  }

  void saveSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    file.writeAsString(jsonEncode({
      'isaacPath': _isaacPath,
      'rerunDelay': rerunDelay,
      'languageCode': languageCode,
    }));
  }

  void setIsaacPath(String path) {
    _isaacPath = path;

    notifyListeners();
  }

  void setRerunDelay(int delay) {
    rerunDelay = delay;

    notifyListeners();
  }

  void setLanguageCode(String code) {
    languageCode = code;

    notifyListeners();
  }
}

final settingProvider = ChangeNotifierProvider<SettingNotifier>((ref) {
  return SettingNotifier();
});
