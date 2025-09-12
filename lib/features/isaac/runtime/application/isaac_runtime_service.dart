import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_steam_ids.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:cartridge/features/steam/domain/steam_link_builder.dart';
import 'package:cartridge/features/steam/domain/steam_links_port.dart';
import 'package:cartridge/features/steam/domain/steam_library_port.dart';

const isaacExeFile = 'isaac-ng.exe';

/// Isaac 런타임/스팀 상호작용 전담
/// - 설치경로/에디션 추론(=Steam manifest)
/// - 스팀 딥링크/웹뷰
/// - 프로세스 실행
class IsaacRuntimeService {
  static const _tag = 'IsaacRuntimeService';

  final SteamLinksPort links;
  final SteamLibraryPort library;

  IsaacRuntimeService({
    required this.links,
    required this.library,
  });

  // ── Steam/설치/에디션 ────────────────────────────────────────────────────────

  Future<String?> findIsaacInstallPath({String? steamBaseOverride}) =>
      library.findGameInstallPath(
        IsaacSteamIds.appId,
        steamBaseOverride: steamBaseOverride,
      );

  Future<IsaacEdition?> inferIsaacEdition({String? steamBaseOverride}) async {
    final depots = await library.readInstalledDepots(
      IsaacSteamIds.appId,
      steamBaseOverride: steamBaseOverride,
    );
    final edition = IsaacEditionInfo.chooseEditionFromDepots(depots);
    logI(_tag, 'inferIsaacEdition → $edition, depots=$depots');
    return edition;
  }

  // ── 딥링크/스팀 액션 ─────────────────────────────────────────────────────────

  Future<void> openWorkshopItem(String workshopId) =>
      links.openUri(SteamUris.workshopItem(workshopId));

  Future<void> openWorkshopHome() =>
      links.openUri(SteamUris.workshopApp(IsaacSteamIds.appId));

  Future<void> openGameProperties() =>
      links.openUri(SteamUris.gameProperties(IsaacSteamIds.appId));

  Future<void> runIntegrityCheck() =>
      links.openUri(SteamUris.validate(IsaacSteamIds.appId));

  Future<void> openPreferSteamClient(String webUrl) =>
      links.openUri(SteamLinkBuilder.preferSteamClientIfPossible(webUrl));

  // ── 실행 ────────────────────────────────────────────────────────────────────

  Future<Process?> startIsaac({
    required String installPath,
    List<String> extraArgs = const [],
    bool? viaSteam,
    String? steamBaseOverride,
  }) async {
    final userPath = installPath;
    final userExe  = File(p.join(userPath, isaacExeFile));
    final userExeExists = await userExe.exists();

    // 자동탐지 경로(스팀 설치 기준)
    String? autoPath;
    try {
      autoPath = await findIsaacInstallPath(steamBaseOverride: steamBaseOverride);
    } catch (_) {
      autoPath = null;
    }

    // ── 규칙 ────────────────────────────────────────────────────────────────
    // 1) 사용자 경로 + 인자 없음 → 직접 실행
    // 2) 사용자 경로 + 인자 있음 + 사용자경로 == 자동탐지경로 → Steam 경유 실행(경고 회피)
    // 3) 사용자 경로 + 인자 있음 + 경로 다름 → 직접 실행
    // 4) 사용자 경로에 exe 없음 → 즉시 실패(return null)
    if (!userExeExists) {
      logE(_tag, '사용자 경로에 실행 파일이 없습니다. 실행을 중단합니다. path=$userPath', null);
      return null;
    }

    bool shouldRunViaSteam;
    if (extraArgs.isEmpty) {
      logI(_tag, '의사결정: 사용자 경로 + 인자 없음 → 직접 실행');
      shouldRunViaSteam = false;
    } else {
      final sameAsAuto = _pathsEqual(userPath, autoPath);
      if (sameAsAuto) {
        logI(_tag, '의사결정: 사용자 경로 == 자동탐지 경로 + 인자 있음 → Steam 경유 실행(경고 회피)');
        shouldRunViaSteam = true;
      } else {
        logI(_tag, '의사결정: 사용자 경로(비표준) + 인자 있음 → 직접 실행(사용자 선택 우선)');
        shouldRunViaSteam = false;
      }
    }

    if (viaSteam != null) {
      logW(_tag, 'viaSteam 파라미터는 호환용이며, 내부 규칙이 우선 적용됩니다. viaSteam=$viaSteam → 결정=${shouldRunViaSteam ? 'Steam' : 'Direct'}');
    }

    // ── 실행 ────────────────────────────────────────────────────────────────
    if (shouldRunViaSteam) {
      final proc = await _startViaSteam(
        extraArgs: extraArgs,
        steamBaseOverride: steamBaseOverride,
      );
      if (proc != null) return proc;

      // Steam 실패 시에도 더 이상 다른 폴백 없음 (사용자 의사/규칙 존중)
      logE(_tag, 'Steam 경유 실행 실패. 다른 폴백 없이 종료합니다.', null);
      return null;
    } else {
      return _startDirect(installPath: userPath, extraArgs: extraArgs);
    }
  }

  Future<bool> isIsaacRunning() async {
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run(
        'tasklist',
        ['/FI', 'IMAGENAME eq $isaacExeFile', '/FO', 'CSV', '/NH'],
        runInShell: true,
      );
      final out = (res.stdout ?? '').toString().toLowerCase();
      // 프로세스가 있으면 해당 행에 "isaac-ng.exe" 가 포함됩니다.
      final running = out.contains(isaacExeFile.toLowerCase());
      if (running) {
        logI(_tag, 'Isaac 프로세스 감지됨(tasklist).');
      }
      return running;
    } catch (_, __) {
      logW(_tag, 'isIsaacRunning 확인 실패(Windows tasklist 호출 실패로 간주).');
      return false;
    }
  }

  Future<bool> killIsaacIfRunning({Duration timeout = const Duration(seconds: 5)}) async {
    if (!Platform.isWindows) return false;

    final wasRunning = await isIsaacRunning();
    if (!wasRunning) return false;

    try {
      // /T: 자식 프로세스도 함께 종료, /F: 강제 종료
      await Process.run(
        'taskkill', ['/IM', isaacExeFile, '/F', '/T'],
        runInShell: true,
      );
    } catch (_, __) {
      logW(_tag, 'taskkill 실패(무시하고 폴링으로 재확인).');
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!await isIsaacRunning()) {
        logI(_tag, 'Isaac 프로세스 정리 완료.');
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }

    logW(_tag, 'Isaac 프로세스가 timeout 내 종료되지 않았습니다(무시하고 진행).');
    return true; // 실행 중이었음은 맞으니 true 반환
  }
// 경로 동등성 체크(Windows용 대충 맞춤: 정규화/구분자 통일/소문자/트레일링 슬래시 제거)
  bool _pathsEqual(String? a, String? b) {
    if (a == null || b == null) return false;
    String norm(String s) {
      final n = p.normalize(s).replaceAll('\\', '/').toLowerCase();
      return n.endsWith('/') ? n.substring(0, n.length - 1) : n;
    }
    return norm(a) == norm(b);
  }

  Future<Process?> _startViaSteam({
    required List<String> extraArgs,
    String? steamBaseOverride,
  }) async {
    final steamExe = await _resolveSteamExePath(steamBaseOverride: steamBaseOverride);
    if (steamExe == null) {
      logE(_tag, 'steam.exe 위치를 찾을 수 없습니다.', null);
      return null;
    }

    final args = <String>[
      '-applaunch',
      IsaacSteamIds.appId.toString(),
      ...extraArgs,
    ];

    logI(_tag, 'Steam 경유 실행: "$steamExe" ${args.join(' ')}');
    try {
      // workingDirectory 생략 OK (steam.exe 자체가 알아서 처리)
      return await Process.start(steamExe, args);
    } catch (e, st) {
      logE(_tag, 'Steam 경유 실행 실패', e, st);
      return null;
    }
  }

  /// 기존 직접 실행(레거시)
  Future<Process?> _startDirect({
    required String installPath,
    required List<String> extraArgs,
  }) async {
    final exe = File(p.join(installPath, isaacExeFile));
    if (!await exe.exists()) {
      logE(_tag, '실행 파일이 없습니다: ${exe.path}', null);
      return null;
    }
    logI(_tag, '직접 실행: ${exe.path} ${extraArgs.join(' ')}');
    try {
      return await Process.start(
        exe.path,
        extraArgs,
        workingDirectory: installPath,
      );
    } catch (e, st) {
      logE(_tag, '직접 실행 실패', e, st);
      return null;
    }
  }
  Future<String?> _resolveSteamExePath({String? steamBaseOverride}) async {
    // 0) Settings 기반 override 우선
    // - 사용자가 지정한 폴더(예: C:\Program Files (x86)\Steam),
    if (steamBaseOverride != null && steamBaseOverride.trim().isNotEmpty) {
      final override = steamBaseOverride.trim();
      // exe 직접 지정 케이스
      final asFile = File(override);
      if (await asFile.exists()) {
        logI(_tag, 'steam.exe resolved (override=file): $override');
        return asFile.path;
      }
      // 디렉터리 지정 케이스
      final asDir = Directory(override);
      if (await asDir.exists()) {
        final candidate = File(p.join(asDir.path, 'steam.exe'));
        if (await candidate.exists()) {
          logI(_tag, 'steam.exe resolved (override=dir): ${candidate.path}');
          return candidate.path;
        }
        logW(_tag, 'override 디렉터리에 steam.exe 없음: ${asDir.path}');
      } else {
        logW(_tag, 'override 경로가 존재하지 않습니다: $override');
      }
    }

    // 1) ENV override
    final envPath = Platform.environment['STEAM_EXE'];
    if (envPath != null && await File(envPath).exists()) {
      return envPath;
    }

    // 2) Program Files (x86)
    final pf86 = Platform.environment['ProgramFiles(x86)'] ??
        Platform.environment['PROGRAMFILES(X86)'];
    if (pf86 != null) {
      final f = File(p.join(pf86, 'Steam', 'steam.exe'));
      if (await f.exists()) return f.path;
    }

    // 3) Program Files
    final pf = Platform.environment['ProgramFiles'] ??
        Platform.environment['PROGRAMFILES'];
    if (pf != null) {
      final f = File(p.join(pf, 'Steam', 'steam.exe'));
      if (await f.exists()) return f.path;
    }

    return null;
  }
}
