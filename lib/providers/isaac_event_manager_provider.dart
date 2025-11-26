import 'dart:async';
import 'dart:io';

import 'package:cartridge/constants/isaac_enums.dart';
import 'package:cartridge/services/isaac_log_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef StageEnteredParams = ({IsaacStage stage});

typedef RoomEnteredParams = ({IsaacRoomType roomType});

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

  final _bossClearedStreamController =
      StreamController<BossClearedParams>.broadcast();

  final _recorderStreamController =
      StreamController<(String, List<String>)>.broadcast();

  Stream<StageEnteredParams> get stageEnteredStream =>
      _stageEnteredStreamController.stream;

  Stream<RoomEnteredParams> get roomEnteredStream =>
      _roomEnteredStreamController.stream;

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

  onDebugMessage(String message) {
    if (message.startsWith(_prefix)) {
      final data = message.substring(_prefix.length);
      final parts = data.split(':');
      final eventType = parts[0];
      final eventParams = parts[1].split('.');

      switch (eventType) {
        case 'StageEntered':
          _stageEnteredStreamController
              .add((stage: IsaacStage.values[int.parse(eventParams[0])],));
          break;
        case 'RoomEntered':
          _roomEnteredStreamController.add(
              (roomType: IsaacRoomType.values[int.parse(eventParams[0])],));
          break;
        case 'BossCleared':
          _bossClearedStreamController.add(
              (bossType: IsaacBossType.values[int.parse(eventParams[0])],));
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
