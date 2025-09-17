import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cartridge/core/log.dart';

enum LaunchOrigin { instancePage, quickInstance, quickVanilla, recordMode }

final gameLaunchUxProvider = Provider<GameLaunchUx>((ref) => GameLaunchUx(ref));

class GameLaunchUx {
  GameLaunchUx(this.ref);
  final Ref ref;
  static const _tag = 'GameLaunchUX';

  /// 게임 실행 직전에 호출. recordMode면 최소화 스킵.
  Future<void> beforeLaunch({
    required LaunchOrigin origin,
    bool recordMode = false,
  }) async {
    try {
      // 1) record 모드면 항상 스킵
      if (recordMode) {
        logI(_tag, 'skip minimize for record mode (origin=$origin)');
        return;
      }

      // 2) 앱 설정에 "게임 시작 시 최소화"가 생기면 여기서 반영
      final allowMinimize = _isMinimizeAllowedBySetting();
      if (!allowMinimize) {
        logI(_tag, 'minimize skipped by setting (origin=$origin)');
        return;
      }

      // 3) 실제 최소화
      final isMin = await windowManager.isMinimized();
      if (isMin) {
        logI(_tag, 'already minimized (origin=$origin)');
      } else {
        await windowManager.minimize();
        logI(_tag, 'window minimized (origin=$origin)');
      }
    } catch (e, st) {
      logE(_tag, 'beforeLaunch failed (origin=$origin)', e, st);
    }
  }

  bool _isMinimizeAllowedBySetting() {
    // TODO: 게임 실행시 프로그램 최소화 여부 옵션 추가한다면 여기에 추가
    // ex)
    // final s = ref.read(appSettingControllerProvider).valueOrNull;
    // return s?.minimizeOnGameStart ?? true;

    // 현재는 기본 ON
    return true;
  }
}
