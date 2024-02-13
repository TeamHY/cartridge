import 'package:uuid/uuid.dart';

class OptionPreset {
  final String id;
  final String name;
  final int windowWidth;
  final int windowHeight;
  final int windowPosX;
  final int windowPosY;

  OptionPreset({
    String? id,
    required this.name,
    required this.windowWidth,
    required this.windowHeight,
    required this.windowPosX,
    required this.windowPosY,
  }) : id = id ?? const Uuid().v4();

  factory OptionPreset.fromJson(Map<String, dynamic> json) {
    return OptionPreset(
      id: json['id'],
      name: json['name'],
      windowWidth: json['windowWidth'] ?? 960,
      windowHeight: json['windowHeight'] ?? 540,
      windowPosX: json['windowPosX'] ?? 100,
      windowPosY: json['windowPosY'] ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'windowPosX': windowPosX,
      'windowPosY': windowPosY,
    };
  }
}
