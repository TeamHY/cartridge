import 'dart:convert';
import 'dart:io';

import 'package:cartridge/theme/theme.dart';
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
  bool isGridView = false;
  String themeId = AppThemeKey.system.name;

  AppThemeKey get themeKey {
    try {
      return AppThemeKey.values.byName(themeId);
    } catch (_) {
      return AppThemeKey.system;
    }
  }

  Future<void> loadSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    _isaacPath = json['isaacPath'] as String? ?? _isaacPath;
    rerunDelay = json['rerunDelay'] as int? ?? 1000;
    languageCode = json['languageCode'] as String?;
    isGridView = json['isGridView'] as bool? ?? false;
    themeId = json['themeId'] as String? ?? AppThemeKey.system.name;

    notifyListeners();
  }

  void saveSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    file.writeAsString(jsonEncode({
      'isaacPath': _isaacPath,
      'rerunDelay': rerunDelay,
      'languageCode': languageCode,
      'isGridView': isGridView,
      'themeKey': themeId,
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

  void setIsGridView(bool value) {
    isGridView = value;

    notifyListeners();
  }

  void setThemeKey(AppThemeKey key) {
    themeId = key.name;         // 'system' 등 유효한 문자열을 사용
    notifyListeners();    // UI 반영
  }
}

final settingProvider = ChangeNotifierProvider<SettingNotifier>((ref) {
  return SettingNotifier();
});
