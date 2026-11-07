import 'game_launch_mode.dart';
import 'mod.dart';

class Preset {
  String name;
  List<Mod> mods;
  String? gameConfigId;
  GameLaunchMode launchMode;

  Preset({
    required this.name,
    required this.mods,
    this.gameConfigId,
    this.launchMode = GameLaunchMode.vanilla,
  });

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      name: json['name'],
      mods: (json['mods'] as List<dynamic>)
          .map((mod) => Mod.fromJson(mod as Map<String, dynamic>))
          .toList(),
      gameConfigId: json['gameConfigId'] ?? json['optionPresetId'],
      launchMode: GameLaunchMode.fromName(json['launchMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mods': mods.map((e) => e.toJson()).toList(),
      'gameConfigId': gameConfigId,
      'launchMode': launchMode.name,
    };
  }
}
