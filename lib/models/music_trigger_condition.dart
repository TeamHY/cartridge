import 'package:cartridge/constants/isaac_enums.dart';

abstract class MusicTriggerCondition {
  String get type;

  Map<String, dynamic> toJson();

  static MusicTriggerCondition fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'stage':
        return StageStayingCondition.fromJson(json);
      case 'room':
        return RoomStayingCondition.fromJson(json);
      case 'boss':
        return BossClearedCondition.fromJson(json);
      default:
        throw Exception('Unknown condition type: $type');
    }
  }
}

class StageStayingCondition extends MusicTriggerCondition {
  final Set<IsaacStage> stage;

  StageStayingCondition(this.stage);

  @override
  String get type => 'stage';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'stage': stage.map((s) => s.index).toList(),
    };
  }

  factory StageStayingCondition.fromJson(Map<String, dynamic> json) {
    return StageStayingCondition(
      (json['stage'] as List<dynamic>)
          .map((e) => IsaacStage.values[e as int])
          .toSet(),
    );
  }
}

class RoomStayingCondition extends MusicTriggerCondition {
  final Set<IsaacRoomType> roomTypes;
  final bool isOnlyWithMonsters;

  RoomStayingCondition(this.roomTypes, this.isOnlyWithMonsters);

  @override
  String get type => 'room';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'roomTypes': roomTypes.map((r) => r.index).toList(),
      'isOnlyWithMonsters': isOnlyWithMonsters,
    };
  }

  factory RoomStayingCondition.fromJson(Map<String, dynamic> json) {
    return RoomStayingCondition(
      (json['roomTypes'] as List<dynamic>)
          .map((e) => IsaacRoomType.values[e as int])
          .toSet(),
      json['isOnlyWithMonsters'] as bool,
    );
  }
}

class BossClearedCondition extends MusicTriggerCondition {
  final Set<IsaacBossType> bossTypes;

  BossClearedCondition(this.bossTypes);

  @override
  String get type => 'boss';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'bossNames': bossTypes.map((b) => b.index).toList(),
    };
  }

  factory BossClearedCondition.fromJson(Map<String, dynamic> json) {
    return BossClearedCondition(
      (json['bossNames'] as List<dynamic>)
          .map((e) => IsaacBossType.values[e as int])
          .toSet(),
    );
  }
}
