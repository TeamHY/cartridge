import 'dart:io';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/options/isaac_options.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

/// 앱 오케스트레이션 서비스:
/// - 옵션 프리셋 적용 + 모드 동기화 + Isaac 실행
/// - Isaac/Steam 도메인 서비스는 IsaacRuntimeService 를 통해 접근
class IsaacLauncherService {
  static const _tag = 'IsaacLauncherService';

  final IsaacRuntimeService runtime;
  final ModsService modsService;
  final IsaacOptionsIniService optionsIniService;
  final IsaacEnvironmentService _env;

  IsaacLauncherService({
    required this.runtime,
    required this.modsService,
    required this.optionsIniService,
    required IsaacEnvironmentService isaacEnvironmentService,
  })  : _env = isaacEnvironmentService;

  Future<Process?> launchIsaac({
    OptionPreset? optionPreset,
    Map<String, ModEntry> entries = const <String, ModEntry>{}, // 켤 목록(나머지는 disable 정책)
    AppSetting? appSetting,
    String? optionsIniPathOverride,
    String? installPathOverride,
    List<String> extraArgs = const [],
  }) async {
    final delayMs  = appSetting?.rerunDelay ?? 1000;
    final wasRunning = await runtime.killIsaacIfRunning(
      timeout: const Duration(seconds: 5),
    );
    if (wasRunning && delayMs > 0) {
      logI(_tag, 'rerunDelay 적용: ${delayMs}ms 대기 후 재실행');
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // 1) 환경
    final env = await _env.resolveEnvironment(
        optionsIniPathOverride: optionsIniPathOverride);
    if (env == null) return null;

    var effectiveArgs = <String>[...extraArgs];
    // 2) 옵션 프리셋 적용
    if (optionPreset != null) {
      await optionsIniService.apply(optionsIniPath: env.optionsIniPath, options: optionPreset.options);
      effectiveArgs = await buildIsaacExtraArgs(
        installPath: installPathOverride ?? env.installPath,
        preset: optionPreset,
        base: extraArgs,
      );
    }

    // 3) 모드 동기화
    try {
      await modsService.applyPreset(env.modsRoot, entries);
      logI(_tag, 'Mods applyPreset 성공');
    } catch (e, st) {
      logE(_tag, 'ModsService.applyPreset 실패', e, st);
    }

    // 4) 실행
    return runtime.startIsaac(
      installPath: installPathOverride ?? env.installPath,
      extraArgs: effectiveArgs,
    );
  }
}
