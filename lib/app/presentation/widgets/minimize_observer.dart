// lib/app/presentation/widgets/minimize_observer.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cartridge/app/presentation/controllers/minimize_resource_mode.dart';
import 'package:cartridge/core/log.dart';

class MinimizeObserver extends ConsumerStatefulWidget {
  const MinimizeObserver({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MinimizeObserver> createState() => _MinimizeObserverState();
}

class _MinimizeObserverState extends ConsumerState<MinimizeObserver>
    with WindowListener {
  static const _tag = 'MinimizeObserver';

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    logI(_tag, 'attached window listener');
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    logI(_tag, 'detached window listener');
    super.dispose();
  }

  @override
  void onWindowMinimize() async {
    logI(_tag, 'onWindowMinimize()');
    ref.read(isMinimizedProvider.notifier).state = true;
    await ref.read(resourceModeControllerProvider).enable();
  }

  @override
  void onWindowRestore() async {
    logI(_tag, 'onWindowRestore()');
    ref.read(isMinimizedProvider.notifier).state = false;
    await ref.read(resourceModeControllerProvider).disable();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 최소화 중에는 모든 Ticker(애니메이션/프레임)를 멈춘다.
/// 전환 시점에만 로그가 찍히게 ConsumerStatefulWidget로 구성.
class TickerGate extends ConsumerStatefulWidget {
  const TickerGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<TickerGate> createState() => _TickerGateState();
}

class _TickerGateState extends ConsumerState<TickerGate> {
  static const _tag = 'TickerGate';
  bool? _lastMinimized;

  @override
  Widget build(BuildContext context) {
    final minimized = ref.watch(isMinimizedProvider);

    if (_lastMinimized != minimized) {
      _lastMinimized = minimized;
      logI(_tag, 'TickerMode -> ${minimized ? "DISABLED (minimized)" : "ENABLED (restored)"}');
    }

    return TickerMode(enabled: !minimized, child: widget.child);
  }
}
