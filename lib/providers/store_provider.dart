import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/services/isaac_config_service.dart';
import 'package:cartridge/services/mod_manager.dart';
import 'package:cartridge/services/mod_names.dart';
import 'package:cartridge/services/mod_service.dart'
    hide cartridgeSupporterName;
import 'package:cartridge/services/preset_service.dart';
import 'package:cartridge/services/game_launcher_service.dart';
import 'package:cartridge/utils/presets_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StoreNotifier extends ChangeNotifier {
  StoreNotifier(this.ref) {
    createSupporterMod();
    reloadMods();
    loadPresets();
    checkAstroVersion();
  }

  final Ref ref;

  PresetsDataV3 _presetsData = PresetsDataV3(
    presets: [],
    gameConfigs: [],
    groups: {},
  );

  List<Preset> get presets => _presetsData.presets;
  List<GameConfig> get gameConfigs => _presetsData.gameConfigs;
  Map<String, Set<String>> get groups => _presetsData.groups;

  List<Mod> currentMods = [];

  bool isSync = false;
  bool isRerun = true;

  String? astroLocalVersion;
  String? astroRemoteVersion;

  String? selectedGameConfigId;

  bool get isAstroOutdated =>
      astroLocalVersion != astroRemoteVersion ||
      astroLocalVersion == null ||
      astroRemoteVersion == null;

  Future<void> createSupporterMod() async {
    final setting = ref.read(settingProvider);

    await ModManager.deleteMod(
      isaacPath: setting.isaacPath,
      modName: cartridgeSupporterName,
    );

    await ModManager.createMod(
      isaacPath: setting.isaacPath,
      modName: cartridgeSupporterName,
      files: {
        'main.lua': await rootBundle
            .loadString('assets/mods/cartridge_supporter/main.lua'),
        'metadata.xml': await rootBundle
            .loadString('assets/mods/cartridge_supporter/metadata.xml'),
      },
    );
  }

  Future<void> reloadMods() async {
    final setting = ref.read(settingProvider);
    await setting.loadSetting();

    currentMods = await ModService.loadMods(setting.isaacPath);
    isSync = true;

    notifyListeners();
  }

  Future<void> checkAstroVersion() async {
    final setting = ref.read(settingProvider);
    await setting.loadSetting();

    astroLocalVersion =
        await ModService.getAstroLocalVersion(setting.isaacPath);
    astroRemoteVersion = await ModService.getAstroRemoteVersion();

    notifyListeners();
  }

  Future<void> _applyGameConfig(String id) async {
    try {
      final gameConfig = gameConfigs.firstWhere((element) => element.id == id);

      await IsaacConfigService.applyWindowConfig(
        windowWidth: gameConfig.windowWidth,
        windowHeight: gameConfig.windowHeight,
        windowPosX: gameConfig.windowPosX,
        windowPosY: gameConfig.windowPosY,
      );
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
    final setting = ref.read(settingProvider);
    await setting.loadSetting();

    if (preset != null) {
      final loadedMods = await ModService.loadMods(setting.isaacPath);
      final modsToApply = loadedMods.map((mod) {
        final presetMod = preset.mods.firstWhere(
          (element) => element.name == mod.name,
          orElse: () => Mod(name: "Null", path: "Null", isDisable: true),
        );
        mod.isDisable = presetMod.isDisable;
        return mod;
      }).toList();

      await ModService.applyModStates(modsToApply);
    }

    await reloadMods();

    if (preset?.gameConfigId != null) {
      await _applyGameConfig(preset!.gameConfigId!);
    }

    await IsaacConfigService.setEnableMods(isEnableMods);
    await IsaacConfigService.setDebugConsole(isDebugConsole);

    if (isRerun || isForceRerun) {
      await GameLauncherService.launchGame(
        isaacPath: setting.isaacPath,
        rerunDelay: setting.rerunDelay,
        isForceUpdate: isForceUpdate,
        isNoDelay: isNoDelay,
      );
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

  Future<void> loadPresets() async {
    _presetsData = await PresetService.loadPresets();
    notifyListeners();
  }

  // TODO: Private로 변경해야 함
  Future<void> savePresets() async {
    await PresetService.savePresets(_presetsData);
  }

  void addPreset(Preset preset) {
    _presetsData.presets.add(preset);
    savePresets();
    notifyListeners();
  }

  void movePreset(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _presetsData.presets.removeAt(oldIndex);
    _presetsData.presets.insert(newIndex, item);
    savePresets();
    notifyListeners();
  }

  void removePreset(Preset preset) {
    _presetsData.presets.remove(preset);
    savePresets();
    notifyListeners();
  }

  void addGroup(String groupName) {
    if (!_presetsData.groups.containsKey(groupName)) {
      _presetsData.groups[groupName] = <String>{};
      savePresets();
      notifyListeners();
    }
  }

  void removeGroup(String groupName) {
    if (_presetsData.groups.containsKey(groupName)) {
      _presetsData.groups.remove(groupName);
      savePresets();
      notifyListeners();
    }
  }

  void renameGroup(String oldName, String newName) {
    if (_presetsData.groups.containsKey(oldName) &&
        !_presetsData.groups.containsKey(newName)) {
      final modNames = _presetsData.groups[oldName]!;
      _presetsData.groups.remove(oldName);
      _presetsData.groups[newName] = modNames;
      savePresets();
      notifyListeners();
    }
  }

  void addModToGroup(String groupName, String modName) {
    if (_presetsData.groups.containsKey(groupName)) {
      _presetsData.groups[groupName]!.add(modName);
      savePresets();
      notifyListeners();
    }
  }

  void removeModFromGroup(String groupName, String modName) {
    if (_presetsData.groups.containsKey(groupName)) {
      _presetsData.groups[groupName]!.remove(modName);
      savePresets();
      notifyListeners();
    }
  }

  void moveModToGroup(String modName, String? fromGroup, String? toGroup) {
    if (fromGroup != null && _presetsData.groups.containsKey(fromGroup)) {
      _presetsData.groups[fromGroup]!.remove(modName);
    }

    if (toGroup != null && _presetsData.groups.containsKey(toGroup)) {
      _presetsData.groups[toGroup]!.add(modName);
    }

    savePresets();
    notifyListeners();
  }

  String? getModGroup(String modName) {
    for (var entry in _presetsData.groups.entries) {
      if (entry.value.contains(modName)) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> saveMods(List<Mod> mods) async {
    await ModService.applyModStates(mods);
    await reloadMods();
  }
}

final storeProvider = ChangeNotifierProvider<StoreNotifier>((ref) {
  return StoreNotifier(ref);
});
