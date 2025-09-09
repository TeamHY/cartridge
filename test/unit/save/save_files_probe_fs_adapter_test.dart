import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_file_namer.dart';
import 'package:cartridge/features/isaac/save/infra/save_files_probe_fs_adapter.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class MockSteamAccountProfile extends Mock implements SteamAccountProfile {}

void main() {
  test('파일 존재 스캔: 존재하는 슬롯만 반환한다 (AAA)', () async {
    // Arrange
    final tmp = await Directory.systemTemp.createTemp('probe_');
    addTearDown(() => tmp.delete(recursive: true));

    final acc = MockSteamAccountProfile();
    when(() => acc.savePath).thenReturn(tmp.path);

    final ed = IsaacEdition.repentance;
    for (final slot in [1, 3]) {
      final name = IsaacSaveFileNamer.fileName(ed, slot);
      await File(p.join(tmp.path, name)).writeAsBytes(const [0]);
    }

    final probe = SaveFilesProbeFsAdapter();

    // Act
    final slots = await probe.listExistingSlots(acc, ed);

    // Assert
    expect(slots, [1, 3]);
  });
}
