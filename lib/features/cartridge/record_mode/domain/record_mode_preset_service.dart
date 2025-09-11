import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:cartridge/features/cartridge/record_mode/domain/models/mod.dart' as remote;
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_environment_service.dart';

abstract class RecordModePresetService {
  Future<GamePresetView> loadAllowedPresetView();
}

class RecordModePresetServiceImpl implements RecordModePresetService {
  final IsaacEnvironmentService _env;
  final RecordModeAllowedPrefsService _prefs;
  RecordModePresetServiceImpl(this._env, this._prefs);


  @override
  Future<GamePresetView> loadAllowedPresetView() async {
    final preset = await _fetchRecordPreset();
    final installed = await _env.getInstalledModsMap(); // Map<String key, local.InstalledMod>

    // 이름 → 설치키 인덱스(대소문자/공백 내성)
    String norm(String s) => s.trim().toLowerCase();
    final byName = <String, String>{};
    for (final e in installed.entries) {
      final nm = e.value.metadata.name.trim();
      if (nm.isEmpty) continue;
      byName.putIfAbsent(norm(nm), () => e.key);
    }

    final items = <AllowedModRow>[];
    var allowedCnt = 0;
    var installedAllowedCnt = 0;

    for (final m in preset.mods) {
      final serverAllowed = !(m.isDisable);
      final k = byName[norm(m.name)];
      final loc = (k == null) ? null : installed[k];

      final isRecorder = RecorderMod.isRecorder(m.name);
      final allowed = isRecorder ? true : serverAllowed;

      // default 값
      final enabled = isRecorder
          ? (loc != null) // 설치된 경우에만 '켜짐'으로 보여줌
          : (loc?.isEnabled ?? false);

      final row = AllowedModRow(
        name: m.name,
        allowed: allowed,
        installed: loc != null,
        enabled: enabled,
        key: k,
        workshopId: isRecorder ? null : (loc?.metadata.id.trim().isEmpty == true ? null : loc?.metadata.id.trim()),
        alwaysOn: isRecorder,
      );
      items.add(row);

      if (allowed) {
        allowedCnt++;
        if (loc != null) installedAllowedCnt++;
      }
    }

    final prefMap = await _prefs.ensureInitialized(items);
    final applied = items.map((r) {
      if (r.alwaysOn) {
        return r.copyWith(enabled: true);
      }
      final k = _prefs.keyFor(r);
      final on = prefMap[k] ?? true;
      return r.copyWith(enabled: on);
    }).toList();

    return GamePresetView(
      items: applied,
      allowedCount: allowedCnt,
      installedAllowedCount: installedAllowedCnt,
    );
  }

  // --- 내부: 서버에서 프리셋 JSON 가져오기 ---
  Future<Preset> _fetchRecordPreset() async {
    final url = dotenv.env['RECORD_PRESET_URL'] ?? '';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch record preset: ${res.statusCode}');
    }
    final json = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    final mods = List<remote.Mod>.from(json.map((e) => remote.Mod.fromJson(e)));
    return Preset(name: 'record', mods: mods);
  }
}
