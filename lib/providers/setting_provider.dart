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

  set isaacPath(String path) {
    _isaacPath = path;
    notifyListeners();
  }

  String _musicPlaylistPath = '';

  String get musicPlaylistPath => _musicPlaylistPath;

  set musicPlaylistPath(String path) {
    _musicPlaylistPath = path;
    notifyListeners();
  }

  int _rerunDelay = 1000;

  int get rerunDelay => _rerunDelay;

  set rerunDelay(int delay) {
    _rerunDelay = delay;
    notifyListeners();
  }

  String? _languageCode;

  String? get languageCode => _languageCode;

  set languageCode(String? code) {
    _languageCode = code;
    notifyListeners();
  }

  bool _isGridView = false;

  bool get isGridView => _isGridView;

  set isGridView(bool value) {
    _isGridView = value;
    notifyListeners();
  }

  Future<void> loadSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    _isaacPath = json['isaacPath'] as String? ?? _isaacPath;
    _musicPlaylistPath =
        json['musicPlaylistPath'] as String? ?? _musicPlaylistPath;
    _rerunDelay = json['rerunDelay'] as int? ?? 1000;
    _languageCode = json['languageCode'] as String?;
    _isGridView = json['isGridView'] as bool? ?? false;

    notifyListeners();
  }

  void saveSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    file.writeAsString(jsonEncode({
      'isaacPath': _isaacPath,
      'musicPlaylistPath': _musicPlaylistPath,
      'rerunDelay': _rerunDelay,
      'languageCode': _languageCode,
      'isGridView': _isGridView,
    }));
  }
}

final settingProvider = ChangeNotifierProvider<SettingNotifier>((ref) {
  return SettingNotifier();
});
