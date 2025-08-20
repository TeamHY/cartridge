import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/models/preset.dart';

class PresetsParser {
  static const int targetVersion = 3;

  static Future<PresetsDataV3?> parseFromFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);

      return _parseJson(json);
    } catch (e) {
      return null;
    }
  }

  static PresetsDataV3 _parseJson(Map<String, dynamic> json) {
    final version = _getVersion(json);
    return _migrateToLatestVersion(_createDataFromJson(json, version));
  }

  static PresetsDataV3 _migrateToLatestVersion(PresetsData data) {
    if (data.version == targetVersion) {
      return data as PresetsDataV3;
    }

    if (data.version > targetVersion) {
      throw Exception('Unsupported version: ${data.version}');
    }

    final nextVersionData = data.migrateToNext();

    return _migrateToLatestVersion(nextVersionData);
  }

  static PresetsData _createDataFromJson(
      Map<String, dynamic> json, int version) {
    switch (version) {
      case 1:
        return PresetsDataV1.fromJson(json);
      case 2:
        return PresetsDataV2.fromJson(json);
      case 3:
        return PresetsDataV3.fromJson(json);
      default:
        throw Exception('Unsupported version: $version');
    }
  }

  static int _getVersion(Map<String, dynamic> json) {
    return json['version'] as int? ?? 1;
  }
}

abstract class PresetsData {
  int get version;

  PresetsData migrateToNext();
}

class PresetsDataV1 extends PresetsData {
  @override
  int get version => 1;

  @override
  final List<dynamic> presets;

  PresetsDataV1({
    required this.presets,
  });

  factory PresetsDataV1.fromJson(dynamic json) {
    List<Preset> presets = [];

    if (json is List<dynamic>) {
      presets = json.map((e) => Preset.fromJson(e)).toList();
    }

    return PresetsDataV1(presets: presets);
  }

  PresetsDataV1 copyWith({
    List<dynamic>? presets,
  }) {
    return PresetsDataV1(
      presets: presets ?? this.presets,
    );
  }

  @override
  PresetsData migrateToNext() {
    return PresetsDataV2(
      presets: presets,
      optionPresets: [],
      favorites: [],
    );
  }
}

class PresetsDataV2 extends PresetsData {
  @override
  int get version => 2;

  @override
  final List<dynamic> presets;

  @override
  final List<dynamic> optionPresets;

  @override
  final List<String> favorites;

  PresetsDataV2({
    required this.presets,
    required this.optionPresets,
    required this.favorites,
  });

  factory PresetsDataV2.fromJson(Map<String, dynamic> json) {
    final presets = (json['presets'] as List<dynamic>?) ?? [];

    final optionPresets = (json['optionPresets'] as List<dynamic>?) ?? [];

    final favorites =
        ((json['favorites'] as List<dynamic>?) ?? []).cast<String>();

    return PresetsDataV2(
      presets: presets,
      optionPresets: [...optionPresets],
      favorites: favorites,
    );
  }

  PresetsDataV2 copyWith({
    List<dynamic>? presets,
    List<dynamic>? optionPresets,
    List<String>? favorites,
  }) {
    return PresetsDataV2(
      presets: presets ?? this.presets,
      optionPresets: optionPresets ?? this.optionPresets,
      favorites: favorites ?? this.favorites,
    );
  }

  @override
  PresetsData migrateToNext() {
    final presets = this.presets.map((e) => Preset.fromJson(e)).toList();

    final gameConfigs =
        optionPresets.map((e) => GameConfig.fromJson(e)).toList();

    final groups = <String, Set<String>>{
      '즐겨찾기': favorites.toSet(),
    };

    return PresetsDataV3(
      presets: presets,
      gameConfigs: gameConfigs,
      groups: groups,
    );
  }
}

class PresetsDataV3 extends PresetsData {
  @override
  int get version => 3;

  @override
  final List<Preset> presets;

  @override
  final List<GameConfig> gameConfigs;

  @override
  final Map<String, Set<String>> groups;

  PresetsDataV3({
    required this.presets,
    required this.gameConfigs,
    required this.groups,
  });

  factory PresetsDataV3.fromJson(Map<String, dynamic> json) {
    final presets = (json['presets'] as List<dynamic>?)
            ?.map((e) => Preset.fromJson(e))
            .toList() ??
        [];

    final gameConfigs = (json['gameConfigs'] as List<dynamic>?)
            ?.map((e) => GameConfig.fromJson(e))
            .toList() ??
        [];

    final groups =
        (json['groups'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(
                  key,
                  (value as List<dynamic>).cast<String>().toSet(),
                )) ??
            {};

    return PresetsDataV3(
      presets: presets,
      gameConfigs: gameConfigs,
      groups: groups,
    );
  }

  PresetsDataV3 copyWith({
    List<Preset>? presets,
    List<GameConfig>? gameConfigs,
    Map<String, Set<String>>? groups,
  }) {
    return PresetsDataV3(
      presets: presets ?? this.presets,
      gameConfigs: gameConfigs ?? this.gameConfigs,
      groups: groups ?? this.groups,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'presets': presets.map((e) => e.toJson()).toList(),
      'gameConfigs': gameConfigs.map((e) => e.toJson()).toList(),
      'groups': groups.map((key, value) => MapEntry(key, value.toList())),
    };
  }

  @override
  PresetsData migrateToNext() {
    throw UnsupportedError('PresetsDataV3 is the latest version');
  }
}
