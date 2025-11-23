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
  final int stage;
  final bool isRepentance;

  StageStayingCondition(this.stage, this.isRepentance);

  @override
  String get type => 'stage';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'stage': stage,
      'isRepentance': isRepentance,
    };
  }

  factory StageStayingCondition.fromJson(Map<String, dynamic> json) {
    return StageStayingCondition(
      json['stage'] as int,
      json['isRepentance'] as bool,
    );
  }
}

class RoomStayingCondition extends MusicTriggerCondition {
  final int roomType;
  final bool isOnlyUncleared;

  RoomStayingCondition(this.roomType, this.isOnlyUncleared);

  @override
  String get type => 'room';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'roomType': roomType,
      'isOnlyUncleared': isOnlyUncleared,
    };
  }

  factory RoomStayingCondition.fromJson(Map<String, dynamic> json) {
    return RoomStayingCondition(
      json['roomType'] as int,
      json['isOnlyUncleared'] as bool,
    );
  }
}

class BossClearedCondition extends MusicTriggerCondition {
  final String bossName;

  BossClearedCondition(this.bossName);

  @override
  String get type => 'boss';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'bossName': bossName,
    };
  }

  factory BossClearedCondition.fromJson(Map<String, dynamic> json) {
    return BossClearedCondition(
      json['bossName'] as String,
    );
  }
}
