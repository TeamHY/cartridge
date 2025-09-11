import 'dart:io';
import 'package:path/path.dart' as p;

/// 폴더 열기 (경로가 파일이어도 보통은 상관없지만, 확실히 하려면 [revealInFolder] 사용)
Future<void> openFolder(String? path) async {
  if (path == null) return;
  var target = path.trim();
  if (target.isEmpty) return;
  if (Platform.isWindows) {
    final ctx = p.Context(style: p.Style.windows);
    target = ctx.normalize(target);
  } else {
    target = p.normalize(target);
  }

  try {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [target]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [target]);
    } else if (Platform.isLinux) {
      final r = await Process.run('xdg-open', [target]);
      if (r.exitCode != 0) {
        // 베스트에포트 대체 시도
        for (final cmd in ['gio', 'nautilus', 'dolphin', 'thunar', 'pcmanfm']) {
          try {
            final args = cmd == 'gio' ? ['open', target] : [target];
            final rr = await Process.run(cmd, args);
            if (rr.exitCode == 0) return;
          } catch (_) {}
        }
      }
    }
  } catch (_) {}
}

/// 파일이 주어졌을 때 “폴더에서 선택/강조” 시도
Future<void> revealInFolder(String path) async {
  final t = path.trim();
  if (t.isEmpty) return;

  try {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', t]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', t]);
    } else if (Platform.isLinux) {
      // 일부 파일 매니저만 --select 지원, 안 되면 부모 폴더 열기
      for (final pair in [
        ['nautilus', ['--select', t]],
        ['dolphin',  ['--select', t]],
        ['thunar',   ['--select', t]],
      ]) {
        try {
          final rr = await Process.run(pair[0] as String, pair[1] as List<String>);
          if (rr.exitCode == 0) return;
        } catch (_) {}
      }
      await openFolder(p.dirname(t));
    }
  } catch (_) {}
}
