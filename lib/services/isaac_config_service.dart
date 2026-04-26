import 'dart:io';

enum IsaacEdition {
  repentance('Binding of Isaac Repentance'),
  repentancePlus('Binding of Isaac Repentance+');

  final String folderName;
  const IsaacEdition(this.folderName);

  String get documentPath =>
      '${Platform.environment['UserProfile']}\\Documents\\My Games\\$folderName';

  String get optionFilePath => '$documentPath\\options.ini';
}

class IsaacConfigService {
  static String get isaacDocumentPath =>
      IsaacEdition.repentancePlus.documentPath;

  static Future<List<IsaacEdition>> getAvailableEditions() async {
    final editions = <IsaacEdition>[];
    for (final edition in IsaacEdition.values) {
      if (await File(edition.optionFilePath).exists()) {
        editions.add(edition);
      }
    }
    return editions;
  }

  static Future<bool> getOptionBool(
      IsaacEdition edition, String key) async {
    try {
      final file = File(edition.optionFilePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      for (final line in content.split('\n')) {
        if (line.startsWith('$key=')) {
          return line.split('=').last.trim() == '1';
        }
      }
    } catch (e) {
      //
    }
    return false;
  }

  static Future<void> setOptionBool(
      IsaacEdition edition, String key, bool value) async {
    await _updateOptionFile((line) {
      if (line.startsWith('$key=')) {
        return '$key=${value ? 1 : 0}';
      }
      return line;
    }, edition: edition);
  }

  static Future<Map<String, String>> getAllOptions(IsaacEdition edition) async {
    final result = <String, String>{};
    try {
      final file = File(edition.optionFilePath);
      if (!await file.exists()) return result;

      final content = await file.readAsString();
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('[')) continue;
        final idx = trimmed.indexOf('=');
        if (idx > 0) {
          result[trimmed.substring(0, idx)] = trimmed.substring(idx + 1);
        }
      }
    } catch (e) {
      //
    }
    return result;
  }

  static Future<void> setOption(
      IsaacEdition edition, String key, String value) async {
    await _updateOptionFile((line) {
      if (line.startsWith('$key=')) {
        return '$key=$value';
      }
      return line;
    }, edition: edition);
  }

  static Future<void> setEnableMods(bool value) async {
    await _updateOptionFile((line) {
      if (line.startsWith('EnableMods=')) {
        return 'EnableMods=${value ? 1 : 0}';
      }
      return line;
    });
  }

  static Future<void> setDebugConsole(bool value) async {
    await _updateOptionFile((line) {
      if (line.startsWith('EnableDebugConsole=')) {
        return 'EnableDebugConsole=${value ? 1 : 0}';
      }
      return line;
    });
  }

  static Future<void> applyWindowConfig({
    required int windowWidth,
    required int windowHeight,
    required int windowPosX,
    required int windowPosY,
  }) async {
    await _updateOptionFile((line) {
      if (line.startsWith('WindowWidth=')) {
        return 'WindowWidth=$windowWidth';
      } else if (line.startsWith('WindowHeight=')) {
        return 'WindowHeight=$windowHeight';
      } else if (line.startsWith('WindowPosX=')) {
        return 'WindowPosX=$windowPosX';
      } else if (line.startsWith('WindowPosY=')) {
        return 'WindowPosY=$windowPosY';
      }
      return line;
    });
  }

  static Future<void> _updateOptionFile(
    String Function(String) transform, {
    IsaacEdition edition = IsaacEdition.repentancePlus,
  }) async {
    try {
      final optionFile = File(edition.optionFilePath);

      if (!await optionFile.exists()) {
        return;
      }

      final content = await optionFile.readAsString();
      final newContent = content.split('\n').map(transform).join('\n');

      await optionFile.writeAsString(newContent);
    } catch (e) {
      //
    }
  }
}
