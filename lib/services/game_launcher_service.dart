import 'dart:io';

import 'package:cartridge/models/game_launch_mode.dart';
import 'package:cartridge/services/process_util.dart';
import 'package:cartridge/services/repentogon_cli_service.dart';
import 'package:cartridge/services/steam_save_service.dart';

class GameLauncherService {
  static const _isaacAppId = '250900';
  static const _installFixes = {
    'repentogon_not_installed',
    'repentogon_incompatible',
  };

  static Future<void> launchGame({
    required String isaacPath,
    required int rerunDelay,
    GameLaunchMode launchMode = GameLaunchMode.vanilla,
    Future<bool> Function()? installRepentogon,
    bool isForceUpdate = false,
    bool isNoDelay = false,
  }) async {
    await ProcessUtil.killIsaac();

    if (isForceUpdate) {
      await ProcessUtil.killSteam();
    }

    if (!isNoDelay) {
      await Future.delayed(Duration(milliseconds: rerunDelay));
    }

    await startIsaac(
      isaacPath: isaacPath,
      launchMode: launchMode,
      installRepentogon: installRepentogon,
    );
  }

  /// Start the game in [launchMode].
  ///
  /// REPENTOGON is only supported on Windows and gets the game's Steam launch
  /// options that rgon-cli understands. When rgon-cli or REPENTOGON is
  /// missing, [installRepentogon] is called to set them up before launching;
  /// it returns false when the setup failed, and the game is not started.
  /// Throws [RgonCliException] when the game cannot be started.
  static Future<void> startIsaac({
    required String isaacPath,
    required GameLaunchMode launchMode,
    Future<bool> Function()? installRepentogon,
  }) async {
    if (launchMode != GameLaunchMode.repentogon || !Platform.isWindows) {
      await ProcessUtil.launchIsaac(isaacPath);
      return;
    }

    if (installRepentogon != null &&
        await RepentogonCliService.installedTag() == null &&
        !await installRepentogon()) {
      return;
    }

    final steamOptions = await SteamSaveService()
        .readLaunchOptions(appId: _isaacAppId, isaacPath: isaacPath);
    final extraArgs =
        RepentogonCliService.launchArgsFromSteamOptions(steamOptions ?? '');

    try {
      await RepentogonCliService.ensureInstalled(checkUpdate: false);
      await RepentogonCliService.launch(isaacPath, extraArgs: extraArgs);
    } on RgonCliException catch (e) {
      if (installRepentogon == null || !_installFixes.contains(e.code)) {
        rethrow;
      }
      if (!await installRepentogon()) return;
      await RepentogonCliService.launch(isaacPath, extraArgs: extraArgs);
    }
  }
}
