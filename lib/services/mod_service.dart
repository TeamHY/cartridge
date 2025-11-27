import 'dart:io';

import 'package:cartridge/models/metadata.dart';
import 'package:cartridge/models/mod.dart';

const astrobirthName = '!Astrobirth';

class ModService {
  static Future<List<Mod>> loadMods(String isaacPath) async {
    final directory = Directory('$isaacPath/mods');
    final mods = <Mod>[];

    if (!await directory.exists()) {
      return mods;
    }

    for (var modDirectory in directory.listSync()) {
      final metadataFile = File('${modDirectory.path}/metadata.xml');

      if (!await metadataFile.exists()) continue;

      final metadata = Metadata.fromString(await metadataFile.readAsString());

      if (metadata.name == "CartridgeSupporter") continue;

      final disableFile = File('${modDirectory.path}/disable.it');
      final isDisable = await disableFile.exists();

      final mod = Mod(
        name: metadata.name ?? '',
        path: modDirectory.path,
        id: metadata.id,
        version: metadata.version,
        isDisable: isDisable,
      );

      mods.add(mod);
    }

    mods.sort((a, b) => a.name.compareTo(b.name));

    return mods;
  }

  static Future<void> applyModStates(List<Mod> mods) async {
    for (var mod in mods) {
      final disableFile = File('${mod.path}/disable.it');

      try {
        if (mod.isDisable) {
          if (!await disableFile.exists()) {
            await disableFile.create();
          }
        } else {
          if (await disableFile.exists()) {
            await disableFile.delete();
          }
        }
      } catch (e) {
        //
      }
    }
  }

  static Future<String?> getAstroLocalVersion(String isaacPath) async {
    final mods = await loadMods(isaacPath);

    final targetMod = mods.firstWhere(
      (mod) => mod.name == astrobirthName,
      orElse: () => Mod.none,
    );

    if (targetMod.name == astrobirthName) {
      return targetMod.version;
    } else {
      return null;
    }
  }

  static Future<String?> getAstroRemoteVersion() async {
    return null;
  }
}
