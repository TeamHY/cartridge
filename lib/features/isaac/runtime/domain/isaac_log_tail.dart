import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Domain model for parsed Isaac log message.
class IsaacLogMessage {
  IsaacLogMessage({required this.topic, required this.parts, required this.rawLine});
  final String topic;
  final List<String> parts;
  final String rawLine;
}

/// Contract for an Isaac log tailing service.
abstract class IsaacLogTail {
  /// A broadcast stream of parsed log messages.
  Stream<IsaacLogMessage> get messages;

  /// Starts watching the log source.
  Future<void> start();

  /// Stops watching and releases resources.
  Future<void> stop();
}

/// File-based implementation that tails an Isaac log file.
class FileIsaacLogTail implements IsaacLogTail {
  FileIsaacLogTail(
    this.path, {
    Duration interval = const Duration(milliseconds: 50),
    this.prefix = '[INFO] - Lua Debug: [CR]',
  }) : _interval = interval;

  final String path;
  final String prefix;
  final Duration _interval;

  final _controller = StreamController<IsaacLogMessage>.broadcast();
  Timer? _timer;
  File? _file;
  int _previousLength = 0;
  bool _isChecking = false;
  bool _started = false;

  @override
  Stream<IsaacLogMessage> get messages => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _file = File(path);
    try {
      if (!await _file!.exists()) {
        // Create empty file so tailing can begin when it appears
        await _file!.create(recursive: true);
      }
      _previousLength = await _file!.length();
    } catch (e, st) {
      _controller.addError(e, st);
    }
    _timer = Timer.periodic(_interval, (_) => _onCheck());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
    _started = false;
  }

  void _onCheck() {
    if (_isChecking) return;
    _isChecking = true;

    final file = _file;
    if (file == null) {
      _isChecking = false;
      return;
    }

    late final int currentLength;
    try {
      currentLength = file.lengthSync();
    } catch (e, st) {
      _controller.addError(e, st);
      _isChecking = false;
      return;
    }

    final start = currentLength - _previousLength >= 0 ? _previousLength : 0;

    try {
      file
          .openRead(start, currentLength)
          .transform(utf8.decoder)
          .forEach((chunk) {
        for (final line in chunk.split('\n')) {
          final trimmed = line.trimRight();
          if (trimmed.isEmpty) continue;
          if (trimmed.startsWith(prefix)) {
            final message = trimmed.substring(prefix.length);
            // Split only into two parts: topic and rest
            final idx = message.indexOf(':');
            if (idx <= 0) continue;
            final topic = message.substring(0, idx).trim();
            final payload = message.substring(idx + 1);
            final parts = payload.split('.');
            _controller.add(IsaacLogMessage(topic: topic, parts: parts, rawLine: trimmed));
          }
        }
      });
    } catch (e, st) {
      _controller.addError(e, st);
    }

    _previousLength = currentLength;
    _isChecking = false;
  }
}
