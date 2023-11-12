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

  void loadSetting() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    _isaacPath = json['isaacPath'] as String? ??
        'C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth';

    notifyListeners();
  }

  void savePresets() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\setting.json');

    file.writeAsString(jsonEncode({'isaacPath': _isaacPath}));
  }

  void setIsaacPath(String path) {
    _isaacPath = path;

    savePresets();
    notifyListeners();
  }
}

final settingProvider = ChangeNotifierProvider<SettingNotifier>((ref) {
  return SettingNotifier();
});
