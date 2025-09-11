import 'dart:io';
import 'package:cartridge/core/log.dart';

import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';
import 'package:cartridge/features/isaac/options/domain/isaac_options_policy.dart';
import 'package:cartridge/features/isaac/options/domain/isaac_options_decoder.dart';

class IsaacOptionsIniService {
  static const _tag = 'IsaacOptionsIniService';

  /// 읽기: options.ini → IsaacOptions
  Future<IsaacOptions> read({required String optionsIniPath}) async {
    final file = File(optionsIniPath);
    if (!await file.exists()) {
      throw FileSystemException('options.ini not found', optionsIniPath);
    }
    final content = await file.readAsString();
    final map = _parseOptionsSection(content);
    if (map.isEmpty) return IsaacOptions();
    return IsaacOptionsDecoder.fromIniMap(map);
  }

  Future<void> apply({
    required String optionsIniPath,
    required IsaacOptions options,
    bool makeBackup = false,
    bool createIfMissing = true,
  }) async {
    final file = File(optionsIniPath);
    if (!await file.exists()) {
      if (!createIfMissing) {
        throw FileSystemException('options.ini not found', optionsIniPath);
      }
      await file.create(recursive: true);
      await file.writeAsString('[Options]\nLanguage=0\n');
    }

    final original = await file.readAsString();
    if (makeBackup) {
      await File('$optionsIniPath.bak').writeAsString(original);
    }

    final normalized = IsaacOptionsPolicy.normalize(options);
    final kv = IsaacOptionsEncoder.toIniMapSkippingNulls(normalized);

    final updated = _patchOptionsSection(original, kv);
    if (updated != original) {
      await file.writeAsString(updated);
      logI(_tag, 'options.ini updated');
    } else {
      logI(_tag, 'no changes');
    }
  }

  Map<String, String> _parseOptionsSection(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    int start = -1, end = lines.length;

    // 섹션 경계 탐색
    for (int i = 0; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t.startsWith('[') && t.endsWith(']')) {
        if (t == '[Options]') {
          start = i;
        } else if (start != -1) { end = i; break; }
      }
    }
    if (start == -1) return {};

    final kv = <String, String>{};
    final re = RegExp(r'^([A-Za-z0-9_]+)\s*=\s*(.*)$');
    for (int i = start + 1; i < end; i++) {
      var raw = lines[i];
      // 주석 제거(; 또는 # 이후)
      final sc = raw.indexOf(';'); if (sc != -1) raw = raw.substring(0, sc);
      final hc = raw.indexOf('#'); if (hc != -1) raw = raw.substring(0, hc);
      final m = re.firstMatch(raw.trim());
      if (m != null) {
        final k = m.group(1)!.trim();
        var v = m.group(2)!.trim();
        // 양쪽 따옴표 제거
        if (v.length >= 2 && ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))) {
          v = v.substring(1, v.length - 1);
        }
        kv[k] = v;
      }
    }
    return kv;
  }

  String _patchOptionsSection(String content, Map<String, String> kv) {
    final lines = content.split(RegExp(r'\r?\n'));
    int start = -1, end = lines.length;

    // [Options] 영역 찾기
    for (int i = 0; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t.startsWith('[') && t.endsWith(']')) {
        if (t == '[Options]') {
          start = i;
        } else if (start != -1) { end = i; break; }
      }
    }
    if (start == -1) { lines.add('[Options]'); start = lines.length - 1; end = lines.length; }

    // 기존 키 위치 인덱스
    final keyToIndex = <String, int>{};
    final re = RegExp(r'^([A-Za-z0-9_]+)\s*=\s*(.*)$');
    for (int i = start + 1; i < end; i++) {
      final m = re.firstMatch(lines[i].trim());
      if (m != null) keyToIndex[m.group(1)!] = i;
    }

    // 업데이트: 있는 키만 교체, 없는 키는 추가
    final toAppend = <String>[];
    kv.forEach((k, v) {
      final idx = keyToIndex[k];
      if (idx != null) {
        lines[idx] = '$k=$v';
      } else {
        toAppend.add('$k=$v');
      }
    });

    if (toAppend.isNotEmpty) {
      // 섹션 끝 다음 줄에 추가
      for (int i = start + 1; i < lines.length; i++) {
        final t = lines[i].trim();
        if (t.startsWith('[') && t.endsWith(']')) { end = i; break; }
      }
      if (end < lines.length && lines[end].trim().isNotEmpty) {
        lines.insert(end, ''); end++;
      }
      lines.insertAll(end, toAppend);
    }

    return lines.join('\n');
  }
}
