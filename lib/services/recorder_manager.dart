import 'dart:io';

import 'package:cartridge/services/recorder_mod.dart';

class RecorderManager {
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
}
