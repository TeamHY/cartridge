import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/option_preset.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/metadata.dart';

const astrobirthName = '!Astrobirth';

class StoreNotifier extends ChangeNotifier {
  StoreNotifier(this.ref) {
    reloadMods();
    loadPresets();
    checkAstroVersion();
  }

  final Ref ref;

  List<Preset> presets = [];

  List<OptionPreset> optionPresets = [];

  List<String> favorites = [];

  List<Mod> currentMods = [];

  bool isSync = false;
  bool isRerun = true;

  String? astroLocalVersion;
  String? astroRemoteVersion;

  String? selectOptionPresetId;

  get isAstroOutdated =>
      astroLocalVersion != astroRemoteVersion ||
      astroLocalVersion == null ||
      astroRemoteVersion == null;

  Future<List<Mod>> loadMods() async {
    final path = ref.read(settingProvider).isaacPath;
    final directory = Directory('$path/mods');

    final mods = <Mod>[];

    if (!await directory.exists()) {
      return mods;
    }

    for (var modDirectory in directory.listSync()) {
      final metadataFile = File('${modDirectory.path}/metadata.xml');

      if (await metadataFile.exists()) {
        final metadata = Metadata.fromString(await metadataFile.readAsString());

        final disableFile = File('${modDirectory.path}/disable.it');

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

  void reloadMods() async {
    currentMods = await loadMods();
    isSync = true;

    notifyListeners();
  }

  Future<String?> getAstroLocalVersion() async {
    final mods = await loadMods();

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
    final response = await http.get(Uri.https('tgd.kr', "s/iwt2hw/72435841"));

    if (response.statusCode != 200) {
      return null;
    }

    final document = parse(response.body);

    return document.querySelector("#article-content > p")?.innerHtml;
  }

  void checkAstroVersion() async {
    astroLocalVersion = await getAstroLocalVersion();
    astroRemoteVersion = await getAstroRemoteVersion();

    notifyListeners();
  }

  void applyOptionPreset(String id) async {
    try {
      final optionPreset =
          optionPresets.firstWhere((element) => element.id == id);

      final optionFile = File(
          '${Platform.environment['UserProfile']}\\Documents\\My Games\\Binding of Isaac Repentance\\options.ini');

      if (!await optionFile.exists()) {
        return;
      }

      final content = await optionFile.readAsString();

      final newContent = content.split('\n').map((line) {
        if (line.startsWith('WindowWidth=')) {
          return 'WindowWidth=${optionPreset.windowWidth}';
        } else if (line.startsWith('WindowHeight=')) {
          return 'WindowHeight=${optionPreset.windowHeight}';
        } else if (line.startsWith('WindowPosX=')) {
          return 'WindowPosX=${optionPreset.windowPosX}';
        } else if (line.startsWith('WindowPosY=')) {
          return 'WindowPosY=${optionPreset.windowPosY}';
        } else {
          return line;
        }
      }).join('\n');

      await optionFile.writeAsString(newContent);
    } catch (e) {
      //
    }
  }

  void applyMods(
    List<Mod> mods, {
    bool isForceRerun = false,
    bool isForceUpdate = false,
  }) async {
    final currentMods = await loadMods();

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
          final disableFile = File('${mod.path}/disable.it');

          disableFile.createSync();
        } else {
          final disableFile = File('${mod.path}/disable.it');

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

      await Process.run(
          '${ref.read(settingProvider).isaacPath}/isaac-ng.exe', []);
    }
  }

  void updateOptionPreset(OptionPreset optionPreset) {
    final index =
        optionPresets.indexWhere((element) => element.id == optionPreset.id);

    if (index == -1) {
      optionPresets.add(optionPreset);
    } else {
      optionPresets[index] = optionPreset;
    }

    savePresets();
    notifyListeners();
  }

  void removeOptionPreset(String id) {
    optionPresets.removeWhere((element) => element.id == id);

    if (selectOptionPresetId == id) {
      selectOptionPresetId = null;
    }

    savePresets();
    notifyListeners();
  }

  void selectOptionPreset(String? id) {
    selectOptionPresetId = id;

    notifyListeners();
  }

  void addFavorite(String name) {
    favorites.add(name);

    savePresets();
    notifyListeners();
  }

  void removeFavorite(String name) {
    favorites.remove(name);

    savePresets();
    notifyListeners();
  }

  void loadOldPreset() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final file = File('${appDocumentsDir.path}/presets.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as List<dynamic>;

    presets = json.map((e) => Preset.fromJson(e)).toList();

    notifyListeners();
  }

  void loadPresets() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/presets.json');

    if (!(await file.exists())) {
      return loadOldPreset();
    }

    final json = jsonDecode(await file.readAsString());

    if (json['version'] == 2) {
      presets = (json['presets'] as List<dynamic>)
          .map((e) => Preset.fromJson(e))
          .toList();

      optionPresets = (json['optionPresets'] as List<dynamic>)
          .map((e) => OptionPreset.fromJson(e))
          .toList();

      favorites = ((json['favorites'] as List<dynamic>?) ?? []).cast<String>();
    } else {
      return;
    }

    notifyListeners();
  }

  void savePresets() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/presets.json');

    file.writeAsString(jsonEncode({
      'version': 2,
      'presets': presets,
      'optionPresets': optionPresets,
      'favorites': favorites,
    }));
  }
}

final storeProvider = ChangeNotifierProvider<StoreNotifier>((ref) {
  return StoreNotifier(ref);
});
