import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cartridge/features/web_preview/application/web_preview_cache.dart';


/// 작업 단위
class _WarmupJob {
  final String source;   // 'workshop_mod'
  final String sourceId; // steam workshop id
  final String url;
  _WarmupJob(this.source, this.sourceId, this.url);
}

/// 진행 상태
class WarmupProgress {
  final int total;
  final int done;
  final int skipped;
  final int failed;
  final bool running;
  final bool paused;

  const WarmupProgress({
    required this.total,
    required this.done,
    required this.skipped,
    required this.failed,
    required this.running,
    required this.paused,
  });

  WarmupProgress copy({
    int? total, int? done, int? skipped, int? failed, bool? running, bool? paused,
  }) => WarmupProgress(
    total: total ?? this.total,
    done: done ?? this.done,
    skipped: skipped ?? this.skipped,
    failed: failed ?? this.failed,
    running: running ?? this.running,
    paused: paused ?? this.paused,
  );

  static const empty = WarmupProgress(
    total: 0, done: 0, skipped: 0, failed: 0, running: false, paused: false,
  );
}

/// 간단한 병렬 풀 + 스로틀
class _ThrottlePool {
  final int concurrency;
  final Duration minGap; // 요청 사이 간격
  final List<Completer<void>> _busy = [];
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);

  _ThrottlePool({required this.concurrency, required this.minGap});

  Future<T> schedule<T>(Future<T> Function() task) async {
    // 슬롯 확보
    while (_busy.length >= concurrency) {
      await Future.any(_busy.map((c) => c.future));
      _busy.removeWhere((f) => f.isCompleted);
    }
    // 간격 확보
    final now = DateTime.now();
    final remain = minGap - now.difference(_lastStart);
    if (remain > Duration.zero) await Future.delayed(remain);
    _lastStart = DateTime.now();

    final slot = Completer<void>();
    _busy.add(slot);

    try {
      return await task();
    } finally {
      // 작업 종료 → 슬롯 반환
      slot.complete();
    }
  }

  Future<void> drain() async {
    await Future.wait(_busy.map((c) => c.future));
    _busy.clear();
  }
}

/// 백그라운드 워밍업 서비스
class PreviewWarmupService<T> {
  PreviewWarmupService({
    required this.cache,
    required this.loadInstalledMods,
    required this.workshopIdOf,
    required this.workshopUrlOf,
  });

  final WebPreviewCache cache;
  final Future<List<T>> Function() loadInstalledMods;
  final String Function(T item) workshopIdOf;
  final String Function(String workshopId) workshopUrlOf;

  final StreamController<WarmupProgress> _progress = StreamController.broadcast();
  Stream<WarmupProgress> get progress => _progress.stream;

  bool _running = false;
  bool _paused  = false;
  bool _cancel  = false;

  void _emit(WarmupProgress p) {
    if (_progress.isClosed) return;
    try {
      _progress.add(p);
    } catch (_) {}
  }

  Future<void> start({int? maxItems}) async {
    if (_running) return;
    _running = true;
    _paused = false;
    _cancel = false;

    // 1) 설치 모드 스냅샷
    final mods = await loadInstalledMods();

    // 2) URL 큐 구성 (이미 캐시 OK면 건너뛰기 위해 탐색)
    final jobs = <_WarmupJob>[];
    for (final it in mods) {
      final modId = (workshopIdOf(it)).trim();
      if (modId.isEmpty) continue;
      final url = workshopUrlOf(modId);
      jobs.add(_WarmupJob('workshop_mod', modId, url));
    }

    // 상한 적용: 유효 작업에서 N개만
    final cappedJobs = (maxItems != null && jobs.length > maxItems)
        ? jobs.take(maxItems).toList(growable: false)
        : jobs;

    // 3) 진행 상태 초기화
    var prog = WarmupProgress(
      total: cappedJobs.length, done: 0, skipped: 0, failed: 0,
      running: true, paused: false,
    );
    _emit(prog);

    // 4) 스로틀/병렬 풀 (네트워크·디스크 부담 낮춤)
    final pool = _ThrottlePool(
      concurrency: _pickConcurrency(),
      minGap: const Duration(milliseconds: 200), // 각 요청 사이 최소 간격
    );
    // 4-1 작업 대기
    final pending = <Future<void>>[];

    // 5) 작업 실행
    for (final j in cappedJobs) {
      if (_cancel) break;

      // 일시정지
      while (_paused && !_cancel) {
        await Future.delayed(const Duration(milliseconds: 120));
      }
      if (_cancel) break;

      // 병렬 슬롯에서 개별 작업
      pending.add(pool.schedule(() async {
        try {
          final prior = await cache.repo.find(j.url);
          final expired = prior?.isExpired ?? true;
          if (prior != null && !expired && prior.imagePath != null && prior.title.isNotEmpty) {
            prog = prog.copy(skipped: prog.skipped + 1);
            _emit(prog);
            return;
          }

          await cache.getOrFetch(
            j.url,
            policy: const RefreshPolicy.ttl(Duration(hours: 24)),
            source: j.source,
            sourceId: j.sourceId,
            targetMaxWidth: 128,
            targetMaxHeight: 128,
            jpegQuality: 85,
          );
          prog = prog.copy(done: prog.done + 1);
          _emit(prog);
        } catch (_) {
          prog = prog.copy(failed: prog.failed + 1);
          _emit(prog);
        }
      }));
    }

    // 모든 스케줄된 작업이 완료될 때까지 대기
    await Future.wait(pending);

    // 종료 정리 + orphan/expired cleanup
    await cache.sweep();

    _running = false;
    _emit(prog.copy(running: false, paused: false));

    await Future<void>.delayed(Duration.zero);
  }

  void pause() {
    if (!_running) return;
    _paused = true;
    _emit(WarmupProgress.empty.copy(paused: true, running: true));
  }

  void resume() {
    if (!_running) return;
    _paused = false;
    _emit(WarmupProgress.empty.copy(paused: false, running: true));
  }

  void cancel() {
    if (!_running) return;
    _cancel = true;
  }

  int _pickConcurrency() {
    // 네트워크/디스크 친화적으로 2~3 권장
    final n = max(2, (Platform.numberOfProcessors / 4).floor());
    return n.clamp(2, 3);
  }

  void dispose() {
    _cancel = true;
    _paused = false;
    if (!_progress.isClosed) {
      _progress.close();
    }
  }
}
