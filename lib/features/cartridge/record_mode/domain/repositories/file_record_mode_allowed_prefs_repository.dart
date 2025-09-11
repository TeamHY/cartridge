import 'dart:convert';
import 'dart:io';

import 'package:cartridge/features/cartridge/record_mode/domain/repositories/record_mode_allowed_prefs_repository.dart';


class FileRecordModeAllowedPrefsRepository implements RecordModeAllowedPrefsRepository {
  final String appFolderName;
  final String fileName;

  FileRecordModeAllowedPrefsRepository({
    this.appFolderName = 'Cartridge',
    this.fileName = 'allowed_mod_prefs.json',
  });

  Future<Directory> _baseDir() async {
    if (Platform.isWindows) {
      final base = Platform.environment['APPDATA'] ?? Directory.current.path;
      return Directory('$base\\$appFolderName');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return Directory('$home/Library/Application Support/$appFolderName');
    } else {
      final home = Platform.environment['HOME'] ?? '';
      return Directory('$home/.config/$appFolderName');
    }
  }

  Future<File> _file() async {
    final dir = await _baseDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$fileName');
  }

  @override
  Future<Map<String, bool>> readAll() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final txt = await f.readAsString();
      final raw = jsonDecode(txt);
      final out = <String, bool>{};
      if (raw is Map<String, dynamic>) {
        for (final e in raw.entries) {
          out[e.key] = e.value == true;
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> writeAll(Map<String, bool> map) async {
    final f = await _file();
    final s = const JsonEncoder.withIndent('  ').convert(map);
    await f.writeAsString(s);
  }
}
