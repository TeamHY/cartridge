/// {@template feature_overview}
/// # File I/O helpers
///
/// App Support 디렉터리 접근/테스트 훅/파일 보장 유틸
/// - 경로 의존성을 주입 가능하도록 provider 훅을 노출
/// {@endtemplate}
library;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 테스트 용이성을 위한 App Support 디렉터리 공급자 타입
typedef AppSupportDirProvider = Future<Directory> Function();

/// 기본 공급자: 실제 getApplicationSupportDirectory()
AppSupportDirProvider appSupportDirProvider = () async => Directory((await getApplicationSupportDirectory()).path);

/// 테스트에서 임시 디렉터리로 바꾸기 위한 훅
@visibleForTesting
void setAppSupportDirProvider(AppSupportDirProvider provider) {
  appSupportDirProvider = provider;
}

/// 앱 지원 디렉터리 하위에 지정된 파일명을 보장하고 File 객체를 반환한다.
Future<File> ensureDataFile(String fileName) async {
  final dir = await appSupportDirProvider();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return File(p.join(dir.path, fileName));
}

Future<Directory> ensureAppSupportSubDir(String relativePath) async {
  final base = await appSupportDirProvider();
  final dir = Directory(p.join(base.path, relativePath));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

// 디렉터리 내 파일 나열
Stream<File> listFiles(Directory dir) async* {
  if (!await dir.exists()) return;
  await for (final ent in dir.list()) {
    if (ent is File) yield ent;
  }
}

// 파일 삭제(존재하면)
Future<void> deleteFileIfExists(String path) async {
  final f = File(path);
  if (await f.exists()) {
    await f.delete();
  }
}

/// 파일에 바이트를 안전하게 기록한다.
/// - 같은 디렉터리에 임시파일(`.<basename>.<ts>.tmp`)로 먼저 쓰고,
///   필요시 기존 파일을 삭제한 뒤 rename하여 원자적 저장을 최대한 보장.
/// - Windows에서 대상 파일이 존재하면 rename이 실패할 수 있어 선삭제 처리.
/// - 실패 시 임시파일을 정리한다.
///
/// [fullPath] 는 절대/앱지원 하위 경로 모두 허용.
/// [atomic] 이 true면 temp→rename 전략을 사용(기본값).
/// [flush] 가 true면 디스크 플러시를 요청한다.
Future<void> writeBytes(
    String fullPath,
    List<int> bytes, {
      bool atomic = true,
      bool flush = true,
    }) async {
  final target = File(fullPath);
  final parent = target.parent;

  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }

  if (!atomic) {
    await target.writeAsBytes(bytes, flush: flush);
    return;
  }

  // same-dir temp file
  final ts = DateTime.now().microsecondsSinceEpoch;
  final tmpName = '.${p.basename(fullPath)}.$ts.tmp';
  final tmpFile = File(p.join(parent.path, tmpName));

  try {
    await tmpFile.writeAsBytes(bytes, flush: flush);

    // Windows 안전성: 기존 파일이 있으면 삭제 후 rename
    if (await target.exists()) {
      try {
        await target.delete();
      } catch (_) {
        // 삭제 실패 시에도 rename을 시도하되, 실패하면 catch에서 처리
      }
    }

    await tmpFile.rename(fullPath);
  } catch (e) {
    // 실패 시 임시파일 정리만 시도
    try {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    } catch (_) {}
    rethrow;
  }
}