import 'mod.dart';

class Preset {
  String name;
  List<Mod> mods;
  String? optionPresetId;

  Preset({required this.name, required this.mods, this.optionPresetId});

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      name: json['name'],
      mods: (json['mods'] as List<dynamic>)
          .map((mod) => Mod.fromJson(mod as Map<String, dynamic>))
          .toList(),
      optionPresetId: json['optionPresetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mods': mods.map((e) => e.toJson()).toList(),
      'optionPresetId': optionPresetId,
    };
  }
}
