import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/metadata.dart';

Future<List<Mod>> loadMods(String path) async {
  final mods = <Mod>[];

  final directory = Directory('$path\\mods');

  if (!await directory.exists()) {
    return mods;
  }

  for (var modDirectory in directory.listSync()) {
    final metadataFile = File('${modDirectory.path}\\metadata.xml');

    if (await metadataFile.exists()) {
      final metadata = Metadata.fromString(await metadataFile.readAsString());

      final disableFile = File('${modDirectory.path}\\disable.it');

      final isDisable = await disableFile.exists();

      final mod = Mod(
        name: metadata.name ?? '',
        path: modDirectory.path,
        version: metadata.version,
        isDisable: isDisable,
      );

      mods.add(mod);
    }
  }

  mods.sort((a, b) => a.name.compareTo(b.name));

  return mods;
}

const astrobirthName = '!Redrawn_Hard';

class StoreNotifier extends ChangeNotifier {
  StoreNotifier(this.ref) {
    reloadMods();
    loadPresets();
  }

  final Ref ref;

  List<Preset> presets = [];

  List<Mod> currentMods = [];

  bool isSync = false;
  bool isRerun = true;

  String? astroLocalVersion;
  String? astroRemoteVersion;

  get isAstroOutdated =>
      astroLocalVersion != astroRemoteVersion ||
      astroLocalVersion == null ||
      astroRemoteVersion == null;

  void reloadMods() async {
    final path = ref.read(settingProvider).isaacPath;

    currentMods = await loadMods(path);
    isSync = true;

    notifyListeners();
  }

  Future<String?> getAstroLocalVersion() async {
    final path = ref.read(settingProvider).isaacPath;

    final mods = await loadMods(path);

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

  Future<String?> getAstroRemoteVersion() async {
    final response = await http.get(Uri.https(
      'raw.githubusercontent.com',
      'TeamHY/Astrobirth/main/metadata.xml',
    ));

    if (response.statusCode != 200) {
      return null;
    }

    final remoteMetadata = Metadata.fromString(response.body);

    return remoteMetadata.version;
  }

  void checkAstroVersion() async {
    astroLocalVersion = await getAstroLocalVersion();
    astroRemoteVersion = await getAstroRemoteVersion();

    notifyListeners();
  }

  void applyMods(
    List<Mod> mods, {
    bool isForceRerun = false,
    bool isForceUpdate = false,
  }) async {
    final path = ref.read(settingProvider).isaacPath;

    final currentMods = await loadMods(path);

    for (var mod in currentMods) {
      final isDisable = mods
          .firstWhere(
            (element) => element.name == mod.name,
            orElse: () => Mod(
              name: "Null",
              path: "Null",
              isDisable: true,
            ),
          )
          .isDisable;

      try {
        if (isDisable) {
          final disableFile = File('${mod.path}\\disable.it');

          disableFile.createSync();
        } else {
          final disableFile = File('${mod.path}\\disable.it');

          disableFile.deleteSync();
        }
      } catch (e) {
        //
      }
    }

    reloadMods();

    if (isRerun || isForceRerun) {
      await Process.run('taskkill', ['/im', 'isaac-ng.exe']);

      if (isForceUpdate) {
        await Process.run('taskkill', ['/f', '/im', 'steam.exe']);
      }

      await Process.run('$path\\isaac-ng.exe', []);
    }
  }

  void loadPresets() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final file = File('${appDocumentsDir.path}\\presets.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as List<dynamic>;

    presets = json.map((e) => Preset.fromJson(e)).toList();

    notifyListeners();
  }

  void savePresets() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final file = File('${appDocumentsDir.path}\\presets.json');

    file.writeAsString(jsonEncode(presets));
  }
}

final storeProvider = ChangeNotifierProvider<StoreNotifier>((ref) {
  return StoreNotifier(ref);
});
