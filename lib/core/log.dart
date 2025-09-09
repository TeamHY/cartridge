import 'dart:developer' as dev;
import 'dart:io';

enum _LogLevel { info, warn, error }

/// 표준출력 미러링 설정.
/// - 테스트/CLI 환경에서 true로 두면 콘솔에서도 동일 로그를 확인할 수 있다.
class LogConfig {
  static bool mirrorToStdout = false;
}

void _out(_LogLevel level, String tag, String msg, [Object? err, StackTrace? st]) {
  final code = switch (level) { _LogLevel.info => 800, _LogLevel.warn => 900, _LogLevel.error => 1000 };
  dev.log(msg, name: tag, level: code, error: err, stackTrace: st);
  if (LogConfig.mirrorToStdout) {
    final prefix = switch (level) { _LogLevel.info => 'I', _LogLevel.warn => 'W', _LogLevel.error => 'E' };
    stdout.writeln('[$prefix][$tag] $msg${err != null ? ' | $err' : ''}');
    if (st != null) stdout.writeln(st);
  }
}

/// 단순 로거 API.
/// - 향후 로깅 백엔드를 교체하더라도 사용 코드는 그대로 유지하기 위한 래퍼.
void logI(String tag, String msg) => _out(_LogLevel.info, tag, msg);
void logW(String tag, String msg) => _out(_LogLevel.warn, tag, msg);
void logE(String tag, String msg, [Object? err, StackTrace? st]) =>
    _out(_LogLevel.error, tag, msg, err, st);