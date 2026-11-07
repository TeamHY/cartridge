import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cartridge/models/repentogon_status.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Error raised by rgon-cli (its `error` code) or while managing it.
class RgonCliException implements Exception {
  const RgonCliException(this.code, [this.message]);

  /// rgon-cli error code (see headless/README.md in TeamHY/RepentogonLauncher)
  /// or one of the `cli_*` codes raised by [RepentogonCliService].
  final String code;
  final String? message;

  @override
  String toString() => message == null
      ? 'RgonCliException($code)'
      : 'RgonCliException($code): $message';
}

/// Event written by rgon-cli while a command is running.
sealed class RgonCliEvent {
  const RgonCliEvent();
}

class RgonCliLogEvent extends RgonCliEvent {
  const RgonCliLogEvent(this.level, this.message);

  /// info, warn or error.
  final String level;
  final String message;
}

class RgonCliDownloadEvent extends RgonCliEvent {
  const RgonCliDownloadEvent(this.file, this.bytes);

  final String file;
  final int bytes;
}

/// Final `result` line of a rgon-cli command.
class RgonCliResult {
  const RgonCliResult({
    required this.json,
    required this.exitCode,
  });

  final Map<String, dynamic> json;
  final int exitCode;

  bool get ok => json['ok'] == true;
  String? get error => json['error'] as String?;
  String? get message => json['message'] as String?;

  RgonCliException toException() =>
      RgonCliException(error ?? 'unknown', message);
}

class RgonCliRelease {
  const RgonCliRelease({
    required this.tag,
    required this.zipUrl,
    this.sha256Url,
  });

  final String tag;
  final Uri zipUrl;
  final Uri? sha256Url;

  String get version => tag.substring(RepentogonCliService.tagPrefix.length);
}

/// Downloads, updates and runs rgon-cli, the headless REPENTOGON launcher
/// built from TeamHY/RepentogonLauncher.
class RepentogonCliService {
  static const repository = 'TeamHY/RepentogonLauncher';
  static const repentogonRepository = 'TeamREPENTOGON/REPENTOGON';
  static const tagPrefix = 'cli-v';
  static const zipAssetName = 'rgon-cli.zip';
  static const sha256AssetName = 'rgon-cli.zip.sha256';
  static const executableName = 'rgon-cli.exe';

  static const _launchFlags = {'--luadebug'};
  static const _launchValueOptions = {
    '--luaheapsize',
    '--set-stage',
    '--set-stage-type',
    '--load-room',
  };

  static List<String> launchArgsFromSteamOptions(String options) {
    final tokens = RegExp(r'"([^"]*)"|(\S+)')
        .allMatches(options)
        .map((match) => match.group(1) ?? match.group(2)!)
        .toList();
    final args = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (_launchFlags.contains(token)) {
        args.add(token);
      } else if (_launchValueOptions.contains(token.split('=').first)) {
        if (token.contains('=')) {
          args.add(token);
        } else if (i + 1 < tokens.length && !tokens[i + 1].startsWith('-')) {
          args
            ..add(token)
            ..add(tokens[++i]);
        }
      }
    }

    return args;
  }

  static const _releaseFileName = '.cartridge-release';
  static const _githubHeaders = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'Cartridge',
  };
  static const _requestTimeout = Duration(seconds: 15);
  static const _downloadTimeout = Duration(minutes: 5);

  /// Serializes installs/updates of rgon-cli itself.
  static Future<void>? _installing;

  static Future<Directory> installDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory(p.join(supportDir.path, 'rgon-cli'));
  }

  static Future<File> _executable() async {
    final dir = await installDirectory();
    return File(p.join(dir.path, executableName));
  }

  /// Release tag of the installed rgon-cli, or null if it is not installed.
  static Future<String?> installedTag() async {
    final dir = await installDirectory();
    final exe = File(p.join(dir.path, executableName));
    final releaseFile = File(p.join(dir.path, _releaseFileName));

    if (!await exe.exists() || !await releaseFile.exists()) {
      return null;
    }

    final tag = (await releaseFile.readAsString()).trim();
    return tag.isEmpty ? null : tag;
  }

  /// Latest published rgon-cli release, or null if none exists.
  static Future<RgonCliRelease?> fetchLatestRelease() async {
    final response = await http
        .get(
          Uri.https('api.github.com', '/repos/$repository/releases',
              {'per_page': '30'}),
          headers: _githubHeaders,
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw RgonCliException(
          'cli_download_failed', 'GitHub API returned ${response.statusCode}');
    }

    final releases = jsonDecode(response.body) as List<dynamic>;
    for (final release in releases.cast<Map<String, dynamic>>()) {
      final tag = release['tag_name'] as String? ?? '';
      if (release['draft'] == true ||
          release['prerelease'] == true ||
          !tag.startsWith(tagPrefix)) {
        continue;
      }

      Uri? zipUrl;
      Uri? sha256Url;
      for (final asset in (release['assets'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()) {
        final url = asset['browser_download_url'] as String?;
        if (url == null) continue;

        if (asset['name'] == zipAssetName) {
          zipUrl = Uri.parse(url);
        } else if (asset['name'] == sha256AssetName) {
          sha256Url = Uri.parse(url);
        }
      }

      if (zipUrl != null) {
        return RgonCliRelease(tag: tag, zipUrl: zipUrl, sha256Url: sha256Url);
      }
    }

    return null;
  }

  /// Name of the latest stable REPENTOGON release.
  static Future<String> fetchLatestRepentogonVersion() async {
    final response = await http
        .get(
          Uri.https(
              'api.github.com', '/repos/$repentogonRepository/releases/latest'),
          headers: _githubHeaders,
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw RgonCliException(
          'check_updates_failed', 'GitHub API returned ${response.statusCode}');
    }

    return (jsonDecode(response.body) as Map<String, dynamic>)['name']
        as String;
  }

  /// Make sure rgon-cli is installed.
  ///
  /// With [checkUpdate], the latest release is installed when it differs from
  /// the installed one. A failed update check is ignored when a working copy
  /// is already installed. Returns the installed release tag.
  static Future<String> ensureInstalled({bool checkUpdate = true}) async {
    while (_installing != null) {
      await _installing;
    }

    final completer = Completer<void>();
    _installing = completer.future;

    try {
      final current = await installedTag();
      if (current != null && !checkUpdate) {
        return current;
      }

      final RgonCliRelease? latest;
      try {
        latest = await fetchLatestRelease();
      } catch (e) {
        if (current != null) return current;
        if (e is RgonCliException) rethrow;
        throw RgonCliException('cli_download_failed', e.toString());
      }

      if (latest == null) {
        if (current != null) return current;
        throw const RgonCliException('cli_release_not_found');
      }

      if (latest.tag == current) {
        return current!;
      }

      await _install(latest);
      return latest.tag;
    } finally {
      _installing = null;
      completer.complete();
    }
  }

  static Future<void> _install(RgonCliRelease release) async {
    final dir = await installDirectory();
    final staging = Directory('${dir.path}.download');

    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    await staging.create(recursive: true);

    try {
      final zipResponse =
          await http.get(release.zipUrl).timeout(_downloadTimeout);
      if (zipResponse.statusCode != 200) {
        throw RgonCliException('cli_download_failed',
            '$zipAssetName returned ${zipResponse.statusCode}');
      }
      final bytes = zipResponse.bodyBytes;

      if (release.sha256Url != null) {
        final hashResponse =
            await http.get(release.sha256Url!).timeout(_requestTimeout);
        if (hashResponse.statusCode != 200) {
          throw RgonCliException('cli_download_failed',
              '$sha256AssetName returned ${hashResponse.statusCode}');
        }

        final expected = hashResponse.body.trim().split(RegExp(r'\s+')).first;
        final actual = sha256.convert(bytes).toString();
        if (expected.toLowerCase() != actual) {
          throw const RgonCliException('cli_hash_mismatch');
        }
      }

      final archive = ZipDecoder().decodeBytes(bytes);
      final root = p.normalize(staging.absolute.path);
      for (final entry in archive) {
        if (!entry.isFile) continue;

        final target = p.normalize(p.join(root, entry.name));
        // Reject entries that would escape the target folder.
        if (!p.isWithin(root, target)) {
          throw RgonCliException('cli_invalid_archive', entry.name);
        }

        final file = File(target);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content);
      }

      if (!await File(p.join(staging.path, executableName)).exists()) {
        throw const RgonCliException(
            'cli_invalid_archive', '$executableName missing');
      }

      await File(p.join(staging.path, _releaseFileName))
          .writeAsString(release.tag);

      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException catch (e) {
          throw RgonCliException('cli_in_use', e.message);
        }
      }

      await staging.rename(dir.path);
    } catch (_) {
      if (await staging.exists()) {
        await staging.delete(recursive: true).catchError((_) => staging);
      }
      rethrow;
    }
  }

  /// Run a rgon-cli command and return its result line.
  static Future<RgonCliResult> run(
    List<String> arguments, {
    void Function(RgonCliEvent event)? onEvent,
  }) async {
    final exe = await _executable();
    if (!await exe.exists()) {
      throw const RgonCliException('cli_not_installed');
    }

    return runExecutable(exe.path, arguments, onEvent: onEvent);
  }

  /// Run [executable] and parse its rgon-cli JSON Lines output.
  @visibleForTesting
  static Future<RgonCliResult> runExecutable(
    String executable,
    List<String> arguments, {
    void Function(RgonCliEvent event)? onEvent,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: File(executable).parent.path,
    );

    Map<String, dynamic>? result;
    final stdoutDone = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach((line) {
      if (line.trim().isEmpty) return;

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        onEvent?.call(RgonCliLogEvent('info', line));
        return;
      }

      switch (json['type']) {
        case 'log':
          onEvent?.call(RgonCliLogEvent(
            json['level'] as String? ?? 'info',
            json['message'] as String? ?? '',
          ));
        case 'download':
          onEvent?.call(RgonCliDownloadEvent(
            json['file'] as String? ?? '',
            (json['bytes'] as num?)?.toInt() ?? 0,
          ));
        case 'result':
          result = json;
      }
    });
    final stderrDone = process.stderr.drain<void>();

    final exitCode = await process.exitCode;
    await stdoutDone;
    await stderrDone;

    final finalResult = result;
    if (finalResult == null) {
      throw RgonCliException('cli_no_result', 'exit code $exitCode');
    }

    return RgonCliResult(json: finalResult, exitCode: exitCode);
  }

  /// State of the Isaac / REPENTOGON installations in [isaacPath].
  static Future<RepentogonStatus> status(String isaacPath) async {
    final result = await run(['status', '--isaac', isaacPath]);
    // An invalid game folder still comes with a status payload.
    if (!result.ok && result.error != 'invalid_isaac') {
      throw result.toException();
    }

    return RepentogonStatus.fromJson(result.json);
  }

  /// Install or update REPENTOGON. Use [force] to reinstall (repair).
  static Future<RgonCliResult> install(
    String isaacPath, {
    bool force = false,
    void Function(RgonCliEvent event)? onEvent,
  }) {
    return run([
      'install',
      '--isaac',
      isaacPath,
      if (force) '--force-repentogon-update',
    ], onEvent: onEvent);
  }

  /// Start the game with REPENTOGON. Returns once the game is running.
  static Future<void> launch(String isaacPath,
      {bool console = false, List<String> extraArgs = const []}) async {
    final result = await run([
      'launch',
      '--isaac',
      isaacPath,
      '--launch-mode',
      'repentogon',
      if (console) '--console',
      ...extraArgs,
    ]);

    if (!result.ok) {
      throw result.toException();
    }
  }
}
