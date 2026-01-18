import 'dart:async';
import 'dart:io';

import 'package:cartridge/constants/isaac_enums.dart';
import 'package:cartridge/services/isaac_log_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef StageEnteredParams = ({IsaacStage stage});

typedef RoomEnteredParams = ({
  IsaacRoomType roomType,
  bool isCleared,
  IsaacBossType? bossType
});

typedef RoomClearedParams = ({IsaacRoomType roomType});

typedef BossClearedParams = ({IsaacBossType bossType});

class IsaacEventManager {
  static const String _prefix = '[Cartridge]';

  static const String _recorderPrefix = '[CR]';

  late final IsaacLogFile _logFile;

  String get isaacDocumentPath {
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Documents/My Games/Binding of Isaac Repentance+';
    }

    return '${Platform.environment['UserProfile']}\\Documents\\My Games\\Binding of Isaac Repentance+';
  }

  final _stageEnteredStreamController =
      StreamController<StageEnteredParams>.broadcast();

  final _roomEnteredStreamController =
      StreamController<RoomEnteredParams>.broadcast();

  final _roomClearedStreamController =
      StreamController<RoomClearedParams>.broadcast();

  final _bossClearedStreamController =
      StreamController<BossClearedParams>.broadcast();

  final _recorderStreamController =
      StreamController<(String, List<String>)>.broadcast();

  Stream<StageEnteredParams> get stageEnteredStream =>
      _stageEnteredStreamController.stream;

  Stream<RoomEnteredParams> get roomEnteredStream =>
      _roomEnteredStreamController.stream;

  Stream<RoomClearedParams> get roomClearedStream =>
      _roomClearedStreamController.stream;

  Stream<BossClearedParams> get bossClearedStream =>
      _bossClearedStreamController.stream;

  Stream<(String, List<String>)> get recorderStream =>
      _recorderStreamController.stream;

  IsaacEventManager() {
    _logFile = IsaacLogFile(
      '$isaacDocumentPath${Platform.pathSeparator}log.txt',
      onDebugMessage: onDebugMessage,
    );
  }

// StageType = {
//     STAGETYPE_ORIGINAL = 0,
//     STAGETYPE_WOTL = 1,
//     STAGETYPE_AFTERBIRTH = 2,
//     STAGETYPE_GREEDMODE = 3, -- deprecated, Greed Mode no longer has its own stages
//     STAGETYPE_REPENTANCE = 4,
//     STAGETYPE_REPENTANCE_B = 5,
// }

  IsaacStage _convertStageToIsaacStage(int stage, int stageType) {
    switch (stage) {
      case 1:
      case 2:
        switch (stageType) {
          case 0:
            return IsaacStage.basement;
          case 1:
            return IsaacStage.cellar;
          case 2:
            return IsaacStage.burningBasement;
          case 4:
            return IsaacStage.downpour;
          case 5:
            return IsaacStage.dross;
        }
        break;
      case 3:
      case 4:
        switch (stageType) {
          case 0:
            return IsaacStage.caves;
          case 1:
            return IsaacStage.catacombs;
          case 2:
            return IsaacStage.floodedCaves;
          case 4:
            return IsaacStage.mines;
          case 5:
            return IsaacStage.ashpit;
        }
        break;
      case 5:
      case 6:
        switch (stageType) {
          case 0:
            return IsaacStage.depths;
          case 1:
            return IsaacStage.necropolis;
          case 2:
            return IsaacStage.dankDepths;
          case 4:
            return IsaacStage.mausoleum;
          case 5:
            return IsaacStage.gehenna;
        }
        break;
      case 7:
      case 8:
        switch (stageType) {
          case 0:
            return IsaacStage.womb;
          case 1:
            return IsaacStage.utero;
          case 2:
            return IsaacStage.scarredWomb;
          case 4:
            return IsaacStage.corpse;
        }
        break;
      case 9:
        return IsaacStage.blueWomb;
      case 10:
        switch (stageType) {
          case 0:
            return IsaacStage.sheol;
          case 1:
            return IsaacStage.cathedral;
        }
        break;
      case 11:
        switch (stageType) {
          case 0:
            return IsaacStage.darkRoom;
          case 1:
            return IsaacStage.chest;
        }
        break;
      case 12:
        return IsaacStage.theVoid;
      case 13:
        switch (stageType) {
          case 0:
            return IsaacStage.homeDay;
          case 1:
            return IsaacStage.homeNight;
        }
        break;
    }

    return IsaacStage.basement;
  }

  onDebugMessage(String message) {
    if (message.startsWith(_prefix)) {
      final data = message.substring(_prefix.length);
      final parts = data.split(':');
      final eventType = parts[0];
      final eventParams = parts[1].split('.');

      switch (eventType) {
        case 'StageEntered':
          final stage = int.parse(eventParams[0]);
          final stageType = int.parse(eventParams[1]);

          _stageEnteredStreamController
              .add((stage: _convertStageToIsaacStage(stage, stageType)));
          break;
        case 'RoomEntered':
          final roomType = int.parse(eventParams[0]);

          _roomEnteredStreamController.add((
            roomType: IsaacRoomType.fromValue(roomType),
            isCleared: eventParams[1] == 'true',
            bossType: eventParams.length > 2
                ? IsaacBossType.values[int.parse(eventParams[2])]
                : null,
          ));
          break;
        case 'RoomCleared':
          final roomType = int.parse(eventParams[0]);

          _roomClearedStreamController
              .add((roomType: IsaacRoomType.fromValue(roomType)));
          break;
        case 'BossCleared':
          final bossTypeString = eventParams[0];

          for (var type in IsaacBossType.values) {
            if (type.name == bossTypeString) {
              _bossClearedStreamController.add((bossType: type));
              break;
            }
          }
          break;
        default:
          if (kDebugMode) {
            print('Unknown event type: $eventType');
          }
          break;
      }
    } else if (message.startsWith(_recorderPrefix)) {
      final data = message.substring(_recorderPrefix.length);
      final parts = data.split(':');

      _recorderStreamController.add((parts[0], parts[1].split('.')));
    }
  }

  void dispose() {
    _logFile.dispose();
    _stageEnteredStreamController.close();
    _roomEnteredStreamController.close();
    _recorderStreamController.close();
  }
}

final isaacEventManagerProvider = Provider<IsaacEventManager>((ref) {
  final manager = IsaacEventManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});
