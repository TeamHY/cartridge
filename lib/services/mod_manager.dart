import 'dart:io';

import 'package:cartridge/services/recorder_mod.dart';

class ModManager {
  static Future<void> createRecorderMod({
    required String isaacPath,
    required String dailySeed,
    required String dailyBoss,
    required int dailyCharacter,
    required String weeklySeed,
    required String weeklyBoss,
    required int weeklyCharacter,
  }) async {
    final recorderDirectory = Directory('$isaacPath\\mods\\cartridge-recorder');

    if (await recorderDirectory.exists()) {
      await recorderDirectory.delete(recursive: true);
    }

    await recorderDirectory.create();

    final mainFile = File("${recorderDirectory.path}\\main.lua");
    await mainFile.create();
    await mainFile.writeAsString(
      await RecorderMod.getModMain(
        dailySeed,
        dailyBoss,
        dailyCharacter,
        weeklySeed,
        weeklyBoss,
        weeklyCharacter,
      ),
    );

    final metadataFile = File("${recorderDirectory.path}\\metadata.xml");
    await metadataFile.create();
    await metadataFile.writeAsString(RecorderMod.modMetadata);
  }

  static Future<void> deleteRecorderMod(String isaacPath) async {
    final recorderDirectory = Directory('$isaacPath\\mods\\cartridge-recorder');

    if (await recorderDirectory.exists()) {
      await recorderDirectory.delete(recursive: true);
    }
  }

  static Future<void> createMod({
    required String isaacPath,
    required String modName,
    required Map<String, String> files,
  }) async {
    final modDirectory = Directory('$isaacPath\\mods\\$modName');

    if (await modDirectory.exists()) {
      await modDirectory.delete(recursive: true);
    }

    await modDirectory.create(recursive: true);

    for (final entry in files.entries) {
      final file = File('${modDirectory.path}\\${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }
  }

  static Future<void> deleteMod({
    required String isaacPath,
    required String modName,
  }) async {
    final modDirectory = Directory('$isaacPath\\mods\\$modName');

    if (await modDirectory.exists()) {
      await modDirectory.delete(recursive: true);
    }
  }
}
