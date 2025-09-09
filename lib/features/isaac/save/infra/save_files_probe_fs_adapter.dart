import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/domain/ports/save_files_probe_port.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_file_namer.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class SaveFilesProbeFsAdapter implements SaveFilesProbePort {
  @override
  Future<List<int>> listExistingSlots(SteamAccountProfile acc, IsaacEdition e) async {
    final out = <int>[];
    for (var slot = 1; slot <= 3; slot++) {
      final name = IsaacSaveFileNamer.fileName(e, slot);
      final f = File(p.join(acc.savePath, name));
      if (await f.exists()) out.add(slot);
    }
    return out;
  }
}
