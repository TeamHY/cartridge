import 'dart:io';

import 'package:cartridge/services/process_util.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class SteamUser {
  const SteamUser({
    required this.id,
    required this.accountName,
    required this.personaName,
    required this.isMostRecent,
  });

  final String id;
  final String accountName;
  final String personaName;
  final bool isMostRecent;

  String get displayName {
    if (personaName.isNotEmpty) {
      return '$personaName ($id)';
    }
    if (accountName.isNotEmpty) {
      return '$accountName ($id)';
    }
    return id;
  }
}

class SteamSaveService {
  static const _steamRegPathCurrentUser = r'HKCU\Software\Valve\Steam';
  static const _steamRegPathLocalMachine =
      r'HKLM\SOFTWARE\WOW6432Node\Valve\Steam';
  static final BigInt _steamId64Base = BigInt.parse('76561197960265728');

  Future<String?> detectSteamPath({String? isaacPath}) async {
    final fromRegistry = await _readRegistryValue(
      _steamRegPathCurrentUser,
      'SteamPath',
    );
    if (_isSteamPathValid(fromRegistry)) {
      return fromRegistry;
    }

    final fromInstallPath = await _readRegistryValue(
      _steamRegPathLocalMachine,
      'InstallPath',
    );
    if (_isSteamPathValid(fromInstallPath)) {
      return fromInstallPath;
    }

    final fromIsaacPath = _extractSteamPathFromIsaacPath(isaacPath);
    if (_isSteamPathValid(fromIsaacPath)) {
      return fromIsaacPath;
    }

    final programFilesX86 = Platform.environment['ProgramFiles(x86)'];
    final programFiles = Platform.environment['ProgramFiles'];
    final fallbackCandidates = [
      if (programFilesX86 != null) p.join(programFilesX86, 'Steam'),
      if (programFiles != null) p.join(programFiles, 'Steam'),
      r'C:\Program Files (x86)\Steam',
      r'C:\Steam',
    ];

    for (final candidate in fallbackCandidates) {
      if (_isSteamPathValid(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  Future<List<SteamUser>> getLoggedInUsers({required String steamPath}) async {
    final users = await _readLoginUsers(steamPath);
    if (users.isNotEmpty) {
      return users;
    }

    final userdataDir = Directory(p.join(steamPath, 'userdata'));
    if (!await userdataDir.exists()) {
      return const [];
    }

    final fallbackUsers = <SteamUser>[];
    await for (final entity in userdataDir.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }

      final id = p.basename(entity.path);
      if (!RegExp(r'^\d+$').hasMatch(id)) {
        continue;
      }

      fallbackUsers.add(
        SteamUser(
          id: id,
          accountName: '',
          personaName: '',
          isMostRecent: false,
        ),
      );
    }

    fallbackUsers.sort((a, b) => a.id.compareTo(b.id));
    return fallbackUsers;
  }

  Future<void> applyAllCompletionSave({
    required String steamPath,
    required String userId,
    required int slot,
  }) async {
    if (slot < 1 || slot > 3) {
      throw Exception('슬롯은 1~3만 가능합니다.');
    }

    await ProcessUtil.killIsaac();
    await ProcessUtil.killSteam();
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final remoteDir = Directory(
        p.join(steamPath, 'userdata', userId, '250900', 'remote'),
      );
      await remoteDir.create(recursive: true);

      final saveAssets = await _loadSaveAssets();
      if (saveAssets.isEmpty) {
        throw Exception('세이브 파일을 찾을 수 없습니다.');
      }

      for (final asset in saveAssets) {
        final targetName = _buildTargetFileName(asset.name, slot);

        final targetPath = p.join(remoteDir.path, targetName);
        await File(targetPath).writeAsBytes(asset.bytes, flush: true);
      }
    } finally {
      await ProcessUtil.launchSteam(steamPath);
    }
  }

  Future<List<_SaveAsset>> _loadSaveAssets() async {
    final assetNames = [
      'rep_persistentgamedata.dat',
      'rep+persistentgamedata.dat',
    ];

    final assets = <_SaveAsset>[];
    for (final assetName in assetNames) {
      final assetPath = 'assets/saves/$assetName';
      try {
        final data = await rootBundle.load(assetPath);
        assets
            .add(_SaveAsset(name: assetName, bytes: data.buffer.asUint8List()));
      } catch (_) {}
    }

    return assets;
  }

  String _buildTargetFileName(String assetName, int slot) {
    final basename = p.basenameWithoutExtension(assetName);
    final normalizedBase = basename.replaceFirst(RegExp(r'\d+$'), '');
    return '$normalizedBase$slot.dat';
  }

  Future<List<SteamUser>> _readLoginUsers(String steamPath) async {
    final loginUsersFile = File(p.join(steamPath, 'config', 'loginusers.vdf'));
    if (!await loginUsersFile.exists()) {
      return const [];
    }

    final content = await loginUsersFile.readAsString();
    final userBlockPattern = RegExp(
      r'"(\d+)"\s*\{([\s\S]*?)\}',
      multiLine: true,
    );

    final kvPattern = RegExp(r'"([^"]+)"\s+"([^"]*)"');
    final users = <SteamUser>[];

    for (final match in userBlockPattern.allMatches(content)) {
      final steamId = match.group(1) ?? '';
      final body = match.group(2) ?? '';
      if (steamId.isEmpty) {
        continue;
      }

      final folderId = _toUserdataFolderId(steamId) ?? steamId;

      final map = <String, String>{};
      for (final kv in kvPattern.allMatches(body)) {
        final key = kv.group(1) ?? '';
        final value = kv.group(2) ?? '';
        if (key.isEmpty) {
          continue;
        }
        map[key] = value;
      }

      users.add(
        SteamUser(
          id: folderId,
          accountName: map['AccountName'] ?? '',
          personaName: map['PersonaName'] ?? '',
          isMostRecent: map['MostRecent'] == '1',
        ),
      );
    }

    users.sort((a, b) {
      if (a.isMostRecent != b.isMostRecent) {
        return a.isMostRecent ? -1 : 1;
      }
      return a.displayName.compareTo(b.displayName);
    });

    return users;
  }

  String? _toUserdataFolderId(String steamId) {
    try {
      final steamIdValue = BigInt.parse(steamId);
      if (steamIdValue <= _steamId64Base) {
        return null;
      }

      final accountId = steamIdValue - _steamId64Base;
      if (accountId <= BigInt.zero) {
        return null;
      }

      return accountId.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readRegistryValue(String keyPath, String valueName) async {
    if (!Platform.isWindows) {
      return null;
    }

    try {
      final result = await Process.run(
        'reg',
        ['query', keyPath, '/v', valueName],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        return null;
      }

      final output = '${result.stdout}';
      final linePattern = RegExp(
        '${RegExp.escape(valueName)}\\s+REG_\\w+\\s+(.+)',
        caseSensitive: false,
      );
      for (final line in output.split(RegExp(r'\r?\n'))) {
        final match = linePattern.firstMatch(line);
        if (match == null) {
          continue;
        }

        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String? _extractSteamPathFromIsaacPath(String? isaacPath) {
    if (isaacPath == null || isaacPath.isEmpty) {
      return null;
    }

    final normalized = isaacPath.replaceAll('/', '\\').toLowerCase();
    const marker = '\\steamapps\\';
    final idx = normalized.indexOf(marker);
    if (idx <= 0) {
      return null;
    }

    return isaacPath.substring(0, idx);
  }

  bool _isSteamPathValid(String? path) {
    if (path == null || path.isEmpty) {
      return false;
    }

    final steamExe = File(p.join(path, 'steam.exe'));
    final userdata = Directory(p.join(path, 'userdata'));
    return steamExe.existsSync() || userdata.existsSync();
  }
}

class _SaveAsset {
  const _SaveAsset({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}
