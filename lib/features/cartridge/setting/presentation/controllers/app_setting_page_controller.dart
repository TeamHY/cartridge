import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_environment_service.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_path_resolver.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_runtime_service.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';


/// 설정 화면 전용 액션(UI 유틸). 전역 상태는 appSettingController가 소유.
class AppSettingPageController {
  AppSettingPageController(this.ref);
  final Ref ref;

  IsaacRuntimeService get _isaac => ref.read(isaacRuntimeServiceProvider);
  IsaacEnvironmentService get _env => ref.read(isaacEnvironmentServiceProvider);
  IsaacPathResolver get _pathResolver => ref.read(isaacPathResolverProvider);

  Future<void> runIntegrityCheck() => _isaac.runIntegrityCheck();
  Future<void> openGameProperties() => _isaac.openGameProperties();
  Future<List<String>> listCandidateOptionsIniPaths() =>
      _pathResolver.listCandidateOptionsIniPaths();

  Future<void> setManualOptionsIniPath(String path) =>
      ref.read(appSettingControllerProvider.notifier).patch(
        optionsIniPath: path,
        useAutoDetectOptionsIni: false,
      );

  Future<void> setManualInstallPath(String path) =>
      ref.read(appSettingControllerProvider.notifier).patch(
        isaacPath: path,
        useAutoDetectInstallPath: false,
      );

  Future<void> setAutoDetect({
    bool? installPath,
    bool? optionsIni,
  }) =>
      ref.read(appSettingControllerProvider.notifier).patch(
        useAutoDetectInstallPath: installPath,
        useAutoDetectOptionsIni: optionsIni,
      );

  Future<String?> detectInstallPath() =>
      _isaac.findIsaacInstallPath();

  Future<String?> detectOptionsIniPath() =>
      _env.detectOptionsIniPathAuto();

  Future<IsaacEdition?> inferIsaacEdition() =>
      _isaac.inferIsaacEdition();

  Future<IsaacAutoInfo> detectAutoInfo() async {
    final r = await _env.resolveInstallPathDetailed();

    // 2) 에디션 정보
    final ed    = await inferIsaacEdition();
    final asset = (ed == null) ? null : IsaacEditionInfo.imageAssetFor(ed);

    // 3) Repentogon (전역 규칙에 따름: 유효 경로일 때만 true 가능)
    final repInstalled = await ref.read(repentogonInstalledProvider.future);


    return IsaacAutoInfo(
      editionName: IsaacEditionInfo.folderName[ed],
      editionAsset: asset,
      edition: ed,
      installPath: r.path,
      installStatus: r.status,
      installSource: r.source,
      repentogonInstalled: repInstalled,
    );
  }
}

final appSettingPageControllerProvider =
Provider<AppSettingPageController>((ref) {
  return AppSettingPageController(ref);
});

/// 화면에서 watch할 Provider
final isaacAutoInfoProvider = FutureProvider<IsaacAutoInfo>((ref) async {
  final pc = ref.read(appSettingPageControllerProvider);
  return pc.detectAutoInfo();
});

/// 화면에서 보여줄 "자동 탐지 미리보기" DTO
class IsaacAutoInfo {
  final String? editionName;
  final String? editionAsset;
  final IsaacEdition? edition;
  final String? installPath;
  final bool repentogonInstalled;
  final InstallPathStatus installStatus;
  final InstallPathSource installSource;

  const IsaacAutoInfo({
    required this.editionName,
    required this.editionAsset,
    this.edition,
    this.installPath,
    this.repentogonInstalled = false,
    this.installStatus = InstallPathStatus.notConfigured,
    this.installSource = InstallPathSource.auto,
  });

  bool get canUseRepentogon =>
      edition == IsaacEdition.repentance || edition == IsaacEdition.repentancePlus;
}