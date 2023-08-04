import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingNotifier extends ChangeNotifier {
  String _isaacPath =
      "C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth";

  String get isaacPath => _isaacPath;

  void loadSetting() {
    notifyListeners();
  }

  void setIsaacPath(String path) {
    _isaacPath = path;
    notifyListeners();
  }
}

final settingProvider = ChangeNotifierProvider<SettingNotifier>((ref) {
  return SettingNotifier();
});
