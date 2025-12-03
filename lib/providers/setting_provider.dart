import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class SettingNotifier extends ChangeNotifier {
  SettingNotifier() {
    loadSetting();
  }

  Timer? _saveTimer;

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

  double _musicVolume = 0.0;

  double get musicVolume => _musicVolume;

  set musicVolume(double volume) {
    final newVolume = volume.clamp(0.0, 1.0);
    _musicVolume = newVolume;
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

  String _playPauseHotkey = 'ctrl+alt+p';

  String get playPauseHotkey => _playPauseHotkey;

  set playPauseHotkey(String value) {
    _playPauseHotkey = value;
    notifyListeners();
  }

  String _nextTrackHotkey = 'ctrl+alt+n';

  String get nextTrackHotkey => _nextTrackHotkey;

  set nextTrackHotkey(String value) {
    _nextTrackHotkey = value;
    notifyListeners();
  }

  String _volumeUpHotkey = 'ctrl+alt+up';

  String get volumeUpHotkey => _volumeUpHotkey;

  set volumeUpHotkey(String value) {
    _volumeUpHotkey = value;
    notifyListeners();
  }

  String _volumeDownHotkey = 'ctrl+alt+down';

  String get volumeDownHotkey => _volumeDownHotkey;

  set volumeDownHotkey(String value) {
    _volumeDownHotkey = value;
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
    _musicVolume = (json['musicVolume'] as num?)?.toDouble() ?? 0.0;
    _rerunDelay = json['rerunDelay'] as int? ?? 1000;
    _languageCode = json['languageCode'] as String?;
    _isGridView = json['isGridView'] as bool? ?? false;
    // _playPauseHotkey = json['playPauseHotkey'] as String? ?? 'ctrl+alt+p';
    // _nextTrackHotkey = json['nextTrackHotkey'] as String? ?? 'ctrl+alt+n';
    // _volumeUpHotkey = json['volumeUpHotkey'] as String? ?? 'ctrl+alt+up';
    // _volumeDownHotkey = json['volumeDownHotkey'] as String? ?? 'ctrl+alt+down';

    notifyListeners();
  }

  void saveSetting() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      final appSupportDir = await getApplicationSupportDirectory();
      final file = File('${appSupportDir.path}\\setting.json');

      await file.writeAsString(jsonEncode({
        'isaacPath': _isaacPath,
        'musicPlaylistPath': _musicPlaylistPath,
        'musicVolume': _musicVolume,
        'rerunDelay': _rerunDelay,
        'languageCode': _languageCode,
        'isGridView': _isGridView,
        // 'playPauseHotkey': _playPauseHotkey,
        // 'nextTrackHotkey': _nextTrackHotkey,
        // 'volumeUpHotkey': _volumeUpHotkey,
        // 'volumeDownHotkey': _volumeDownHotkey,
      }));
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final settingProvider = ChangeNotifierProvider<SettingNotifier>((ref) {
  return SettingNotifier();
});
