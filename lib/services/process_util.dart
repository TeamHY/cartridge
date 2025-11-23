import 'dart:io';

class ProcessUtil {
  static Future<void> killIsaac() async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/im', 'isaac-ng.exe']);
    } else if (Platform.isMacOS) {
      await Process.run('pkill', ['-f', 'isaac-ng.exe']);
    }
  }

  static Future<void> killSteam() async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/f', '/im', 'steam.exe']);
    } else if (Platform.isMacOS) {
      await Process.run('pkill', ['-f', 'steam.exe']);
    }
  }

  static Future<void> launchIsaac(String isaacPath) async {
    if (Platform.isWindows) {
      await Process.run('$isaacPath/isaac-ng.exe', []);
    } else if (Platform.isMacOS) {
      await Process.run('open', [
        '-a',
        "${Platform.environment['HOME']}/Applications/CrossOver/Steam/The Binding of Isaac Rebirth.app"
      ]);
    }
  }
}
