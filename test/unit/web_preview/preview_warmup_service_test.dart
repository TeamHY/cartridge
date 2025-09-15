import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/web_preview/application/web_preview_cache.dart';
import 'package:cartridge/features/web_preview/data/web_preview_repository.dart';
import 'package:cartridge/features/web_preview/domain/web_preview.dart';
import 'package:cartridge/features/web_preview/application/preview_warmup_service.dart';

void main() {
  group('PreviewWarmupService', () {
    late _FakeRepo repo;
    late _FakeCache cache;
    late PreviewWarmupService<String> svc;

    // 설치 모드 목록(여기선 id 문자열로 간단화)
    Future<List<String>> loadInstalled() async => ['1', '2', 'bad', 'skip'];

    String widOf(String v) => v; // 그대로 id 사용
    String urlOf(String id) => 'https://example.com/workshop/$id';

    setUp(() {
      repo  = _FakeRepo();
      cache = _FakeCache(repo);
      svc   = PreviewWarmupService<String>(
        cache: cache,
        loadInstalledMods: loadInstalled,
        workshopIdOf: widOf,
        workshopUrlOf: urlOf,
      );

      // 미리 캐시된(preview OK & not expired) 항목: skip → 스킵 경로 유도
      final now = DateTime.now();
      repo.store[urlOf('skip')] = WebPreview(
        url: urlOf('skip'),
        title: 'ok title',
        imagePath: '/tmp/skip.jpg',
        imageUrl: 'https://img/skip.jpg',
        mime: 'image/jpeg',
        etag: 'etag',
        lastModified: 'Wed, 01 Jan 2030 00:00:00 GMT',
        statusCode: 200,
        fetchedAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(days: 1)), // not expired
        hash: 'h',
      );

      // 실패 유도: id == 'bad' → getOrFetch 예외
      cache.failUrls.add(urlOf('bad'));
    });

    tearDown(() {
      svc.dispose();
    });

    test('start(): done / skipped / failed 카운트 & sweep() 호출 & 종료 이벤트 검증', () async {
      final events = <WarmupProgress>[];
      final sub = svc.progress.listen(events.add);

      await svc.start(); // 1,2,bad,skip 처리

      await sub.cancel();

      // 최종 이벤트 확인
      expect(events, isNotEmpty);
      final last = events.last;
      expect(last.running, isFalse);
      expect(last.paused, isFalse);

      // 총 4개 대상중: 1(done), 2(done), bad(failed), skip(skipped)
      expect(last.total, 4);
      expect(last.done, 2);
      expect(last.failed, 1);
      expect(last.skipped, 1);

      // getOrFetch 성공 호출 기록 확인(1,2)
      expect(cache.fetchedUrls.toSet(),
          {urlOf('1'), urlOf('2')});

      // sweep 1회 수행
      expect(cache.sweepCalls, 1);
    });

    test('pause()/resume(): 진행 이벤트에 반영되며 이후 정상 완료', () async {
      final events = <WarmupProgress>[];
      final sub = svc.progress.listen(events.add);

      // 비동기 시작
      unawaited(svc.start());

      // 초기 total 이벤트 올 때까지 대기
      await _waitUntil(() => events.any((e) => e.running && e.total > 0));

      svc.pause();
      await _waitUntil(() => events.any((e) => e.running && e.paused));

      svc.resume();
      await _waitUntil(() => events.any((e) => e.running && !e.paused));

      // 완료 대기
      await _waitUntil(() => events.isNotEmpty && !events.last.running, timeoutMs: 8000);

      await sub.cancel();

      expect(events.any((e) => e.paused == true), isTrue, reason: 'pause 이벤트가 있어야 함');
      expect(events.last.running, isFalse);
    });

    test('maxItems: 상한 개수 만큼만 처리', () async {
      final events = <WarmupProgress>[];
      final sub = svc.progress.listen(events.add);

      await svc.start(maxItems: 3);

      await sub.cancel();

      // 총 대상이 3개로 제한
      final last = events.last;
      expect(last.total, 3);

      // skip이 그 3개 안에 포함되면 done+skipped 합이 3이 된다.
      expect(last.done + last.skipped + last.failed, 3);
      expect(last.total, lessThanOrEqualTo(3));
    });

    test('이미 캐시가 있었지만 만료 or 이미지/제목 불완전하면 fetch 수행', () async {
      final now = DateTime.now();
      // 만료된 항목
      repo.store[urlOf('1')] = WebPreview(
        url: urlOf('1'),
        title: 'old',
        imagePath: '/tmp/old.jpg',
        fetchedAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.subtract(const Duration(days: 1)), // expired
        imageUrl: null, mime: null, etag: null, lastModified: null,
        statusCode: 200, hash: null,
      );
      // 이미지 없음(불완전)
      repo.store[urlOf('2')] = WebPreview(
        url: urlOf('2'),
        title: 'has-title-no-image',
        imagePath: null, // 불완전 → fetch 유도
        imageUrl: null, mime: null, etag: null, lastModified: null,
        statusCode: 200,
        fetchedAt: now,
        expiresAt: now.add(const Duration(days: 1)),
        hash: null,
      );

      await svc.start();

      // 두 URL 모두 다시 fetch 되었어야 한다.
      expect(cache.fetchedUrls.toSet().containsAll({urlOf('1'), urlOf('2')}), isTrue);
    });
  });
}

// ── Fakes & helpers ───────────────────────────────────────────────────────────

class _FakeRepo implements WebPreviewRepository {
  final _changes = StreamController<String>.broadcast();
  final Map<String, WebPreview> store = {}; // url -> preview
  final Map<(String source, String sourceId), String> links = {}; // (source, id) -> url

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<WebPreview?> find(String url) async => store[url];

  @override
  Future<void> upsert(WebPreview p) async {
    store[p.url] = p;
    _changes.add(p.url);
  }

  @override
  Future<void> link(String source, String sourceId, String url) async {
    links[(source, sourceId)] = url;
  }

  @override
  Future<void> unlink(String source, String sourceId) async {
    links.remove((source, sourceId));
  }

  @override
  Future<List<String>> allUrlsFor(String source) async {
    return links.entries
        .where((e) => e.key.$1 == source)
        .map((e) => e.value)
        .toList();
  }

  @override
  Future<Set<String>> allImagePaths() async {
    return store.values.map((e) => e.imagePath).whereType<String>().toSet();
  }

  @override
  Future<int> sweepOrphans() async {
    final referenced = links.values.toSet();
    final before = store.length;
    store.removeWhere((url, _) => !referenced.contains(url));
    return before - store.length;
  }

  @override
  Future<int> deleteExpired() async {
    final now = DateTime.now();
    final before = store.length;
    store.removeWhere((_, p) => p.expiresAt != null && now.isAfter(p.expiresAt!));
    return before - store.length;
  }
}

class _FakeCache implements WebPreviewCache {
  _FakeCache(this._repo);

  final _FakeRepo _repo;
  final List<String> fetchedUrls = [];
  final Set<String> failUrls = {};
  int sweepCalls = 0;

  @override
  WebPreviewRepository get repo => _repo;


  @override
  Future<void> sweep() async {
    sweepCalls += 1;
  }

  @override
  Future<void> evictLink(String source, String sourceId) {
    throw UnimplementedError();
  }

  @override
  Future<WebPreview> getOrFetch(
      String url, {
        RefreshPolicy policy = const RefreshPolicy.ttl(Duration(hours: 24)),
        String? source,
        String? sourceId,
        bool forceRefresh = false,
        int? targetMaxWidth,
        int? targetMaxHeight,
        int jpegQuality = 85,
        String? acceptLanguage,
      }) async {
    if (failUrls.contains(url)) {
      throw Exception('fetch failed: $url');
    }

    final now = DateTime.now();
    final p = WebPreview(
      url: url,
      title: 'title-$url',
      imagePath: '/tmp/${url.hashCode}.jpg',
      imageUrl: 'https://img/${url.hashCode}.jpg',
      mime: 'image/jpeg',
      etag: 'etag',
      lastModified: 'Wed, 01 Jan 2030 00:00:00 GMT',
      statusCode: 200,
      fetchedAt: now,
      expiresAt: now.add(const Duration(hours: 12)),
      hash: 'h',
    );

    await _repo.upsert(p);

    if (source != null && sourceId != null) {
      await _repo.link(source, sourceId, url);
    }

    fetchedUrls.add(url);
    return p;
  }
}

/// 이벤트 기다림 헬퍼(간단 폴링)
Future<void> _waitUntil(bool Function() cond, {int timeoutMs = 5000}) async {
  final deadline = DateTime.now().millisecondsSinceEpoch + timeoutMs;
  while (!cond()) {
    if (DateTime.now().millisecondsSinceEpoch > deadline) {
      fail('waitUntil timeout ($timeoutMs ms)');
    }
    // 너무 바쁘게 돌지 않도록 살짝 양보
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
