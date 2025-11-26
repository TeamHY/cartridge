import 'dart:async';
import 'dart:convert';
import 'dart:io';

class IsaacLogFile {
  IsaacLogFile(String path, {required this.onDebugMessage}) {
    _file = File(path);
    _previousLength = _file.lengthSync();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
      if (_isChecking) return;

      onCheck();
    });
  }

  static const String _prefix = '[INFO] - Lua Debug: ';

  final Function(String) onDebugMessage;

  late final File _file;
  late final Timer _timer;

  int _previousLength = 0;
  bool _isChecking = false;

  void dispose() {
    _timer.cancel();
  }

  void onCheck() {
    _isChecking = true;

    final currentLength = _file.lengthSync();
    final start = currentLength - _previousLength >= 0 ? _previousLength : 0;

    _file
        .openRead(start, currentLength)
        .transform(utf8.decoder)
        .forEach((text) {
      text.split('\n').forEach((line) {
        if (line.startsWith(_prefix)) {
          final message = line.substring(_prefix.length);
          onDebugMessage(message);
        }
      });
    });

    _previousLength = currentLength;
    _isChecking = false;
  }
}
