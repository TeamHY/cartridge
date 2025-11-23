import 'dart:io';

class IsaacConfigService {
  static String get isaacDocumentPath =>
      '${Platform.environment['UserProfile']}\\Documents\\My Games\\Binding of Isaac Repentance+';

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
      String Function(String) transform) async {
    try {
      final optionFile = File('${isaacDocumentPath}\\options.ini');

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
