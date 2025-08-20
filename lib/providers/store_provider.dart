import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/utils/presets_parser.dart';
import 'package:cartridge/utils/process_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/metadata.dart';

const astrobirthName = '!Astrobirth';

final isaacDocumentPath =
    '${Platform.environment['UserProfile']}\\Documents\\My Games\\Binding of Isaac Repentance+';

Future<void> setEnableMods(bool value) async {
  try {
    final optionFile = File('$isaacDocumentPath\\options.ini');

    if (!await optionFile.exists()) {
      return;
    }

    final content = await optionFile.readAsString();

    final newContent = content.split('\n').map((line) {
      if (line.startsWith('EnableMods=')) {
        return 'EnableMods=${value ? 1 : 0}';
      }
      return line;
    }).join('\n');

    await optionFile.writeAsString(newContent);
  } catch (e) {
  }
}

Future<void> setDebugConsole(bool value) async {
  try {
    final optionFile = File('$isaacDocumentPath\\options.ini');

    if (!await optionFile.exists()) {
      return;
    }

    final content = await optionFile.readAsString();

    final newContent = content.split('\n').map((line) {
      if (line.startsWith('EnableDebugConsole=')) {
        return 'EnableDebugConsole=${value ? 1 : 0}';
      }
      return line;
    }).join('\n');

    await optionFile.writeAsString(newContent);
  } catch (e) {
    //
  }
}

class StoreNotifier extends ChangeNotifier {
  StoreNotifier(this.ref) {
    reloadMods();
    loadPresets();
    checkAstroVersion();
  }

  final Ref ref;

  PresetsDataV3? _presetsData;

  List<Preset> get presets => _presetsData?.presets ?? [];

  List<GameConfig> get gameConfigs =>  _presetsData?.gameConfigs ?? [];

  Map<String, Set<String>> get groups =>  _presetsData?.groups ?? {};

  List<Mod> currentMods = [];

  bool isSync = false;
  bool isRerun = true;

  String? astroLocalVersion;
  String? astroRemoteVersion;

  String? selectedGameConfigId;

  get isAstroOutdated =>
      astroLocalVersion != astroRemoteVersion ||
      astroLocalVersion == null ||
      astroRemoteVersion == null;

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<Mod>> loadMods() async {
    final setting = ref.read(settingProvider);
    await setting.loadSetting();

    final path = setting.isaacPath;
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
    // final response = await http.get(Uri.https('tgd.kr', "s/iwt2hw/72435841"));

    // if (response.statusCode != 200) {
    //   return null;
    // }

    // final document = parse(response.body);

    // return document.querySelector("#article-content > p")?.innerHtml;

    return null;
  }

  void checkAstroVersion() async {
    astroLocalVersion = await getAstroLocalVersion();
    astroRemoteVersion = await getAstroRemoteVersion();

    notifyListeners();
  }

  Future<void> applyGameConfig(String id) async {
    try {
      final gameConfig =
          gameConfigs.firstWhere((element) => element.id == id);

      final optionFile = File('$isaacDocumentPath\\options.ini');

      if (!await optionFile.exists()) {
        return;
      }

      final content = await optionFile.readAsString();

      final newContent = content.split('\n').map((line) {
        if (line.startsWith('WindowWidth=')) {
          return 'WindowWidth=${gameConfig.windowWidth}';
        } else if (line.startsWith('WindowHeight=')) {
          return 'WindowHeight=${gameConfig.windowHeight}';
        } else if (line.startsWith('WindowPosX=')) {
          return 'WindowPosX=${gameConfig.windowPosX}';
        } else if (line.startsWith('WindowPosY=')) {
          return 'WindowPosY=${gameConfig.windowPosY}';
        } else {
          return line;
        }
      }).join('\n');

      await optionFile.writeAsString(newContent);
    } catch (e) {
      //
    }
  }

  Future<void> applyPreset(
    Preset? preset, {
    bool isForceRerun = false,
    bool isForceUpdate = false,
    bool isEnableMods = true,
    bool isDebugConsole = true,
    bool isNoDelay = false,
  }) async {
    final currentMods = await loadMods();

    if (preset != null) {
      for (var mod in currentMods) {
        final isDisable = preset.mods
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
    }

    reloadMods();

    if (isRerun || isForceRerun) {
      await ProcessUtil.killIsaac();

      if (isForceUpdate) {
        await ProcessUtil.killSteam();
      }

      if (!isNoDelay) {
        await Future.delayed(Duration(
          milliseconds: ref.read(settingProvider).rerunDelay,
        ));
      }
    }

    if (preset?.gameConfigId != null) {
      await applyGameConfig(preset!.gameConfigId!);
    }

    await setEnableMods(isEnableMods);
    await setDebugConsole(isDebugConsole);

    if (isRerun || isForceRerun) {
      await Process.run(
          '${ref.read(settingProvider).isaacPath}/isaac-ng.exe', []);
    }
  }

  void updateGameConfig(GameConfig gameConfig) {
    final index =
        gameConfigs.indexWhere((element) => element.id == gameConfig.id);

    if (index == -1) {
      gameConfigs.add(gameConfig);
    } else {
      gameConfigs[index] = gameConfig;
    }

    savePresets();
    notifyListeners();
  }

  void removeGameConfig(String id) {
    gameConfigs.removeWhere((element) => element.id == id);

    if (selectedGameConfigId == id) {
      selectedGameConfigId = null;
    }

    savePresets();
    notifyListeners();
  }

  void selectGameConfig(String? id) {
    selectedGameConfigId = id;

    notifyListeners();
  }

  void loadPresets() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/presets.json');

    print(appSupportDir);

    if (!(await file.exists())) {
      return;
    }

    _presetsData = await PresetsParser.parseFromFile(file);

    notifyListeners();
  }

  void savePresets() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/presets.json');

    file.writeAsString(jsonEncode(_presetsData?.toJson()));
  }

  void addGroup(String groupName) {
    if (_presetsData == null) {
      _presetsData = PresetsDataV3(
        presets: [],
        gameConfigs: [],
        groups: {},
      );
    }
    
    if (!_presetsData!.groups.containsKey(groupName)) {
      _presetsData!.groups[groupName] = <String>{};
      savePresets();
      notifyListeners();
    }
  }

  void removeGroup(String groupName) {
    if (_presetsData != null && _presetsData!.groups.containsKey(groupName)) {
      _presetsData!.groups.remove(groupName);
      savePresets();
      notifyListeners();
    }
  }

  void renameGroup(String oldName, String newName) {
    if (_presetsData != null && 
        _presetsData!.groups.containsKey(oldName) && 
        !_presetsData!.groups.containsKey(newName)) {
      final modNames = _presetsData!.groups[oldName]!;
      _presetsData!.groups.remove(oldName);
      _presetsData!.groups[newName] = modNames;
      savePresets();
      notifyListeners();
    }
  }

  void addModToGroup(String groupName, String modName) {
    if (_presetsData != null && _presetsData!.groups.containsKey(groupName)) {
      _presetsData!.groups[groupName]!.add(modName);
      savePresets();
      notifyListeners();
    }
  }

  void removeModFromGroup(String groupName, String modName) {
    if (_presetsData != null && _presetsData!.groups.containsKey(groupName)) {
      _presetsData!.groups[groupName]!.remove(modName);
      savePresets();
      notifyListeners();
    }
  }

  void moveModToGroup(String modName, String? fromGroup, String? toGroup) {
    if (_presetsData == null) return;

    if (fromGroup != null && _presetsData!.groups.containsKey(fromGroup)) {
      _presetsData!.groups[fromGroup]!.remove(modName);
    }

    if (toGroup != null && _presetsData!.groups.containsKey(toGroup)) {
      _presetsData!.groups[toGroup]!.add(modName);
    }

    savePresets();
    notifyListeners();
  }

  String? getModGroup(String modName) {
    if (_presetsData == null) return null;
    
    for (var entry in _presetsData!.groups.entries) {
      if (entry.value.contains(modName)) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> saveMods(List<Mod> mods) async {
    final currentMods = await loadMods();

    for (var mod in currentMods) {
      final targetMod = mods.firstWhere(
        (element) => element.name == mod.name,
        orElse: () => Mod(
          name: "Null",
          path: "Null",
          isDisable: true,
        ),
      );

      try {
        if (targetMod.isDisable) {
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
  }
}

final storeProvider = ChangeNotifierProvider<StoreNotifier>((ref) {
  return StoreNotifier(ref);
});
