// test/unit/web_preview/web_preview_controllers_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/web_preview/data/web_preview_repository.dart';
import 'package:cartridge/features/web_preview/application/web_preview_cache.dart';
import 'package:cartridge/features/web_preview/domain/web_preview.dart';

import 'package:cartridge/features/web_preview/application/web_preview_providers.dart'
    show webPreviewRepoProvider, webPreviewCacheProvider, webPreviewProvider;

import 'package:cartridge/features/web_preview/application/preview_warmup_service.dart';
import 'package:cartridge/features/isaac/mod/domain/models/installed_mod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────────────────────────────────────

/// DB를 전혀 사용하지 않는 In-memory Fake Repo.
/// WebPreviewRepository를 상속해서 필요한 메서드만 오버라이드합니다.
class _FakeRepo extends WebPreviewRepository {
  _FakeRepo() : super(db: () async => throw UnimplementedError());

  final _store = <String, WebPreview>{};
  final _changes = StreamController<String>.broadcast();

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<WebPreview?> find(String url) async => _store[url];

  @override
  Future<void> upsert(WebPreview p) async {
    _store[p.url] = p;
    _changes.add(p.url);
  }

  // 아래 메서드들은 테스트에서 사용되지 않지만, 혹시 호출되더라도 문제없게 기본 구현
  @override
  Future<void> link(String source, String sourceId, String url) async {}

  @override
  Future<void> unlink(String source, String sourceId) async {}

  @override
  Future<List<String>> allUrlsFor(String source) async => const [];

  @override
  Future<Set<String>> allImagePaths() async => <String>{};

  @override
  Future<int> sweepOrphans() async => 0;

  @override
  Future<int> deleteExpired() async => 0;
}

/// WarmupService를 간단히 흉내내는 Fake.
/// progress 스트림만 필요하므로 그 부분만 동작하게 합니다.
class _FakeWarmupService extends PreviewWarmupService<InstalledMod> {
  _FakeWarmupService()
      : super(
    cache: WebPreviewCache(_FakeRepo()),
    loadInstalledMods: () async => const <InstalledMod>[],
    workshopIdOf: (m) => '',
    workshopUrlOf: (id) => '',
  );

  final _progress = StreamController<WarmupProgress>.broadcast();
  @override
  Stream<WarmupProgress> get progress => _progress.stream;

  void emit(WarmupProgress p) => _progress.add(p);

  @override
  void dispose() {
    _progress.close();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  group('webPreviewProvider', () {
    late ProviderContainer container;
    late _FakeRepo repo;

    setUp(() {
      repo = _FakeRepo();

      // cache provider도 같은 fake repo를 쓰도록 맞춰둡니다.
      final cache = WebPreviewCache(repo);

      container = ProviderContainer(overrides: [
        webPreviewRepoProvider.overrideWithValue(repo),
        webPreviewCacheProvider.overrideWithValue(cache),
      ]);
      addTearDown(container.dispose);
    });

    test('초기 find() 값 방출 후, 동일 URL changes 발생 시 최신값 재방출', () async {
      const url = 'https://example.com/a';

      final seen = <WebPreview?>[];
      final sub = container.listen(
        webPreviewProvider(url),
            (prev, next) => next.whenData(seen.add),
        fireImmediately: true,
      );

      // 첫 이벤트: find()가 null → null 데이터 방출될 수 있음
      await pumpEventQueue();
      expect(seen.isNotEmpty, isTrue);
      expect(seen.first, isNull);

      // 같은 URL upsert → 변경 이벤트 방출
      final now = DateTime.now();
      await repo.upsert(WebPreview(url: url, title: 'T1', fetchedAt: now));
      await pumpEventQueue();
      expect(seen.last!.title, 'T1');

      // 다른 URL upsert → 무시되어야 함
      await repo.upsert(WebPreview(url: 'https://example.com/other', title: 'X', fetchedAt: now));
      await pumpEventQueue();
      expect(seen.last!.title, 'T1');

      // 같은 URL로 업데이트 → 다시 방출
      await repo.upsert(WebPreview(url: url, title: 'T2', fetchedAt: now.add(const Duration(seconds: 1))));
      await pumpEventQueue();
      expect(seen.last!.title, 'T2');

      sub.close();
    });
  });

  group('previewWarmupProgressProvider', () {
    late ProviderContainer container;
    late _FakeWarmupService svc;

    test('WarmupProgress 스트림이 그대로 노출된다', () async {
      svc = _FakeWarmupService();

      // 실제 앱에서는 다른 파일에 있을 previewWarmupServiceProvider/previewWarmupProgressProvider를 import해서
      // 여기서 service provider만 fake로 갈아끼웁니다.
      final previewWarmupServiceProvider = Provider<PreviewWarmupService<InstalledMod>>((ref) => svc);
      final previewWarmupProgressProvider = StreamProvider<WarmupProgress>((ref) {
        final s = ref.watch(previewWarmupServiceProvider);
        return s.progress;
      });

      container = ProviderContainer(overrides: [
        previewWarmupServiceProvider, // 위에서 정의한 로컬 override 자체가 Provider이므로 그대로 전달
      ]);
      addTearDown(() {
        container.dispose();
        svc.dispose();
      });

      final seen = <WarmupProgress>[];
      final sub = container.listen(
        previewWarmupProgressProvider,
            (prev, next) => next.whenData(seen.add),
        fireImmediately: false,
      );

      // 이벤트 흉내
      svc.emit(const WarmupProgress(total: 4, done: 1, skipped: 0, failed: 0, running: true, paused: false));
      svc.emit(const WarmupProgress(total: 4, done: 2, skipped: 1, failed: 0, running: true, paused: false));
      svc.emit(const WarmupProgress(total: 4, done: 2, skipped: 1, failed: 1, running: false, paused: false));
      await pumpEventQueue();

      expect(seen.length, 3);
      expect(seen.first.done, 1);
      expect(seen.last.running, isFalse);
      expect(seen.last.failed, 1);

      sub.close();
    });
  });
}
