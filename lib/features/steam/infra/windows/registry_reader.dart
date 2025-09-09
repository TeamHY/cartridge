import 'package:win32_registry/win32_registry.dart';

abstract class RegReader {
  String? readString(RegistryHive hive, String path, String value);
}

class RealRegReader implements RegReader {
  @override
  String? readString(RegistryHive hive, String path, String value) {
    try {
      final k = Registry.openPath(hive, path: path);
      final v = k.getStringValue(value);
      k.close();
      return (v != null && v.trim().isNotEmpty) ? v : null;
    } catch (_) {
      return null;
    }
  }
}

