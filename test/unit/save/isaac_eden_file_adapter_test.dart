import 'dart:io';
import 'dart:typed_data';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_eden_file_adapter.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_file_namer.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class MockSteamAccountProfile extends Mock implements SteamAccountProfile {}

class _FakeCodec extends IsaacSaveCodec {
  @override
  int readEdenTokens(Uint8List data, {int? section1Offset}) =>
      ByteData.sublistView(data, 0, 4).getUint32(0, Endian.little);

  @override
  Uint8List writeEdenTokens(Uint8List data, int eden, {int? section1Offset}) {
    final out = Uint8List.fromList(data);
    ByteData.sublistView(out, 0, 4).setUint32(0, eden, Endian.little);
    return out;
  }

  @override
  Uint8List updateChecksumAfterbirthFamily(Uint8List data) => Uint8List.fromList(data);

  @override
  int calcAfterbirthChecksum(Uint8List data, int ofs, int length) =>
      ByteData.sublistView(data, data.length - 4).getUint32(0, Endian.little);
}

void main() {
  test('읽기/쓰기/백업: 길이 유지 + 값 반영 (AAA)', () async {
    // Arrange
    final tmp = await Directory.systemTemp.createTemp('eden_adapter_');
    addTearDown(() => tmp.delete(recursive: true));

    final acc = MockSteamAccountProfile();
    when(() => acc.savePath).thenReturn(tmp.path);

    final ed = IsaacEdition.afterbirthPlus;
    const slot = 2;

    final name = IsaacSaveFileNamer.fileName(ed, slot);
    final file = File(p.join(tmp.path, name));

    final data = Uint8List(32);
    ByteData.sublistView(data, 0, 4).setUint32(0, 123, Endian.little);
    await file.writeAsBytes(data, flush: true);

    final adapter = IsaacEdenFileAdapter(codec: _FakeCodec() as dynamic);

    // Act
    final before = await adapter.read(acc, ed, slot);
    await adapter.write(acc, ed, slot, 777, makeBackup: true, mode: SaveWriteMode.inPlace);
    final after = await adapter.read(acc, ed, slot);

    // Assert
    expect(before, 123);
    expect(after, 777);
    expect(await File('${file.path}.bak').exists(), isTrue);
    expect((await file.readAsBytes()).length, 32);
  });

  test('읽기 예외: 파일 미존재 시 StateError (AAA)', () async {
    final acc = MockSteamAccountProfile();
    final tmp = await Directory.systemTemp.createTemp('eden_adapter_');
    addTearDown(() => tmp.delete(recursive: true));
    when(() => acc.savePath).thenReturn(tmp.path);

    final adapter = IsaacEdenFileAdapter(codec: _FakeCodec() as dynamic);

    expect(
          () => adapter.read(acc, IsaacEdition.repentance, 1),
      throwsA(isA<StateError>()),
    );
  });
}
