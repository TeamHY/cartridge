import 'package:cartridge/services/process_util.dart';

class GameLauncherService {
  static Future<void> launchGame({
    required String isaacPath,
    required int rerunDelay,
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

    await ProcessUtil.launchIsaac(isaacPath);
  }
}
