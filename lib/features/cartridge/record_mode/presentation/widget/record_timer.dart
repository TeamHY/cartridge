import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/cartridge/record_mode/application/record_mode_providers.dart';
import 'package:cartridge/theme/theme.dart';

class RecordTimer extends ConsumerStatefulWidget {
  const RecordTimer({
    super.key,
    this.maxBaseFontSize = 60,
    this.boxPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.loading = false,
    this.error = false,
    this.loadingText = '00:00:00.00',
    this.errorText = '--:--:--.--',
  });

  final double maxBaseFontSize;
  final EdgeInsetsGeometry boxPadding;
  final bool loading;
  final bool error;
  final String loadingText;
  final String errorText;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RecordTimerState();
}

class _RecordTimerState extends ConsumerState<RecordTimer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  Duration _serverElapsed = Duration.zero;
  Duration _displayElapsed = Duration.zero;
  DateTime _lastSync = DateTime.now();
  bool _running = false;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((_) {
      if (!_running) return;
      final now = DateTime.now();
      final dt = now.difference(_lastSync);
      final next = _serverElapsed + dt;
      if ((next - _displayElapsed).inMilliseconds >= 8) {
        setState(() => _displayElapsed = next);
      }
    });

    // 1) 초기값을 즉시 반영
    final initial = ref.read(recordModeElapsedProvider);
    _apply(initial);
  }

  void _apply(AsyncValue<Duration> v) {
    v.when(
      data: (d) {
        _serverElapsed = d;
        _lastSync = DateTime.now();
        final wasRunning = _running;
        _running = d > Duration.zero;
        setState(() => _displayElapsed = d);

        if (_running && !_ticker.isActive) _ticker.start();
        if (!_running && _ticker.isActive) _ticker.stop();

        if (!wasRunning && _running) {
          _displayElapsed = d; // 시작 시 한 번 더 동기화
        }
      },
      loading: () => _resetToZero(),
      error: (_, __) => _resetToZero(),
    );
  }

  void _resetToZero() {
    if (_ticker.isActive) _ticker.stop();
    _running = false;
    setState(() => _displayElapsed = Duration.zero);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final baseStyle = AppTypography.timerItalic.copyWith(
      fontSize: widget.maxBaseFontSize,
      color: t.resources.textFillColorPrimary,
      height: 1.0,
    );

    ref.listen<AsyncValue<Duration>>(
      recordModeElapsedProvider,
          (prev, next) => _apply(next),
      onError: (_, __) => _resetToZero(),
    );

    final text = widget.loading
        ? widget.loadingText
        : (widget.error ? widget.errorText : getTimeString(_displayElapsed));

    return Padding(
      padding: widget.boxPadding,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(text, maxLines: 1, softWrap: false, textAlign: TextAlign.center, style: baseStyle),
        ),
      ),
    );
  }
}