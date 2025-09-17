// lib/core/utils/background_work.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/core/log.dart';

final backgroundWorkRegistryProvider =
Provider<BackgroundWorkRegistry>((_) => BackgroundWorkRegistry());

typedef Starter = void Function();
typedef Canceler = void Function();

class BackgroundWorkRegistry {
  static const _tag = 'BgWork';

  final _handles = <_Handle>[];
  int _nextId = 1;

  int get count => _handles.length;

  /// Timer.periodic 같은 주기 작업을 등록/관리
  void registerPeriodic({
    required Duration interval,
    required void Function(Timer t) onTick,
    String? name,
  }) {
    final id = _nextId++;
    Timer? timer;

    void start() {
      timer = Timer.periodic(interval, onTick);
      logI(_tag, 'start periodic #$id'
          ' ${name != null ? "($name)" : ""} interval=${interval.inMilliseconds}ms');
    }

    void cancel() {
      if (timer != null) {
        timer!.cancel();
        logI(_tag, 'cancel periodic #$id ${name != null ? "($name)" : ""}');
      }
      timer = null;
    }

    final h = _Handle(
      id: id,
      kind: _Kind.periodic,
      label: name ?? 'periodic-${interval.inMilliseconds}ms',
      start: start,
      cancel: cancel,
    );

    _handles.add(h);
    start();
    logI(_tag, 'registered periodic #$id'
        ' (handles=${_handles.length})');
  }

  /// 커스텀 워처(Stream 구독, 파일워처 등)도 등록 가능
  void registerCustom({
    required Starter start,
    required Canceler cancel,
    String? name,
  }) {
    final id = _nextId++;

    final h = _Handle(
      id: id,
      kind: _Kind.custom,
      label: name ?? 'custom',
      start: () {
        start();
        logI(_tag, 'start custom #$id ${name != null ? "($name)" : ""}');
      },
      cancel: () {
        cancel();
        logI(_tag, 'cancel custom #$id ${name != null ? "($name)" : ""}');
      },
    );

    _handles.add(h);
    h.start();
    logI(_tag, 'registered custom #$id (handles=${_handles.length})');
  }

  void pauseAll() {
    final sw = Stopwatch()..start();
    for (final h in _handles) {
      try { h.cancel(); } catch (e, st) {
        logE(_tag, 'pauseAll cancel failed (#${h.id} ${h.label})', e, st);
      }
    }
    sw.stop();
    logI(_tag, 'pauseAll() done: paused=${_handles.length} in ${sw.elapsedMilliseconds}ms');
  }

  void resumeAll() {
    final sw = Stopwatch()..start();
    for (final h in _handles) {
      try { h.start(); } catch (e, st) {
        logE(_tag, 'resumeAll start failed (#${h.id} ${h.label})', e, st);
      }
    }
    sw.stop();
    logI(_tag, 'resumeAll() done: resumed=${_handles.length} in ${sw.elapsedMilliseconds}ms');
  }
}

enum _Kind { periodic, custom }

class _Handle {
  _Handle({
    required this.id,
    required this.kind,
    required this.label,
    required this.start,
    required this.cancel,
  });

  final int id;
  final _Kind kind;
  final String label;
  final Starter start;
  final Canceler cancel;
}
