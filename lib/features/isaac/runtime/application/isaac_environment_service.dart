import 'dart:io';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/isaac/mod/domain/models/installed_mod.dart';
import 'package:cartridge/features/isaac/mod/domain/mods_service.dart';
import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_path_resolver.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_runtime_service.dart';
import 'package:path/path.dart' as p;

class LaunchEnvironment {
  final String installPath;
  final String optionsIniPath;
  final String modsRoot;
  const LaunchEnvironment({
    required this.installPath,
    required this.optionsIniPath,
    required this.modsRoot,
  });
}

class IsaacEnvironmentService {
  static const String _tag = 'IsaacEnvironmentService';

  IsaacEnvironmentService({
    required SettingService settings,
    required IsaacRuntimeService isaac,
    required IsaacPathResolver pathResolver,
    required ModsService mods,
  })  : _settings = settings,
        _isaac = isaac,
        _pathResolver = pathResolver,
        _mods = mods;

  final SettingService _settings;
  final IsaacRuntimeService _isaac;
  final IsaacPathResolver _pathResolver;
  final ModsService _mods;

  Future<bool> isValidInstallDir(String? dir) async {
    if (dir == null || dir.trim().isEmpty) return false;
    final d = Directory(dir);
    if (!await d.exists()) return false;
    final exe = File(p.join(dir, isaacExeFile));
    return await exe.exists();
  }

  // ── installPath 결정 ───────────────────────────────────────────────────────────
  // Settings → steamBaseOverride 유틸
  Future<String?> _steamBaseOverrideFromSettings() async {
    final s = await _settings.getNormalized();
    if (s.useAutoDetectSteamPath) return null;
    final v = s.steamPath.trim();
    return v.isEmpty ? null : v;
  }

  /// 2) 우선순위(수동/자동)에 따라 경로 결정 + 상세 상태 반환
  /// - 수동 선택(useAutoDetectInstallPath == false)이면 **반드시 그 경로**만 검사
  /// - 자동 선택이면 자동탐지 시도; 실패면 autoDetectFailed
  Future<InstallPathResolution> resolveInstallPathDetailed({
    String? installPathOverride,
  }) async {
    final s = await _settings.getNormalized(); // 현 보유 설정

    // 수동 우선: 설정이 수동이고 수동 경로가 쓰일 조건이면, 그 경로만 검사
    final bool manualSelected = !s.useAutoDetectInstallPath;
    final String? manualPath = (installPathOverride ?? s.isaacPath).trim().isEmpty
        ? null
        : (installPathOverride ?? s.isaacPath).trim();

    if (manualSelected) {
      if (manualPath == null) {
        return const InstallPathResolution(
          path: null,
          status: InstallPathStatus.notConfigured,
          source: InstallPathSource.manual,
          isValid: false,
        );
      }
      final dir = Directory(manualPath);
      if (!await dir.exists()) {
        return InstallPathResolution(
          path: manualPath,
          status: InstallPathStatus.dirNotFound,
          source: InstallPathSource.manual,
          isValid: false,
        );
      }
      final ok = await isValidInstallDir(manualPath);
      return InstallPathResolution(
        path: manualPath,
        status: ok ? InstallPathStatus.ok : InstallPathStatus.exeNotFound,
        source: InstallPathSource.manual,
        isValid: ok,
      );
    }

    final steamBase = await _steamBaseOverrideFromSettings();
    final auto = await _isaac.findIsaacInstallPath(
      steamBaseOverride: steamBase,
    );
    if (auto == null || auto.trim().isEmpty) {
      return const InstallPathResolution(
        path: null,
        status: InstallPathStatus.autoDetectFailed,
        source: InstallPathSource.auto,
        isValid: false,
      );
    }
    final ok = await isValidInstallDir(auto);
    return InstallPathResolution(
      path: auto,
      status: ok ? InstallPathStatus.ok : InstallPathStatus.exeNotFound,
      source: InstallPathSource.auto,
      isValid: ok,
    );
  }

  /// 3) 기존 API 호환: 유효할 때만 경로 반환(아니면 null)
  Future<String?> resolveInstallPath() async {
    final r = await resolveInstallPathDetailed();
    return r.isValid ? r.path : null;
  }

  // ── options.ini 후보 탐색 ───────────────────────────────────────────────────────────
  Future<String?> detectOptionsIniPathAuto({
    List<String> fallbackCandidates = const [],
  }) async {
    final hit = await _autoDetectOptionsIni(fallbackCandidates: fallbackCandidates);
    if (hit != null) {
      logI(_tag, 'options.ini auto-only detected: $hit');
      return hit;
    }
    logW(_tag, 'options.ini auto-only detection failed');
    return null;
  }

  Future<String?> resolveOptionsIniPath({
    String? override,
    List<String> fallbackCandidates = const [],
  }) async {
    // 1) override 최우선
    if (override != null && await File(override).exists()) {
      logI(_tag, 'options.ini resolved (override): $override');
      return override;
    }

    // 2) 설정 기반 수동 우선
    final s = await _settings.getNormalized();
    if (!s.useAutoDetectOptionsIni && s.optionsIniPath.trim().isNotEmpty) {
      final manual = s.optionsIniPath.trim();
      if (await File(manual).exists()) {
        logI(_tag, 'options.ini resolved (manual): $manual');
        return manual;
      }
      logW(_tag, 'manual options.ini not found: $manual (fallback to auto)');
    }

    // 3) 자동탐지
    final auto = await _autoDetectOptionsIni(fallbackCandidates: fallbackCandidates);
    if (auto != null) return auto;

    logW(_tag, 'options.ini not found (return null)');
    return null;
  }

  // ── 환경 번들 ───────────────────────────────────────────────────────────
  Future<LaunchEnvironment?> resolveEnvironment({
    String? optionsIniPathOverride,
    List<String> fallbackIniCandidates = const [],
  }) async {
    final install = await resolveInstallPath();
    final ini = await resolveOptionsIniPath(
      override: optionsIniPathOverride,
      fallbackCandidates: fallbackIniCandidates,
    );
    if (install == null || ini == null) return null;

    final modsRoot = _pathResolver.deriveModsRootFromInstallPath(install);
    logI(_tag, "게임 실행 경로: $install, options.ini 경로: $ini");
    return LaunchEnvironment(
      installPath: install,
      optionsIniPath: ini,
      modsRoot: modsRoot,
    );
  }

  Future<String?> resolveModsRoot() async {
    final install = await resolveInstallPath();
    if (install == null) return null;
    return _pathResolver.deriveModsRootFromInstallPath(install);
  }

  Future<Map<String, InstalledMod>> getInstalledModsMap() async {
    final modsRoot = await resolveModsRoot();
    if (modsRoot == null) {
      logW(_tag, 'getInstalledModsMap: installPath not resolved');
      return const <String, InstalledMod>{};
    }
    return _mods.getInstalledMap(modsRoot);
  }

  Future<String?> _autoDetectOptionsIni({
    List<String> fallbackCandidates = const [],
  }) async {
    final preferred = await _isaac.inferIsaacEdition(
      steamBaseOverride: await _steamBaseOverrideFromSettings(),
    );
    logI(_tag, 'infer Isaac Edition: $preferred');

    if (preferred == null) {
      logW(_tag, 'edition not inferred → skip options.ini auto-detect');
      return null;
    }
    final candidates = await _pathResolver.listCandidateOptionsIniPaths(
      preferredEdition: preferred,
    );
    logI(_tag, 'candidates options.ini path: $candidates');

    for (final c in candidates) {
      if (await File(c).exists()) {
        logI(_tag, 'options.ini resolved (auto): $c');
        return c;
      }
    }
    for (final f in fallbackCandidates) {
      if (await File(f).exists()) {
        logI(_tag, 'options.ini resolved (fallback): $f');
        return f;
      }
    }
    return null;
  }
}
