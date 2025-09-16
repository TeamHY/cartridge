// test/unit/record_mode/file_record_mode_allowed_prefs_repository_test.dart
import 'dart:io';
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/file_record_mode_allowed_prefs_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/core/infra/file_io.dart' as fio;

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('record_mode_prefs_');
    fio.setAppSupportDirProvider(() async => tmpDir);
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  test('readAll(): 파일 없으면 빈 맵', () async {
    final repo = FileRecordModeAllowedPrefsRepository();
    final m = await repo.readAll();
    expect(m, isEmpty);
  });

  test('writeAll()/readAll(): 라운드트립', () async {
    final repo = FileRecordModeAllowedPrefsRepository();
    final input = {'a': true, 'b': false};

    await repo.writeAll(input);
    final out = await repo.readAll();

    expect(out, equals(input));

    final f = await fio.ensureDataFile('allowed_mod_prefs.json');
    expect(await f.exists(), isTrue);
    final txt = await f.readAsString();
    expect(txt, contains('"a": true'));
    expect(txt, contains('"b": false'));
  });

  test('readAll(): 잘못된 JSON이어도 빈 맵 반환', () async {
    final repo = FileRecordModeAllowedPrefsRepository();
    final f = await fio.ensureDataFile('allowed_mod_prefs.json');
    await f.writeAsString('{not json');

    final out = await repo.readAll();
    expect(out, isEmpty);
  });

  test('relativePath 지원: 하위 폴더 경로에서도 정상 동작', () async {
    final repo = FileRecordModeAllowedPrefsRepository(
      relativePath: 'prefs/allowed_mod_prefs.json',
    );
    final input = {'x': true};

    await repo.writeAll(input);
    final out = await repo.readAll();
    expect(out, equals(input));

    final subFile = await fio.ensureDataFile('prefs/allowed_mod_prefs.json');
    expect(await subFile.exists(), isTrue);
  });
}
