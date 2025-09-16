import 'dart:convert';
import 'dart:io';
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
    await _ensureRecorderInstalledIfMissing();
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
        return r.copyWith(enabled: r.installed);
      }

      final k = _prefs.keyFor(r);
      final stored = prefMap[k];
      final want = r.installed
          ? (stored ?? r.enabled)
          : false;

      return r.copyWith(enabled: want);
    }).toList();


    return GamePresetView(
      items: applied,
      allowedCount: allowedCnt,
      installedAllowedCount: installedAllowedCnt,
    );
  }

  Future<bool> _ensureRecorderInstalledIfMissing() async {
    final installed = await _env.getInstalledModsMap();
    final hasRecorder = installed.values.any((m) =>
    m.metadata.name.trim() == RecorderMod.name ||
        m.metadata.directory.trim() == RecorderMod.directory
    );
    if (hasRecorder) return true;

    final modsRoot = await _env.resolveModsRoot();
    if (modsRoot == null) return false;

    // 1) 먼저 원격 템플릿을 받아온다. 실패하면 디스크에 아무것도 쓰지 않고 끝낸다.
    String mainLua;
    try {
      // 값 주입은 실행 시점에 다시 이루어지므로 여기서는 템플릿만 확보되면 충분
      mainLua = await RecorderMod.getModMain('', '', 0, '', '', 0);
    } catch (_) {
      return false; // 네트워크/서버 문제 등으로 받지 못하면 설치 시도 중단
    }

    // 2) 임시 폴더에 모두 쓰고, 끝까지 성공하면 최종 폴더로 rename (부분 설치 방지)
    final targetDir = Directory('$modsRoot\\${RecorderMod.directory}');
    final tempDir = Directory('${targetDir.path}.tmp');

    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      await File('${tempDir.path}\\main.lua').writeAsString(mainLua);
      await File('${tempDir.path}\\metadata.xml').writeAsString(RecorderMod.modMetadata);

      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      await tempDir.rename(targetDir.path); // 여기까지 오면 “설치 완료”

      return true;
    } catch (_) {
      // 실패하면 임시 폴더 정리해서 흔적 남지 않게
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
      return false;
    }
  }
  // ── 내부: 서버에서 프리셋 JSON 가져오기 ───────────────────────────────────────────────────────────
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
