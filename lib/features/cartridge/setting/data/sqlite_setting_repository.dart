import 'package:sqflite/sqflite.dart';

import 'package:cartridge/features/cartridge/setting/data/i_setting_repository.dart';
import 'package:cartridge/features/cartridge/setting/domain/models/app_setting.dart';

/// 단일 행(ROW) 테이블에 앱 설정을 저장.
/// - 테이블명: app_setting
/// - 항상 id=1 한 행만 유지.
class SqliteSettingRepository implements ISettingRepository {
  final Future<Database> Function() _db;

  SqliteSettingRepository({required Future<Database> Function() dbOpener})
      : _db = dbOpener;

  @override
  Future<AppSetting> load() async {
    final db = await _db();
    final rows = await db.query('app_setting', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      // 없으면 기본값 한 줄 생성
      final def = AppSetting.defaults;
      await db.insert(
        'app_setting',
        _toMap(def)..['id'] = 1,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return def;
    }
    return _fromMap(rows.first);
  }

  @override
  Future<void> save(AppSetting s) async {
    final db = await _db();
    await db.insert(
      'app_setting',
      _toMap(s)..['id'] = 1,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Mapping ────────────────────────────────────────────────────────────────
  Map<String, Object?> _toMap(AppSetting s) => {
    'isaac_path': s.isaacPath,
    'rerun_delay': s.rerunDelay,
    'language_code': s.languageCode,
    'theme_name': s.themeName,
    'options_ini_path': s.optionsIniPath,
    'use_auto_detect_install_path': s.useAutoDetectInstallPath ? 1 : 0,
    'use_auto_detect_options_ini': s.useAutoDetectOptionsIni ? 1 : 0,
  };

  AppSetting _fromMap(Map<String, Object?> m) => AppSetting(
    isaacPath: (m['isaac_path'] as String?) ?? '',
    rerunDelay: (m['rerun_delay'] as int?) ?? 1000,
    languageCode: (m['language_code'] as String?) ?? 'ko',
    themeName: (m['theme_name'] as String?) ?? 'system',
    optionsIniPath: (m['options_ini_path'] as String?) ?? '',
    useAutoDetectInstallPath: ((m['use_auto_detect_install_path'] as int?) ?? 1) != 0,
    useAutoDetectOptionsIni: ((m['use_auto_detect_options_ini'] as int?) ?? 1) != 0,
  );
}
