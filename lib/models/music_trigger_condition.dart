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
  final IsaacRoomType roomType;
  final bool isOnlyUncleared;

  RoomStayingCondition(this.roomType, this.isOnlyUncleared);

  @override
  String get type => 'room';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'roomType': roomType.index,
      'isOnlyUncleared': isOnlyUncleared,
    };
  }

  factory RoomStayingCondition.fromJson(Map<String, dynamic> json) {
    return RoomStayingCondition(
      IsaacRoomType.values[json['roomType'] as int],
      json['isOnlyUncleared'] as bool,
    );
  }
}

class BossClearedCondition extends MusicTriggerCondition {
  final IsaacBossType bossType;

  BossClearedCondition(this.bossType);

  @override
  String get type => 'boss';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'bossName': bossType.index,
    };
  }

  factory BossClearedCondition.fromJson(Map<String, dynamic> json) {
    return BossClearedCondition(
      IsaacBossType.values[json['bossName'] as int],
    );
  }
}
