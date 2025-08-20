import 'package:uuid/uuid.dart';

class GameConfig {
  final String id;
  final String name;
  final int windowWidth;
  final int windowHeight;
  final int windowPosX;
  final int windowPosY;

  GameConfig({
    String? id,
    required this.name,
    this.windowWidth = 960,
    this.windowHeight = 540,
    this.windowPosX = 100,
    this.windowPosY = 100,
  }) : id = id ?? const Uuid().v4();

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      id: json['id'],
      name: json['name'],
      windowWidth: json['windowWidth'],
      windowHeight: json['windowHeight'],
      windowPosX: json['windowPosX'],
      windowPosY: json['windowPosY'],
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