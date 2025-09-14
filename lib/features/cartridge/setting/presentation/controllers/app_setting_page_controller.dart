import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/steam/steam.dart';


/// 설정 화면 전용 액션(UI 유틸). 전역 상태는 appSettingController가 소유.
class AppSettingPageController {
  AppSettingPageController(this.ref);
  final Ref ref;

  SteamInstallPort get _steam => ref.read(steamInstallPortProvider);
  IsaacRuntimeService get _isaac => ref.read(isaacRuntimeServiceProvider);
  IsaacEnvironmentService get _env => ref.read(isaacEnvironmentServiceProvider);

  Future<String?> detectSteamPath() =>
      _steam.autoDetectBaseDir();

  Future<String?> detectInstallPath() =>
      _isaac.findIsaacInstallPath();

  Future<String?> detectOptionsIniPath() =>
      _env.detectOptionsIniPathAuto();

  Future<IsaacEdition?> inferIsaacEdition() =>
      _isaac.inferIsaacEdition();
}

final appSettingPageControllerProvider =
Provider<AppSettingPageController>((ref) {
  return AppSettingPageController(ref);
});
