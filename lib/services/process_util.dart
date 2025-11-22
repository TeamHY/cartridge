import 'dart:io';

class ProcessUtil {
  static Future<void> killIsaac() async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/im', 'isaac-ng.exe']);
    }
  }

  static Future<void> killSteam() async {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/f', '/im', 'steam.exe']);
    }
  }
}
