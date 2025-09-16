import 'dart:convert';

import 'package:cartridge/core/infra/file_io.dart' as fio;
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/record_mode_allowed_prefs_repository.dart';


class FileRecordModeAllowedPrefsRepository implements RecordModeAllowedPrefsRepository {
  final String relativePath;

  FileRecordModeAllowedPrefsRepository({
    this.relativePath = 'allowed_mod_prefs.json',
  });


  @override
  Future<Map<String, bool>> readAll() async {
    try {
      final f = await fio.ensureDataFile(relativePath);
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
    final f = await fio.ensureDataFile(relativePath);
    final s = const JsonEncoder.withIndent('  ').convert(map);
    await fio.writeBytes(f.path, utf8.encode(s), atomic: true, flush: true);
  }
}
