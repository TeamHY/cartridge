import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory, OpenDatabaseOptions;

import 'package:cartridge/core/infra/file_io.dart';

/// 경로별 커넥션 캐시(중복 open 방지)
final Map<String, Future<Database>> _dbCache = {};

/// App Support 디렉터리 하위에 [fileName]으로 SQLite DB를 연다.
/// - 경로 결정은 반드시 ensureDataFile()을 통해 이 프로젝트 규칙을 따른다.
/// - Windows(sqflite_common_ffi)에서도 동일 코드로 동작(메인에서 databaseFactory=...만 설정).
Future<Database> openAppDatabase(
    String fileName, {
      required int version,
      FutureOr<void> Function(Database db)? onConfigure,
      FutureOr<void> Function(Database db, int version)? onCreate,
      FutureOr<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
    }) async {
  final file = await ensureDataFile(fileName);
  final path = file.path;

  // 이미 열려있으면 재사용
  final cached = _dbCache[path];
  if (cached != null) return cached;

  final future = databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: (db) async {
        // 기본 PRAGMA
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA busy_timeout = 5000;');
        await db.execute('PRAGMA journal_mode = WAL;');
        if (onConfigure != null) await onConfigure(db);
      },
      onCreate: (db, v) async {
        if (onCreate != null) await onCreate(db, v);
      },
      onUpgrade: (db, oldV, newV) async {
        if (onUpgrade != null) await onUpgrade(db, oldV, newV);
      },
    ),
  );

  _dbCache[path] = future;
  return future;
}

/// DB 닫기(테스트/리셋용). 열려있으면 캐시에서 제거 후 close.
Future<void> closeAppDatabase(String fileName) async {
  final file = await ensureDataFile(fileName);
  final path = file.path;
  final fut = _dbCache.remove(path);
  if (fut != null) {
    final db = await fut;
    await db.close();
  }
}

/// DB 파일 삭제(테스트/리셋용). close 이후 삭제 권장.
Future<void> deleteAppDatabase(String fileName) async {
  final file = await ensureDataFile(fileName);
  final path = file.path;
  // sqflite가 제공하는 삭제 API 사용(잠금/플랫폼 호환성)
  await databaseFactory.deleteDatabase(path);
  _dbCache.remove(path);
}
