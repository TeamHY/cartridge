import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/utils/background_work.dart';
import 'package:cartridge/core/log.dart';

/// 창 최소화 여부
final isMinimizedProvider = StateProvider<bool>((_) => false);

/// 리소스 모드 컨트롤러
final resourceModeControllerProvider = Provider<ResourceModeController>((ref) {
  return ResourceModeController(ref);
});

class ResourceModeController {
  ResourceModeController(this.ref);
  final Ref ref;

  static const _tag = 'ResourceMode';

  bool _enabled = false;
  int? _prevCacheBytes;

  Future<void> enable() async {
    if (_enabled) {
      logI(_tag, 'enable(): already enabled — skip');
      return;
    }
    _enabled = true;

    try {
      final reg = ref.read(backgroundWorkRegistryProvider);
      final beforeHandles = reg.count;
      final sw = Stopwatch()..start();
      reg.pauseAll();
      sw.stop();

      // 1) 백그라운드 작업(타이머/워처) 일괄 정지
      logI(_tag, 'Paused background works: count=$beforeHandles in ${sw.elapsedMilliseconds}ms');

      // 2) 이미지 캐시 축소
      final cache = PaintingBinding.instance.imageCache;
      _prevCacheBytes ??= cache.maximumSizeBytes;
      cache.maximumSizeBytes = 32 << 20; // 32MB
      logI(_tag, 'ImageCache downsize: prev=${_prevCacheBytes}B → now=${cache.maximumSizeBytes}B');

      // 3) (안전) 프레임 타이밍 원복 보정
      timeDilation = 1.0;

      logI(_tag, 'Resource mode ENABLED');
    } catch (e, st) {
      logE(_tag, 'enable() failed', e, st);
    }
  }

  Future<void> disable() async {
    if (!_enabled) {
      logI(_tag, 'disable(): already disabled — skip');
      return;
    }

    try {
      // 1) 이미지 캐시 용량 원복
      if (_prevCacheBytes != null) {
        final prev = PaintingBinding.instance.imageCache.maximumSizeBytes;
        PaintingBinding.instance.imageCache.maximumSizeBytes = _prevCacheBytes!;
        logI(_tag, 'ImageCache restore: prev=${prev}B → now=${_prevCacheBytes}B');
      }

      // 2) 백그라운드 작업 재개
      final reg = ref.read(backgroundWorkRegistryProvider);
      final sw = Stopwatch()..start();
      reg.resumeAll();
      sw.stop();
      logI(_tag, 'Resumed background works: count=${reg.count} in ${sw.elapsedMilliseconds}ms');

      logI(_tag, 'Resource mode DISABLED');
    } catch (e, st) {
      logE(_tag, 'disable() failed', e, st);
    } finally {
      _enabled = false;
    }
  }
}
