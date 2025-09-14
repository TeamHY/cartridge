import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart'; // GameSessionService, getTimeString
import 'package:cartridge/theme/theme.dart';


class RecordTimer extends StatefulWidget {
  const RecordTimer({
    super.key,
    required this.session,
    this.maxBaseFontSize = 60,
    this.boxPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.loading = false,
    this.error = false,
    this.loadingText = '00:00:00.00',
    this.errorText = '--:--:--.--',
  });

  final GameSessionService session;
  final double maxBaseFontSize;
  final EdgeInsetsGeometry boxPadding;

  final bool loading;
  final bool error;
  final String loadingText;
  final String errorText;

  @override
  State<RecordTimer> createState() => _RecordTimerState();
}

class _RecordTimerState extends State<RecordTimer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  StreamSubscription<Duration>? _sub;

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
    _bindStream();
  }

  void _bindStream() {
    _sub?.cancel();
    _sub = widget.session.elapsed().listen((d) {
      _serverElapsed = d;
      _lastSync = DateTime.now();
      _running = d > Duration.zero;
      setState(() => _displayElapsed = d);

      if (_running) {
        if (!_ticker.isActive) _ticker.start();
      } else {
        if (_ticker.isActive) _ticker.stop();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RecordTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _bindStream();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    // 디지털(7세그) + 이탤릭 + 탭귤러 피겨 (AppTypography 규약 사용)
    final baseStyle = AppTypography.timerItalic.copyWith(
      fontSize: widget.maxBaseFontSize,
      color: t.resources.textFillColorPrimary,
      height: 1.0,
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
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: baseStyle,
          ),
        ),
      ),
    );
  }
}
