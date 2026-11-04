import 'dart:io';

import 'package:cartridge/models/game_launch_mode.dart';
import 'package:cartridge/services/process_util.dart';
import 'package:cartridge/services/repentogon_cli_service.dart';

class GameLauncherService {
  static Future<void> launchGame({
    required String isaacPath,
    required int rerunDelay,
    GameLaunchMode launchMode = GameLaunchMode.vanilla,
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

    await startIsaac(isaacPath: isaacPath, launchMode: launchMode);
  }

  /// Start the game in [launchMode].
  ///
  /// REPENTOGON is only supported on Windows and throws [RgonCliException]
  /// when the game cannot be started.
  static Future<void> startIsaac({
    required String isaacPath,
    required GameLaunchMode launchMode,
  }) async {
    if (launchMode == GameLaunchMode.repentogon && Platform.isWindows) {
      await RepentogonCliService.ensureInstalled(checkUpdate: false);
      await RepentogonCliService.launch(isaacPath);
      return;
    }

    await ProcessUtil.launchIsaac(isaacPath);
  }
}
