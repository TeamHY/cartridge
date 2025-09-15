
import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/option_presets/data/i_option_presets_repository.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset_view.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/option_presets_service.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OptionPresetsService', () {
    late _MemRepo repo;
    late OptionPresetsService sut;

    setUp(() {
      repo = _MemRepo();
      sut = OptionPresetsService(repo: repo);
    });

    // ── Queries ────────────────────────────────────────────────────────────
    test('listAllViews(): pos ASC 순서 유지', () async {
      // Given
      repo.seed([
        OptionPreset(id: 'b', name: 'Bravo', useRepentogon: true, options: IsaacOptions.fromJson({})),
        OptionPreset(id: 'a', name: 'Alpha', useRepentogon: false, options: IsaacOptions.fromJson({})),
        OptionPreset(id: 'c', name: 'Charlie', useRepentogon: null, options: IsaacOptions.fromJson({})),
      ], order: const ['a', 'c', 'b']);

      // When
      final views = await sut.listAllViews();

      // Then
      expect(views.map((e) => e.id).toList(), ['a', 'c', 'b']);
    });

    test('getViewById()/getById(): 존재 시 반환, 없으면 null', () async {
      // Given
      final p = OptionPreset(id: 'x', name: 'X', useRepentogon: true, options: IsaacOptions.fromJson({}));
      repo.seed([p], order: const ['x']);

      // When
      final v = await sut.getViewById('x');
      final m = await sut.getById('x');
      final no = await sut.getViewById('nope');

      // Then
      expect(v, isA<OptionPresetView>());
      expect(m, isA<OptionPreset>());
      expect(v!.id, 'x');
      expect(m!.id, 'x');
      expect(no, isNull);
    });

    // ── Commands: create/update/delete/clone ───────────────────────────────
    test('createView(): 정상 입력 → Result.ok + 저장', () async {
      // When
      final res = await sut.createView(
        name: '  New  ',
        windowWidth: 1280,
        useRepentogon: true,
      );

      // Then
      res.map(
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'optionPreset.create.ok');
          expect(repo.items.length, 1);
          final saved = repo.items.values.single;
          expect(saved.name, 'New'); // trim 적용
          expect(saved.options.windowWidth, 1280);
          expect(saved.useRepentogon, isTrue);
        },
      );
    });

    test('updateView(): notFound → Result.notFound', () async {
      final res = await sut.updateView('nope', name: 'X');
      res.map(
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
        notFound: (r) => expect(r.code, 'optionPreset.update.notFound'),
      );
    });

    test('updateView(): 일부 필드 변경 → Result.ok, pos 유지', () async {
      // Given
      final orig = OptionPreset(
        id: 'a',
        name: 'Old',
        useRepentogon: false,
        options: IsaacOptions.fromJson({'WindowWidth': 640}),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1),
      );
      repo.seed([orig], order: const ['a']);

      // When
      final res = await sut.updateView('a', name: '  New ', windowWidth: 1920, useRepentogon: true);

      // Then
      res.map(
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'optionPreset.update.ok');
          final saved = repo.items['a']!;
          expect(saved.name, 'New');
          expect(saved.options.windowWidth, 1920);
          expect(saved.useRepentogon, isTrue);
          // pos 유지 확인
          expect(repo.order, ['a']);
          // updatedAt 갱신(정확한 시간 비교 대신 null 아님만 확인)
          expect(saved.updatedAt, isNotNull);
          expect(saved.updatedAt!.millisecondsSinceEpoch, greaterThan(1));
        },
      );
    });

    test('cloneView(): notFound → Result.notFound', () async {
      final res = await sut.cloneView('ghost', duplicateSuffix: '(copy)');
      res.map(
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
        notFound: (r) => expect(r.code, 'optionPreset.clone.notFound'),
      );
    });

    test('cloneView(): 정상 → 새 id 저장 + 이름 suffix 반영', () async {
      // Given
      final base = OptionPreset(
        id: 'base',
        name: 'Base',
        useRepentogon: null,
        options: IsaacOptions.fromJson({'WindowWidth': 800}),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1),
      );
      repo.seed([base], order: const ['base']);

      // When
      final res = await sut.cloneView('base', duplicateSuffix: '(copy)');

      // Then
      res.map(
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'optionPreset.clone.ok');
          expect(repo.items.length, 2);
          // 새 id가 추가되었고, 이름은 suffix 포함
          final ids = repo.items.keys.toList();
          expect(ids.contains('base'), isTrue);
          final cloneId = ids.firstWhere((id) => id != 'base');
          expect(repo.items[cloneId]!.name, 'Base (copy)');
          // pos는 맨 뒤로(append)
          expect(repo.order.last, cloneId);
        },
      );
    });

    test('deleteView(): 존재하지 않으면 notFound, 존재하면 ok', () async {
      // Given
      final p = OptionPreset(id: 'a', name: 'A', useRepentogon: true, options: IsaacOptions.fromJson({}));
      repo.seed([p], order: const ['a']);

      // When/Then notFound
      final r1 = await sut.deleteView('ghost');
      r1.map(
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
        notFound: (r) => expect(r.code, 'optionPreset.delete.notFound'),
      );

      // When OK
      final r2 = await sut.deleteView('a');
      r2.map(
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'optionPreset.delete.ok');
          expect(repo.items.containsKey('a'), isFalse);
          expect(repo.order.contains('a'), isFalse);
        },
      );
    });

    // ── Sorting ────────────────────────────────────────────────────────────
    test('reorderOptionPresets(): strict=true 정상 재배치 → Result.ok', () async {
      // Given
      repo.seed([
        OptionPreset(id: 'a', name: 'A', useRepentogon: true, options: IsaacOptions.fromJson({})),
        OptionPreset(id: 'b', name: 'B', useRepentogon: false, options: IsaacOptions.fromJson({})),
        OptionPreset(id: 'c', name: 'C', useRepentogon: null, options: IsaacOptions.fromJson({})),
      ], order: const ['a', 'b', 'c']);

      // When
      final res = await sut.reorderOptionPresets(['b', 'c', 'a'], strict: true);

      // Then
      res.map(
        invalid: (_) => fail('expected ok'),
        notFound: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (r) {
          expect(r.code, 'optionPreset.reorder.ok');
          expect(repo.order, ['b', 'c', 'a']);
        },
      );
    });

    test('reorderOptionPresets(): strict=true에서 permutation 아니면 failure(code invalid)', () async {
      // Given
      repo.seed([
        OptionPreset(id: 'a', name: 'A', useRepentogon: true, options: IsaacOptions.fromJson({})),
        OptionPreset(id: 'b', name: 'B', useRepentogon: false, options: IsaacOptions.fromJson({})),
      ], order: const ['a', 'b']);

      // When
      final res = await sut.reorderOptionPresets(['a', 'ghost'], strict: true);

      // Then
      res.map(
        ok: (_) => fail('expected failure.invalid'),
        invalid: (_) => fail('expected failure.invalid'),
        notFound: (_) => fail('expected failure.invalid'),
        conflict: (_) => fail('expected failure.invalid'),
        failure: (r) => expect(r.code, 'optionPreset.reorder.invalid'),
      );
    });

    test('reorderOptionPresets(): 예기치 못한 예외 → failure(code failure)', () async {
      // Given repo가 항상 throw
      final bad = _ThrowingRepo();
      final s2 = OptionPresetsService(repo: bad);

      // When
      final res = await s2.reorderOptionPresets(['a']);

      // Then
      res.map(
        ok: (_) => fail('expected failure'),
        invalid: (_) => fail('expected failure'),
        notFound: (_) => fail('expected failure'),
        conflict: (_) => fail('expected failure'),
        failure: (r) => expect(r.code, 'optionPreset.reorder.failure'),
      );
    });
  });
}

// ── Test Doubles (in-memory) ───────────────────────────────────────────────────────────
class _MemRepo implements IOptionPresetsRepository {
  final Map<String, OptionPreset> items = {};
  final List<String> order = [];

  void seed(List<OptionPreset> list, {required List<String> order}) {
    items
      ..clear()
      ..addEntries(list.map((e) => MapEntry(e.id, e)));
    this.order
      ..clear()
      ..addAll(order);
  }

  @override
  Future<OptionPreset?> findById(String id) async => items[id];

  @override
  Future<List<OptionPreset>> listAll() async => order.map((id) => items[id]!).toList();

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
  Future<void> upsert(OptionPreset preset) async {
    final exists = items.containsKey(preset.id);
    items[preset.id] = preset;
    if (!exists) order.add(preset.id);
  }
}

class _ThrowingRepo implements IOptionPresetsRepository {
  @override
  Future<OptionPreset?> findById(String id) async => throw StateError('boom');
  @override
  Future<List<OptionPreset>> listAll() async => throw StateError('boom');
  @override
  Future<void> removeById(String id) async => throw StateError('boom');
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async => throw StateError('boom');
  @override
  Future<void> upsert(OptionPreset preset) async => throw StateError('boom');
}
