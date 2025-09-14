// dart_test.yaml should include: timeout: 60x for slower CI on Windows if needed
// To run: dart test -r expanded test/setting/sqlite_setting_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cartridge/features/cartridge/setting/data/i_setting_repository.dart';
import 'package:cartridge/features/cartridge/setting/data/sqlite_setting_repository.dart';
import 'package:cartridge/features/cartridge/setting/domain/models/app_setting.dart';

void main() {
  // Initialize FFI (required for Windows/Linux and for in-memory DB in tests)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqliteSettingRepository', () {
    late Database db;
    late ISettingRepository repo;

    setUp(() async {
      db = await _openMemoryDbWithSchema();
      repo = SqliteSettingRepository(dbOpener: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('load(): 행이 없으면 defaults 생성 후 반환', () async {
      // Given DB has no app_setting row
      final count0 = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM app_setting'),
      );
      expect(count0, 0);

      // When
      final loaded = await repo.load();

      // Then: defaults are returned and row is created with id=1
      final count1 = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM app_setting'),
      );
      expect(count1, 1);

      // Compare field-by-field to avoid depending on == implementation
      final d = AppSetting.defaults;
      expect(loaded.steamPath, d.steamPath);
      expect(loaded.isaacPath, d.isaacPath);
      expect(loaded.rerunDelay, d.rerunDelay);
      expect(loaded.languageCode, d.languageCode);
      expect(loaded.themeName, d.themeName);
      expect(loaded.optionsIniPath, d.optionsIniPath);
      expect(loaded.useAutoDetectSteamPath, d.useAutoDetectSteamPath);
      expect(loaded.useAutoDetectInstallPath, d.useAutoDetectInstallPath);
      expect(loaded.useAutoDetectOptionsIni, d.useAutoDetectOptionsIni);

      final row = (await db.query('app_setting', where: 'id=1')).single;
      expect(row['id'], 1);
    });

    test('save() + load(): round-trip으로 값 보존', () async {
      // Given
      final s = AppSetting(
        steamPath: 'C:/Program Files/Steam',
        isaacPath: 'D:/Games/Isaac',
        rerunDelay: 777,
        languageCode: 'en',
        themeName: 'dark',
        optionsIniPath: 'D:/Games/Isaac/options.ini',
        useAutoDetectSteamPath: false,
        useAutoDetectInstallPath: true,
        useAutoDetectOptionsIni: false,
      );

      // When
      await repo.save(s);
      final loaded = await repo.load();

      // Then
      expect(loaded.steamPath, 'C:/Program Files/Steam');
      expect(loaded.isaacPath, 'D:/Games/Isaac');
      expect(loaded.rerunDelay, 777);
      expect(loaded.languageCode, 'en');
      expect(loaded.themeName, 'dark');
      expect(loaded.optionsIniPath, 'D:/Games/Isaac/options.ini');
      expect(loaded.useAutoDetectSteamPath, isFalse);
      expect(loaded.useAutoDetectInstallPath, isTrue);
      expect(loaded.useAutoDetectOptionsIni, isFalse);
    });

    test('save(): 항상 id=1 단일 row를 upsert', () async {
      // Given
      final a = AppSetting.defaults;
      final b = a.copyWith(themeName: 'light', rerunDelay: 1234);

      // When
      await repo.save(a);
      await repo.save(b);

      // Then: only one row exists and it has the latest values
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM app_setting'),
      );
      expect(count, 1);

      final row = (await db.query('app_setting', where: 'id=1')).single;
      expect(row['theme_name'], 'light');
      expect(row['rerun_delay'], 1234);
    });

    test('booleans는 INTEGER 0/1로 저장', () async {
      // Given
      final s = AppSetting.defaults.copyWith(
        useAutoDetectSteamPath: true,
        useAutoDetectInstallPath: false,
        useAutoDetectOptionsIni: true,
      );

      // When
      await repo.save(s);

      // Then (query raw ints)
      final row = (await db.query('app_setting', columns: [
        'use_auto_detect_steam_path',
        'use_auto_detect_install_path',
        'use_auto_detect_options_ini',
      ], where: 'id=1')).single;

      expect(row['use_auto_detect_steam_path'], 1);
      expect(row['use_auto_detect_install_path'], 0);
      expect(row['use_auto_detect_options_ini'], 1);
    });

    test('load(): 기존 row를 as-is로 반환 (overwrite 없음)', () async {
      // Given a pre-existing record
      await db.insert('app_setting', {
        'id': 1,
        'steam_path': '/steam',
        'isaac_path': '/isaac',
        'rerun_delay': 5,
        'language_code': 'en',
        'theme_name': 'system',
        'options_ini_path': '/isaac/options.ini',
        'use_auto_detect_steam_path': 0,
        'use_auto_detect_install_path': 0,
        'use_auto_detect_options_ini': 1,
      });

      // When
      final loaded = await repo.load();

      // Then
      expect(loaded.steamPath, '/steam');
      expect(loaded.isaacPath, '/isaac');
      expect(loaded.rerunDelay, 5);
      expect(loaded.languageCode, 'en');
      expect(loaded.themeName, 'system');
      expect(loaded.optionsIniPath, '/isaac/options.ini');
      expect(loaded.useAutoDetectSteamPath, isFalse);
      expect(loaded.useAutoDetectInstallPath, isFalse);
      expect(loaded.useAutoDetectOptionsIni, isTrue);
    });

    test('DB CHECK(id=1): id≠1 insert는 실패', () async {
      // Given
      // When/Then
      expectLater(
            () => db.insert('app_setting', {
          'id': 2,
          'steam_path': '',
          'isaac_path': '',
          'rerun_delay': 1,
          'language_code': 'ko',
          'theme_name': 'system',
          'options_ini_path': '',
          'use_auto_detect_steam_path': 1,
          'use_auto_detect_install_path': 1,
          'use_auto_detect_options_ini': 1,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}

Future<Database> _openMemoryDbWithSchema() async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE app_setting(
            id INTEGER PRIMARY KEY CHECK(id = 1),
            steam_path TEXT NOT NULL DEFAULT '',
            isaac_path TEXT NOT NULL DEFAULT '',
            rerun_delay INTEGER NOT NULL DEFAULT 1000,
            language_code TEXT NOT NULL DEFAULT 'ko',
            theme_name TEXT NOT NULL DEFAULT 'system',
            options_ini_path TEXT NOT NULL DEFAULT '',
            use_auto_detect_steam_path INTEGER NOT NULL DEFAULT 1,
            use_auto_detect_install_path INTEGER NOT NULL DEFAULT 1,
            use_auto_detect_options_ini INTEGER NOT NULL DEFAULT 1
          );
        ''');
      },
    ),
  );
}
