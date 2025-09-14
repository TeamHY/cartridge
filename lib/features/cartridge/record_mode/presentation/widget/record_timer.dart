import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart'; // GameSessionService, getTimeString
import 'package:cartridge/theme/theme.dart';

/// 심플 타이머 위젯
/// - theme.md 준수(고정색 X)
/// - 로딩/에러: 고정 텍스트로만 표시하여 레이아웃 안정
class RecordTimer extends StatefulWidget {
  const RecordTimer({
    super.key,
    required this.session,
    this.fontSize = 48,
    this.fontWeight = FontWeight.w500,
    this.loading = false,
    this.error = false,
    this.loadingText = '00:00:00.00',
    this.errorText = '--:--:--.--',
  });

  final GameSessionService session;

  final double fontSize;
  final FontWeight fontWeight;

  /// true면 로딩 텍스트
  final bool loading;

  /// true면 에러 텍스트
  final bool error;

  /// 로딩 시 표시 문자열(가변폭 방지를 위해 고정 길이 권장)
  final String loadingText;

  /// 에러 시 표시 문자열(가변폭 방지를 위해 고정 길이 권장)
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

    final textStyle = AppTypography.timerItalic.copyWith(
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
      color: t.resources.textFillColorPrimary,
    );

    final secondary = t.resources.textFillColorSecondary;
    final estimatedHeight = widget.fontSize * 1.1;

    // 로딩: 고정 문자열
    if (widget.loading) {
      return SizedBox(
        height: estimatedHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.loadingText, style: textStyle.copyWith(color: secondary)),
        ),
      );
    }

    // 에러: 고정 문자열
    if (widget.error) {
      return SizedBox(
        height: estimatedHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.errorText, style: textStyle.copyWith(color: secondary)),
        ),
      );
    }

    // 정상: 경과 시간
    final timeText = getTimeString(_displayElapsed);
    return SizedBox(
      height: estimatedHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(timeText, style: textStyle),
      ),
    );
  }
}
