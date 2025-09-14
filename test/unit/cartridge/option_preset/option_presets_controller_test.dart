import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OptionPresetsController', () {
    late ProviderContainer container;
    late _StubService svc;

    setUp(() async {
      svc = _StubService();
      svc.items = [
        OptionPresetView(id: 'a', name: 'Alpha'),
        OptionPresetView(id: 'b', name: 'Beta'),
        OptionPresetView(id: 'c', name: 'Gamma'),
      ];
      container = ProviderContainer(overrides: [
        optionPresetsServiceProvider.overrideWithValue(svc),
        // repentogonInstalledProvider는 Future<bool>이라 가정하고 true 고정
        repentogonInstalledProvider.overrideWith((ref) async => true),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('build(): listAllViews OK → AsyncData(List)', () async {
      // When
      final list = await container.read(optionPresetsControllerProvider.future);

      // Then
      expect(list.map((e) => e.id).toList(), ['a', 'b', 'c']);
      final state = container.read(optionPresetsControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.length, 3);
    });

    test('optionPresetByIdProvider: id로 단건 조회, 없으면 null', () async {
      await container.read(optionPresetsControllerProvider.future);
      final v = container.read(optionPresetByIdProvider('b'));
      expect(v!.name, 'Beta');
      final none = container.read(optionPresetByIdProvider('x'));
      expect(none, isNull);
    });

    test('refresh(): 강제 새로고침 → 최신 목록 반영', () async {
      await container.read(optionPresetsControllerProvider.future);
      // Given: 서비스에 새 항목 추가
      svc.items.add(OptionPresetView(id: 'd', name: 'Delta'));

      // When
      await container.read(optionPresetsControllerProvider.notifier).refresh();

      // Then
      final list = container.read(optionPresetsControllerProvider).value!;
      expect(list.map((e) => e.id), ['a', 'b', 'c', 'd']);
    });

    test('create(): 생성 후 listAllViews로 state 갱신', () async {
      await container.read(optionPresetsControllerProvider.future);

      // When
      await container.read(optionPresetsControllerProvider.notifier).create(
        OptionPresetView(id: '', name: 'New'),
      );

      // Then
      final list = container.read(optionPresetsControllerProvider).value!;
      expect(list.any((e) => e.name == 'New'), isTrue);
      expect(svc.createdNames.last, 'New');
    });

    test('fetch(): 업데이트 후 listAllViews로 state 갱신', () async {
      await container.read(optionPresetsControllerProvider.future);

      // When: id=b 이름을 New로 변경 요청
      await container.read(optionPresetsControllerProvider.notifier).fetch(
        OptionPresetView(id: 'b', name: 'New'),
      );

      // Then
      final list = container.read(optionPresetsControllerProvider).value!;
      expect(list.firstWhere((e) => e.id == 'b').name, 'New');
      expect(svc.updatedIds.last, 'b');
    });

    test('remove(): 삭제 후 refresh 호출', () async {
      await container.read(optionPresetsControllerProvider.future);

      // When
      await container.read(optionPresetsControllerProvider.notifier).remove('b');

      // Then
      final list = container.read(optionPresetsControllerProvider).value!;
      expect(list.map((e) => e.id).toList(), ['a', 'c']);
      expect(svc.deletedIds.last, 'b');
    });

    test('clone(): Result.ok → refresh 수행, notFound면 refresh 없음', () async {
      await container.read(optionPresetsControllerProvider.future);

      // OK 케이스
      final resOk = await container
          .read(optionPresetsControllerProvider.notifier)
          .clone('a', '(copy)');
      resOk.map(
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
        ok: (_) => expect(true, isTrue),
      );
      // 복제되었는지 확인
      final afterOk = container.read(optionPresetsControllerProvider).value!;
      expect(afterOk.length, 4);
      expect(afterOk.any((e) => e.name == 'Alpha (copy)'), isTrue);

      // notFound 케이스
      svc.cloneNotFound = true;
      final beforeCount = svc.listCalls;
      final resBad = await container
          .read(optionPresetsControllerProvider.notifier)
          .clone('ghost', '(copy)');
      resBad.map(
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
        notFound: (_) => expect(true, isTrue),
      );
      // refresh(listAllViews) 추가 호출이 없어야 함
      expect(svc.listCalls, beforeCount);
    });

    test('reorderOptionPresets(): ok면 refresh, failure면 refresh 없음', () async {
      await container.read(optionPresetsControllerProvider.future);
      final before = svc.listCalls;

      // OK
      final r1 = await container
          .read(optionPresetsControllerProvider.notifier)
          .reorderOptionPresets(['c', 'a', 'b']);
      r1.map(
        ok: (_) => expect(true, isTrue),
        invalid: (_) => fail('expected ok'),
        notFound: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      expect(svc.order, ['c', 'a', 'b']);
      expect(svc.listCalls, greaterThan(before));

      // Failure
      svc.reorderShouldFail = true;
      final before2 = svc.listCalls;
      final r2 = await container
          .read(optionPresetsControllerProvider.notifier)
          .reorderOptionPresets(['a', 'b', 'c']);
      r2.map(
        failure: (_) => expect(true, isTrue),
        ok: (_) => fail('expected failure'),
        invalid: (_) => fail('expected failure'),
        notFound: (_) => fail('expected failure'),
        conflict: (_) => fail('expected failure'),
      );
      expect(svc.listCalls, before2); // refresh 없음
    });

    test('isRepentogonInstalled(): Provider override로 true 반환', () async {
      final ok = await container.read(optionPresetsControllerProvider.notifier).isRepentogonInstalled();
      expect(ok, isTrue);
    });
  });

  group('UI용 Provider', () {
    late ProviderContainer container;
    late _StubService svc;

    setUp(() async {
      svc = _StubService();
      svc.items = [
        OptionPresetView(id: 'a', name: 'Alpha'),
        OptionPresetView(id: 'b', name: 'Beta'),
        OptionPresetView(id: 'c', name: 'Gamma'),
      ];
      container = ProviderContainer(overrides: [
        optionPresetsServiceProvider.overrideWithValue(svc),
      ]);
      await container.read(optionPresetsControllerProvider.future);
    });

    tearDown(() => container.dispose());

    test('filteredOptionPresetsProvider: 쿼리로 필터(부분 일치, lower-case)', () async {
      container.read(optionPresetsQueryProvider.notifier).state = 'a';
      final filtered = container.read(filteredOptionPresetsProvider).value!;
      expect(filtered.map((e) => e.name).toList(), containsAll(['Alpha', 'Gamma']));
    });

    test('OptionPresetsWorkingOrder: syncFrom/move/setAll/reset 동작', () async {
      final wo = container.read(optionPresetsWorkingOrderProvider.notifier);
      wo.syncFrom(container.read(optionPresetsControllerProvider).value!);
      expect(container.read(optionPresetsWorkingOrderProvider), ['a', 'b', 'c']);

      wo.move(0, 2); // a -> 끝으로
      expect(container.read(optionPresetsWorkingOrderProvider), ['b', 'c', 'a']);

      wo.setAll(const ['c', 'b', 'a']);
      expect(container.read(optionPresetsWorkingOrderProvider), ['c', 'b', 'a']);

      wo.reset();
      expect(container.read(optionPresetsWorkingOrderProvider), isEmpty);
    });

    test('orderedOptionPresetsForUiProvider: reorder 모드에서 working order 적용', () async {
      // 기본: reorder 모드 off
      final base = container.read(orderedOptionPresetsForUiProvider).value!;
      expect(base.map((e) => e.id).toList(), ['a', 'b', 'c']);

      // reorder on + working order 설정
      container.read(optionPresetsReorderModeProvider.notifier).state = true;
      container.read(optionPresetsWorkingOrderProvider.notifier).setAll(const ['c', 'a', 'b']);
      final ordered = container.read(orderedOptionPresetsForUiProvider).value!;
      expect(ordered.map((e) => e.id).toList(), ['c', 'a', 'b']);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Stub Service
// ─────────────────────────────────────────────────────────────────────────────
class _StubService extends OptionPresetsService {
  _StubService() : super(repo: _NoopRepo());

  List<OptionPresetView> items = [];
  List<String> order = [];
  int listCalls = 0;
  final List<String> createdNames = [];
  final List<String> updatedIds = [];
  final List<String> deletedIds = [];
  bool cloneNotFound = false;
  bool reorderShouldFail = false;

  @override
  Future<List<OptionPresetView>> listAllViews() async {
    listCalls += 1;
    order = items.map((e) => e.id).toList();
    return List.unmodifiable(items);
  }

  @override
  Future<Result<OptionPresetView>> createView({
    required String name,
    int? windowWidth,
    int? windowHeight,
    int? windowPosX,
    int? windowPosY,
    bool? fullscreen,
    double? gamma,
    bool? enableDebugConsole,
    bool? pauseOnFocusLost,
    bool? mouseControl,
    bool? useRepentogon,
  }) async {
    createdNames.add(name.trim());
    final id = name.trim().isEmpty ? 'new' : name.trim().toLowerCase();
    items.add(OptionPresetView(id: id, name: name.trim()));
    return Result.ok(data: OptionPresetView(id: id, name: name.trim()), code: 'optionPreset.create.ok');
  }

  @override
  Future<Result<OptionPresetView>> updateView(
      String id, {
        String? name,
        int? windowWidth,
        int? windowHeight,
        int? windowPosX,
        int? windowPosY,
        bool? fullscreen,
        double? gamma,
        bool? enableDebugConsole,
        bool? pauseOnFocusLost,
        bool? mouseControl,
        bool? useRepentogon,
      }) async {
    updatedIds.add(id);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx >= 0 && name != null) {
      items[idx] = OptionPresetView(id: id, name: name);
    }
    return Result.ok(data: items[idx], code: 'optionPreset.update.ok');
  }

  @override
  Future<Result<void>> deleteView(String id) async {
    deletedIds.add(id);
    items.removeWhere((e) => e.id == id);
    return const Result.ok(code: 'optionPreset.delete.ok');
  }

  @override
  Future<Result<OptionPresetView>> cloneView(String sourceId, {required String duplicateSuffix}) async {
    if (cloneNotFound) return const Result.notFound(code: 'optionPreset.clone.notFound');
    final src = items.firstWhere((e) => e.id == sourceId);
    final cloned = OptionPresetView(id: '${src.id}_copy', name: '${src.name} $duplicateSuffix');
    items.add(cloned);
    return Result.ok(data: cloned, code: 'optionPreset.clone.ok');
  }

  @override
  Future<Result<void>> reorderOptionPresets(List<String> orderedIds, {bool strict = true}) async {
    if (reorderShouldFail) return const Result.failure(code: 'optionPreset.reorder.failure');
    final map = {for (final v in items) v.id: v};
    items = orderedIds.map((id) => map[id]!).toList();
    order = orderedIds;
    return const Result.ok(code: 'optionPreset.reorder.ok');
  }
}

class _NoopRepo implements IOptionPresetsRepository {
  @override
  Future<OptionPreset?> findById(String id) async => null;
  @override
  Future<List<OptionPreset>> listAll() async => const [];
  @override
  Future<void> removeById(String id) async {}
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {}
  @override
  Future<void> upsert(OptionPreset preset) async {}
}
