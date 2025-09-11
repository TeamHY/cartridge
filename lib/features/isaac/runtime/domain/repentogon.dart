library;

import 'dart:io';
import 'package:path/path.dart' as p;

const kArgRepentogonOff = '-repentogonoff';

/// zhlREPENTOGON.dll 존재만 체크하는 초미니 유틸
abstract final class Repentogon {
  static const dllName = 'zhlREPENTOGON.dll';

  /// 설치 경로(installPath)에 DLL이 있으면 설치됨
  static Future<bool> isInstalled(String installPath) async {
    try {
      return File(p.join(installPath, dllName)).exists();
    } catch (_) {
      return false;
    }
  }
}
