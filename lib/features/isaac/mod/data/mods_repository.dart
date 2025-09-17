import 'dart:async';
import 'dart:collection';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/isaac/mod/domain/models/installed_mod.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_metadata.dart';


/// 파일시스템 I/O를 전담하는 Repository.
///
/// 책임(Responsibilities):
/// - 설치 루트 1-depth 디렉터리 나열(list).
/// - 각 디렉터리의 `metadata.xml` 읽기(read) → [ModMetadata] 파싱 → [InstalledMod] 구성.
/// - `disable.it` 생성/삭제(write)로 활성/비활성 상태 반영.
///
/// ## 의존성 주입(Dependency Injection)
///
/// - [fs] : `package:file`의 [FileSystem].
///   - **운영 기본값(Production default)**: [LocalFileSystem]
///   - **단위 테스트(Unit test)**: `MemoryFileSystem` 사용 권장(실제 디스크 I/O 없음)
///   - 주의: 활성/비활성 처리는 실제로 `disable.it` 파일 생성/삭제를 수행합니다.
///
/// - [path] : `package:path`의 [p.Context].
///   - **운영 기본값**: [p.context] (host OS의 경로 스타일 자동 사용)
///   - **단위 테스트**: `Context(style: Style.posix)` 권장 → 경로 구분자(`/`)를 고정하여
///     플랫폼 차이를 줄입니다.
///   - 코드에서는 항상 **주입된 [path]**로 경로를 합성하세요. (`p.join` 대신 `path.join`)
///
/// - [defaultScanConcurrency] : 설치 디렉터리 **스캔** 시 동시성(작업 수) 기본값.
///   - I/O bound 작업 특성상 8–16 정도를 권장(SSD/NVMe 기준).
///   - 내부적으로 [1, 64] 범위로 클램프됩니다.
///
/// - [defaultApplyConcurrency] : `disable.it` **쓰기** 시 동시성 기본값.
///   - 파일 핸들/락 경합을 고려해 과도한 값은 지양(8–16 권장).
///
/// ## 동시성/안전성
/// - 멀티 프로세스/멀티 인스턴스 트랜잭션 보장은 없습니다(마지막 쓰기 우선).
/// - 동일 루트에 대해 동시 호출은 가능하나, 과도한 동시성은 파일 핸들 경합을 유발할 수 있습니다.
///
/// ## 프로그램 정책(중요)
/// - **명시적으로 활성화로 매칭되지 않은 모든 설치 모드**는 **비활성화**됩니다.
///   (즉, 기본 `shouldEnable`은 `false` 입니다)
class ModsRepository {
  static const String kMetadataFileName = 'metadata.xml';
  static const String kDisableFlagFileName = 'disable.it';
  static const String _tag = 'ModsRepository';

  final FileSystem fs;
  final p.Context path;

  /// 동시성
  final int defaultScanConcurrency;
  final int defaultApplyConcurrency;

  ModsRepository({
    FileSystem? fs,
    p.Context? path,
    this.defaultScanConcurrency = 8,
    this.defaultApplyConcurrency = 8,
  })  : fs = fs ?? const LocalFileSystem(),
        path = path ?? p.context;


  // ── Scan (READ) ───────────────────────────────────────────────────────────

  /// [root] 경로 하위 **1-depth** 디렉터리를 스캔
  ///
  /// 동작:
  /// - 각 디렉터리의 `metadata.xml`을 읽어 [ModMetadata]로 파싱합니다.
  /// - `disable.it` 존재 여부를 읽어 `disabled` 플래그를 설정합니다.
  /// - `metadata.xml` 누락/파싱 실패 디렉터리는 **스킵**합니다.
  ///
  /// 파라미터:
  /// - [scanConcurrency]: 이 호출에 한해 [defaultScanConcurrency]를 오버라이드(선택).
  Future<Map<String, InstalledMod>> scanInstalledMap(
      String root, {
        int? scanConcurrency,
      }) async {
    final scan = await _scanInstalled(
      root,
      scanConcurrency: scanConcurrency ?? defaultScanConcurrency,
    );
    return scan.itemsByFolder;
  }

  /// 내부 스캔: key=folderName 맵으로 구성(중복 발생 시 last-win, 경고 로그)
  Future<_InstalledScan> _scanInstalled(
      String root, {
        int? scanConcurrency,
      }) async {
    final dirs = await _listFirstLevelDirs(root);
    final map = <String, InstalledMod>{};
    int skippedCount = 0;

    final sc = (scanConcurrency ?? defaultScanConcurrency).clamp(1, 64);

    await _forEachLimited<Directory>(dirs, sc, (d) async {
        final xml = await _readMetadataXml(d);
        if (xml == null) {
          skippedCount++;
          logW(_tag,
              'op=list fn=_scanInstalled msg=$kMetadataFileName 없음 path=${d.path} root=$root');
          return;
        }
        try {
          final metadata = ModMetadata.fromXmlString(xml);
          final hasDisableFlag = await _existsDisableItFile(d);

          final mod = InstalledMod(
            metadata: metadata,
            disabled: hasDisableFlag,
            installPath: d.path, // 절대 경로
          );

          final key = path.basename(d.path);
          if (mod.folderName != key) {
            logI(_tag,
              'op=list fn=_scanInstalled msg=폴더명 불일치 actual="$key" derived="${mod.folderName}" hint=metadata.directory/id가 실제 폴더와 다를 수 있습니다 path=${d.path}');
          }
          if (map.containsKey(key)) {
            logW(
              _tag,
              'op=list fn=_scanInstalled msg=중복 폴더명(last-win) key=$key prev=${map[key]?.installPath} curr=${d.path}',
            );
          }
          map[key] = mod; // last-win
        } catch (e, st) {
          skippedCount++;
          logW(_tag, 'op=list fn=_scanInstalled msg=metadata 파싱 실패 path=${d.path}');
          logE(_tag, 'op=list fn=_scanInstalled msg=파싱 예외 path=${d.path}', e, st);
        }
      },
    );

    logI(
      _tag,
      'op=list fn=_scanInstalled msg=스캔 완료 installed=${map.length} skipped=$skippedCount root=$root',
    );

    // 불변 맵으로 래핑
    return _InstalledScan(
      itemsByFolder: UnmodifiableMapView(map),
      skippedCount: skippedCount,
    );
  }

  // ── 모드 활성화/비활성화하기 ───────────────────────────────────────────────────────────

  /// 프리셋 요청([requested])에 맞춰 `disable.it` 파일을 생성/삭제합니다.
  ///
  /// 매칭 규칙: Windows 전용: 폴더명 키 기준으로 활성화/비활성화만 수행.
  ///
  /// 정책(Program Policy):
  /// - requested[folder].enabled == true → ON
  /// - 그 외(키 없음/false) → OFF
  /// - 중복은 last-win
  ///
  /// 동시성:
  /// - [applyConcurrency]로 호출 단위 오버라이드 가능.
  Future<void> applyPreset(
      String root,
      Map<String, ModEntry> requested, {
        int? applyConcurrency,  // 주입 기본값 사용, 필요 시 오버라이드
      }) async {
    // concurrency 강제로 1-64 제한
    final ac = (applyConcurrency ?? defaultApplyConcurrency).clamp(1, 64);
    final dirs = await _listFirstLevelDirs(root);

    await _forEachLimited<Directory>(dirs, ac, (d) async {
      final folder = path.basename(d.path);
      if (!await d.exists()) return;

      final shouldEnable = requested[folder]?.enabled ?? false;
      final flag = fs.file(path.join(d.path, kDisableFlagFileName));

      try {
        final exists = await flag.exists();

        if (shouldEnable) {
          if (exists) {
            await flag.delete();
          }
        } else {
          if (!exists) {
            await flag.create(recursive: true);
            await flag.writeAsBytes(const <int>[]);
          }
        }
      } catch (e, st) {
        logE(_tag, 'op=apply msg=flag set failed folder=$folder', e, st);
      }
    });
  }

  // ── Internals(내부 유틸) ───────────────────────────────────────────────────────────

  Future<String?> _readMetadataXml(Directory dir) async {
    final f = fs.file(path.join(dir.path, kMetadataFileName));
    return await f.exists() ? f.readAsString() : null;
  }

  Future<bool> _existsDisableItFile(Directory dir) async {
    final f = fs.file(path.join(dir.path, kDisableFlagFileName));
    return f.exists();
  }

  Future<List<Directory>> _listFirstLevelDirs(String root) async {
    final dir = fs.directory(root);
    if (!await dir.exists()) {
      logW(_tag, 'op=list msg=root not found root=$root');
      return const <Directory>[];
    }
    final entries = await dir.list(followLinks: false).toList();
    return [for (final e in entries) if (e is Directory) e];
  }

  Future<void> _forEachLimited<T>(
      Iterable<T> items,
      int limit,
      FutureOr<void> Function(T) task,
      ) async {
    final list = items is List<T> ? items : items.toList(growable: false);
    var index = 0;

    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= list.length) break;
        await task(list[i]);
      }
    }

    final n = limit.clamp(1, 64);
    await Future.wait([for (var i = 0; i < n; i++) worker()]);
  }
}

/// 내부 스캔 결과(불변 맵 + 스킵 카운트)
class _InstalledScan {
  /// key = 실제 폴더명(basename)
  final UnmodifiableMapView<String, InstalledMod> itemsByFolder;
  final int skippedCount;
  const _InstalledScan({required this.itemsByFolder, required this.skippedCount});
}
