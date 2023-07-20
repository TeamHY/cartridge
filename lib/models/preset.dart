import 'mod.dart';

class Preset {
  final String name;
  final List<Mod> mods;

  Preset({required this.name, required this.mods});

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      name: json['name'],
      mods: (json['mods'] as List<dynamic>)
          .map((mod) => Mod.fromJson(mod as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mods': mods,
    };
  }
}
