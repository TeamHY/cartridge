import 'dart:async';

abstract class RecordModeAllowedPrefsRepository {
  Future<Map<String, bool>> readAll();
  Future<void> writeAll(Map<String, bool> map);
}
