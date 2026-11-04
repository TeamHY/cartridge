import 'dart:io';

import 'package:cartridge/models/repentogon_status.dart';
import 'package:cartridge/services/repentogon_cli_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Write a fake rgon-cli (shell script) that prints [stdoutLines].
Future<String> _fakeCli(Directory dir, List<String> stdoutLines,
    {int exitCode = 0}) async {
  final script = File('${dir.path}/rgon-cli');
  final body = stdoutLines.map((line) => "printf '%s\\n' '$line'").join('\n');
  await script.writeAsString('#!/bin/sh\n$body\nexit $exitCode\n');
  await Process.run('chmod', ['+x', script.path]);
  return script.path;
}

void main() {
  group('RepentogonStatus.fromJson', () {
    test('parses a launchable installation', () {
      final status = RepentogonStatus.fromJson({
        'isaac': {
          'valid': true,
          'compatible': true,
          'version': 'v1.9.7.12.J273',
          'reason': 'Should just work.',
        },
        'repentogon': {
          'installed': true,
          'launchable': true,
          'state': 'modern',
          'version': '1.1.2',
        },
      });

      expect(status.isaacValid, isTrue);
      expect(status.isaacCompatible, isTrue);
      expect(status.isaacVersion, 'v1.9.7.12.J273');
      expect(status.installed, isTrue);
      expect(status.launchable, isTrue);
      expect(status.state, 'modern');
      expect(status.version, '1.1.2');
    });

    test('defaults missing fields to a non installed state', () {
      final status = RepentogonStatus.fromJson({
        'isaac': {'valid': false, 'version': ''},
      });

      expect(status.isaacValid, isFalse);
      expect(status.isaacVersion, isNull);
      expect(status.installed, isFalse);
      expect(status.launchable, isFalse);
      expect(status.state, 'none');
      expect(status.version, isNull);
    });
  });

  group('RepentogonCliService.runExecutable', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('rgon_cli_test');
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test('forwards events and returns the result line', () async {
      final exe = await _fakeCli(dir, [
        '{"type":"log","level":"info","message":"Downloading"}',
        'not json',
        '{"type":"download","file":"./launcher-data/REPENTOGON.zip","bytes":2048}',
        '{"type":"result","command":"install","ok":true,"outcome":"installed"}',
      ]);

      final events = <RgonCliEvent>[];
      final result = await RepentogonCliService.runExecutable(exe, ['install'],
          onEvent: events.add);

      expect(result.ok, isTrue);
      expect(result.exitCode, 0);
      expect(result.json['outcome'], 'installed');

      expect(events, hasLength(3));
      expect((events[0] as RgonCliLogEvent).message, 'Downloading');
      expect((events[1] as RgonCliLogEvent).message, 'not json');
      final download = events[2] as RgonCliDownloadEvent;
      expect(download.file, './launcher-data/REPENTOGON.zip');
      expect(download.bytes, 2048);
    });

    test('exposes the error of a failed result', () async {
      final exe = await _fakeCli(
          dir,
          [
            '{"type":"result","command":"launch","ok":false,"error":"repentogon_not_installed","message":"missing"}',
          ],
          exitCode: 1);

      final result = await RepentogonCliService.runExecutable(exe, ['launch']);
      final error = result.toException();

      expect(result.ok, isFalse);
      expect(result.exitCode, 1);
      expect(error.code, 'repentogon_not_installed');
      expect(error.message, 'missing');
    });

    test('throws when no result line is written', () async {
      final exe = await _fakeCli(dir, ['{"type":"log","message":"crash"}'],
          exitCode: 3);

      expect(
        () => RepentogonCliService.runExecutable(exe, ['status']),
        throwsA(isA<RgonCliException>()
            .having((e) => e.code, 'code', 'cli_no_result')),
      );
    });
  }, skip: Platform.isWindows ? 'uses a POSIX shell script' : null);
}
