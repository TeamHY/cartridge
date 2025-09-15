
import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModPresetsService', () {
    late _MemRepo repo;
    late ModPresetsService sut;

    setUp(() {
      repo = _MemRepo();
      sut = ModPresetsService(
        repository: repo,
        envService: _StubEnv(), // 기본은 사용 안 함(override를 넘길 예정)
        projector: const ModPresetProjector(),
      );
    });

    // ── Queries ───────────────────────────────────────────────────────────
    test('listAllViews(): pos ASC 순서 유지', () async {
      // Given
      final a = ModPreset(id: 'a', name: 'Alpha', entries: const []);
      final b = ModPreset(id: 'b', name: 'Beta', entries: const []);
      final c = ModPreset(id: 'c', name: 'Gamma', entries: const []);
      repo.seed([a, b, c], order: const ['b', 'c', 'a']);

      // When
      final views = await sut.listAllViews(installedOverride: const {});

      // Then: repo.listAll()는 order 유지, projector는 id/name만 투영
      expect(views.map((e) => e.key).toList(), ['b', 'c', 'a']);
      expect(views.first.name, 'Beta');
    });

    test('getViewById()/getById(): 존재 시 반환, 없으면 null/notFound', () async {
      // Given
      final p = ModPreset(id: 'x', name: 'X', entries: const []);
      repo.seed([p], order: const ['x']);

      // When
      final res = await sut.getViewById(presetId: 'x', installedOverride: const {});
      final v = await sut.getById(presetId: 'x', installedOverride: const {});
      final miss = await sut.getViewById(presetId: 'ghost', installedOverride: const {});

      // Then
      res.map(
        ok: (r) => expect(r.data!.key, 'x'),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      expect(v!.key, 'x');
      miss.map(
        notFound: (r) => expect(r.code, 'modPreset.getViewById.notFound'),
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
      );
    });

    test('getRawPresetsByIds(): 존재하는 것만 반환, 순서는 입력과 무관', () async {
      repo.seed([
        ModPreset(id: 'a', name: 'A', entries: const []),
        ModPreset(id: 'b', name: 'B', entries: const []),
      ], order: const ['a', 'b']);

      final list = await sut.getRawPresetsByIds({'b', 'ghost', 'a'});
      expect(list.map((e) => e.id).toSet(), {'a', 'b'});
    });

    // ── Commands: create/rename/delete/clone ───────────────────────────────
    test('create(): SeedMode.allOff → entries 0, Result.ok', () async {
      final res = await sut.create(
        name: '  New  ',
        seedMode: SeedMode.allOff,
        installedOverride: const {},
      );

      res.map(
        ok: (r) {
          expect(r.code, 'modPreset.create.ok');
          expect(repo.items.length, 1);
          final saved = repo.items.values.single;
          expect(saved.name, isNotEmpty); // normalize에서 공백 제거
          expect(saved.entries, isEmpty);
        },
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
    });

    test('rename(): notFound → Result.notFound', () async {
      final res = await sut.rename('ghost', 'X', installedOverride: const {});
      res.map(
        notFound: (r) => expect(r.code, 'modPreset.rename.notFound'),
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
      );
    });

    test('rename(): 동일 이름 → Result.ok(code noop)', () async {
      final p = ModPreset(id: 'a', name: 'Same', entries: const []);
      repo.seed([p], order: const ['a']);
      final res = await sut.rename('a', '  Same  ', installedOverride: const {});
      res.map(
        ok: (r) => expect(r.code, 'modPreset.rename.noop'),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
    });

    test('rename(): 다른 이름 → Result.ok(code ok) + 저장', () async {
      final p = ModPreset(id: 'a', name: 'Old', entries: const []);
      repo.seed([p], order: const ['a']);
      final res = await sut.rename('a', ' New ', installedOverride: const {});
      res.map(
        ok: (r) {
          expect(r.code, 'modPreset.rename.ok');
          expect(repo.items['a']!.name, 'New');
        },
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
    });

    test('delete(): 존재하지 않으면 notFound, 존재하면 ok', () async {
      final p = ModPreset(id: 'a', name: 'A', entries: const []);
      repo.seed([p], order: const ['a']);

      final r1 = await sut.delete('ghost');
      r1.map(
        notFound: (r) => expect(r.code, 'modPreset.delete.notFound'),
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
      );

      final r2 = await sut.delete('a');
      r2.map(
        ok: (r) => expect(r.code, 'modPreset.delete.ok'),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      expect(repo.items.containsKey('a'), isFalse);
    });

    test('clone(): notFound → Result.notFound', () async {
      final r = await sut.clone(sourceId: 'ghost', duplicateSuffix: '(copy)', installedOverride: const {});
      r.map(
        notFound: (r) => expect(r.code, 'modPreset.clone.notFound'),
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
      );
    });

    test('clone(): 정상 → 새 id 저장 + 이름 suffix 반영', () async {
      final base = ModPreset(id: 'base', name: 'Base', entries: const []);
      repo.seed([base], order: const ['base']);

      final r = await sut.clone(sourceId: 'base', duplicateSuffix: '(copy)', installedOverride: const {});
      r.map(
        ok: (res) {
          expect(res.code, 'modPreset.clone.ok');
          expect(repo.items.length, 2);
          final ids = repo.items.keys.toList();
          expect(ids.contains('base'), isTrue);
          final cloneId = ids.firstWhere((id) => id != 'base');
          expect(repo.items[cloneId]!.name, 'Base (copy)');
        },
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
    });

    test('removeMissing(): notFound → Result.notFound', () async {
      final r = await sut.removeMissing(presetId: 'ghost', installedOverride: const {});
      r.map(
        notFound: (r) => expect(r.code, 'modPreset.removeMissing.notFound'),
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
      );
    });

    test('removeMissing(): entries가 없으면 noop, 있으면 installed에 맞춰 삭제', () async {
      // noop
      final empty = ModPreset(id: 'e', name: 'Empty', entries: const []);
      repo.seed([empty], order: const ['e']);
      final r1 = await sut.removeMissing(presetId: 'e', installedOverride: const {});
      r1.map(
        ok: (r) => expect(r.code, 'modPreset.removeMissing.noop'),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );

      // installed가 비어있고 entries가 존재 → 모두 제거
      final p = ModPreset(id: 'p', name: 'P', entries: [
        ModEntry(key: 'mod.a', enabled: true, favorite: false),
        ModEntry(key: 'mod.b', enabled: false, favorite: false),
      ]);
      repo.seed([p], order: const ['p']);
      final r2 = await sut.removeMissing(presetId: 'p', installedOverride: const {});
      r2.map(
        ok: (r) {
          expect(r.code, 'modPreset.removeMissing.ok');
          expect(repo.items['p']!.entries, isEmpty);
        },
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
    });

    // ── Sorting ────────────────────────────────────────────────────────────
    test('reorderModPresets(): strict=true 정상 재배치 → Result.ok', () async {
      repo.seed([
        ModPreset(id: 'a', name: 'A', entries: const []),
        ModPreset(id: 'b', name: 'B', entries: const []),
        ModPreset(id: 'c', name: 'C', entries: const []),
      ], order: const ['a', 'b', 'c']);

      final res = await sut.reorderModPresets(['b', 'c', 'a'] ,);
      res.map(
        ok: (r) => expect(r.code, 'modPreset.reorder.ok'),
        invalid: (_) => fail('expected ok'),
        notFound: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      expect(repo.order, ['b', 'c', 'a']);
    });

    test('reorderModPresets(): repo가 ArgumentError → failure(code invalid)', () async {
      final bad = _ThrowingRepo(argError: true);
      final svc = ModPresetsService(repository: bad, envService: _StubEnv(), projector: const ModPresetProjector());
      final res = await svc.reorderModPresets(['a']);
      res.map(
        failure: (r) => expect(r.code, 'modPreset.reorder.invalid'),
        ok: (_) => fail('expected failure'),
        invalid: (_) => fail('expected failure'),
        notFound: (_) => fail('expected failure'),
        conflict: (_) => fail('expected failure'),
      );
    });

    test('reorderModPresets(): repo가 예기치 못한 예외 → failure(code failure)', () async {
      final bad = _ThrowingRepo(argError: false);
      final svc = ModPresetsService(repository: bad, envService: _StubEnv(), projector: const ModPresetProjector());
      final res = await svc.reorderModPresets(['a']);
      res.map(
        failure: (r) => expect(r.code, 'modPreset.reorder.failure'),
        ok: (_) => fail('expected failure'),
        invalid: (_) => fail('expected failure'),
        notFound: (_) => fail('expected failure'),
        conflict: (_) => fail('expected failure'),
      );
    });
  });
}

// ── Test Doubles ───────────────────────────────────────────────────────────
class _MemRepo implements IModPresetsRepository {
  final Map<String, ModPreset> items = {};
  final List<String> order = [];

  void seed(List<ModPreset> list, {required List<String> order}) {
    items
      ..clear()
      ..addEntries(list.map((e) => MapEntry(e.id, e)));
    this.order
      ..clear()
      ..addAll(order);
  }

  @override
  Future<ModPreset?> findById(String id) async => items[id];

  @override
  Future<List<ModPreset>> listAll() async => order.map((id) => items[id]!).toList();

  @override
  Future<void> removeById(String id) async {
    items.remove(id);
    order.removeWhere((e) => e == id);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    if (strict) {
      final a = Set.of(order);
      final b = Set.of(orderedIds);
      if (a.length != b.length || !a.containsAll(b)) {
        throw ArgumentError('orderedIds must be a permutation of existing ids');
      }
    }
    order
      ..clear()
      ..addAll(orderedIds);
  }

  @override
  Future<void> upsert(ModPreset preset) async {
    final exists = items.containsKey(preset.id);
    items[preset.id] = preset;
    if (!exists) order.add(preset.id);
  }

  // Entries 단건 최적화 메서드들은 서비스 테스트에서 직접 사용하지 않으므로 noop로 둡니다.
  @override
  Future<void> upsertEntry(String presetId, ModEntry entry) async {
    final cur = items[presetId];
    if (cur == null) return;
    final list = [...cur.entries];
    final i = list.indexWhere((e) => e.key == entry.key);
    if (i < 0) {
      list.add(entry);
    } else {
      list[i] = entry;
    }
    items[presetId] = cur.copyWith(entries: list);
  }

  @override
  Future<void> deleteEntry(String presetId, String modKey) async {
    final cur = items[presetId];
    if (cur == null) return;
    final list = cur.entries.where((e) => e.key != modKey).toList();
    items[presetId] = cur.copyWith(entries: list);
  }

  @override
  Future<void> updateEntryState(String presetId, String modKey, {bool? enabled, bool? favorite}) async {
    final cur = items[presetId];
    if (cur == null) return;
    final list = [...cur.entries];
    final i = list.indexWhere((e) => e.key == modKey);
    if (i < 0) return;
    final old = list[i];
    list[i] = old.copyWith(
      enabled: enabled ?? old.enabled,
      favorite: favorite ?? old.favorite,
      updatedAt: DateTime.now(),
    );
    items[presetId] = cur.copyWith(entries: list);
  }
}

class _ThrowingRepo implements IModPresetsRepository {
  final bool argError;
  _ThrowingRepo({required this.argError});
  @override
  Future<ModPreset?> findById(String id) async => throw StateError('boom');
  @override
  Future<List<ModPreset>> listAll() async => throw StateError('boom');
  @override
  Future<void> removeById(String id) async => throw StateError('boom');
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    if (argError) throw ArgumentError('bad');
    throw StateError('boom');
  }
  @override
  Future<void> upsert(ModPreset preset) async => throw StateError('boom');
  @override
  Future<void> upsertEntry(String presetId, ModEntry entry) async => throw StateError('boom');
  @override
  Future<void> deleteEntry(String presetId, String modKey) async => throw StateError('boom');
  @override
  Future<void> updateEntryState(String presetId, String modKey, {bool? enabled, bool? favorite}) async => throw StateError('boom');
}

class _StubEnv implements IsaacEnvironmentService {
  @override
  Future<Map<String, InstalledMod>> getInstalledModsMap() async => const {};

  @override
  Future<String?> detectOptionsIniPathAuto({List<String> fallbackCandidates = const []}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isValidInstallDir(String? dir) {
    throw UnimplementedError();
  }

  @override
  Future<LaunchEnvironment?> resolveEnvironment({String? optionsIniPathOverride, List<String> fallbackIniCandidates = const []}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveInstallPath() {
    throw UnimplementedError();
  }

  @override
  Future<InstallPathResolution> resolveInstallPathDetailed({String? installPathOverride}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveModsRoot() {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveOptionsIniPath({String? override, List<String> fallbackCandidates = const []}) {
    throw UnimplementedError();
  }
}