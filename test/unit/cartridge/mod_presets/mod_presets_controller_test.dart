
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_environment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModPresetsController', () {
    late ProviderContainer container;
    late _StubService svc;

    setUp(() async {
      svc = _StubService();
      svc.items = [
        ModPresetView(key: 'a', name: 'Alpha', items: const [], totalCount: 0, enabledCount: 0),
        ModPresetView(key: 'b', name: 'Beta',  items: const [], totalCount: 0, enabledCount: 0),
        ModPresetView(key: 'c', name: 'Gamma', items: const [], totalCount: 0, enabledCount: 0),
      ];
      container = ProviderContainer(overrides: [
        modPresetsServiceProvider.overrideWithValue(svc),
      ]);
    });

    tearDown(() => container.dispose());

    test('build(): listAllViews OK → AsyncData(List)', () async {
      // When
      final list = await container.read(modPresetsControllerProvider.future);

      // Then
      expect(list.map((e) => e.key).toList(), ['a', 'b', 'c']);
      final state = container.read(modPresetsControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.length, 3);
    });

    test('modPresetByIdProvider: id로 단건 조회, 없으면 null', () async {
      await container.read(modPresetsControllerProvider.future);
      final v = container.read(modPresetByIdProvider('b'));
      expect(v!.name, 'Beta');
      final none = container.read(modPresetByIdProvider('x'));
      expect(none, isNull);
    });

    test('refresh(): 강제 새로고침 → 최신 목록 반영', () async {
      await container.read(modPresetsControllerProvider.future);
      // Given: 서비스에 새 항목 추가
      svc.items.add(ModPresetView(key: 'd', name: 'Delta', items: const [], totalCount: 0, enabledCount: 0));

      // When
      await container.read(modPresetsControllerProvider.notifier).refresh();

      // Then
      final list = container.read(modPresetsControllerProvider).value!;
      expect(list.map((e) => e.key).toList(), ['a', 'b', 'c', 'd']);
    });

    test('create(): Result.ok → refresh 수행', () async {
      await container.read(modPresetsControllerProvider.future);

      final res = await container.read(modPresetsControllerProvider.notifier).create(name: 'New');
      res.map(
        ok: (_) => expect(true, isTrue),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      final list = container.read(modPresetsControllerProvider).value!;
      expect(list.any((e) => e.name == 'New'), isTrue);
      expect(svc.createdNames.last, 'New');
    });

    test('clone(): Result.ok → refresh, notFound면 refresh 없음', () async {
      await container.read(modPresetsControllerProvider.future);

      // OK
      final beforeOk = svc.listCalls;
      final resOk = await container.read(modPresetsControllerProvider.notifier).clone('a', duplicateSuffix: '(copy)');
      resOk.map(
        ok: (_) => expect(true, isTrue),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      expect(svc.listCalls, greaterThan(beforeOk));
      final afterOk = container.read(modPresetsControllerProvider).value!;
      expect(afterOk.any((e) => e.name == 'Alpha (copy)'), isTrue);

      // notFound
      svc.cloneNotFound = true;
      final beforeBad = svc.listCalls;
      final resBad = await container.read(modPresetsControllerProvider.notifier).clone('ghost', duplicateSuffix: '(copy)');
      resBad.map(
        notFound: (_) => expect(true, isTrue),
        ok: (_) => fail('expected notFound'),
        invalid: (_) => fail('expected notFound'),
        conflict: (_) => fail('expected notFound'),
        failure: (_) => fail('expected notFound'),
      );
      expect(svc.listCalls, beforeBad); // refresh 없음
    });

    test('remove(): Result.ok → refresh', () async {
      await container.read(modPresetsControllerProvider.future);

      final res = await container.read(modPresetsControllerProvider.notifier).remove('b');
      res.map(
        ok: (_) => expect(true, isTrue),
        notFound: (_) => fail('expected ok'),
        invalid: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
      final list = container.read(modPresetsControllerProvider).value!;
      expect(list.map((e) => e.key).toList(), ['a', 'c']);
      expect(svc.deletedIds.last, 'b');
    });

    test('reorderModPresets(): ok면 refresh, failure면 refresh 없음', () async {
      await container.read(modPresetsControllerProvider.future);
      final before = svc.listCalls;

      // OK
      final r1 = await container.read(modPresetsControllerProvider.notifier).reorderModPresets(['c', 'a', 'b']);
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
      final r2 = await container.read(modPresetsControllerProvider.notifier).reorderModPresets(['a', 'b', 'c']);
      r2.map(
        failure: (_) => expect(true, isTrue),
        ok: (_) => fail('expected failure'),
        invalid: (_) => fail('expected failure'),
        notFound: (_) => fail('expected failure'),
        conflict: (_) => fail('expected failure'),
      );
      expect(svc.listCalls, before2); // refresh 없음
    });
  });

  group('UI Provider', () {
    late ProviderContainer container;
    late _StubService svc;

    setUp(() async {
      svc = _StubService();
      svc.items = [
        ModPresetView(key: 'a', name: 'Alpha', items: const [], totalCount: 0, enabledCount: 0),
        ModPresetView(key: 'b', name: 'Beta',  items: const [], totalCount: 0, enabledCount: 0),
        ModPresetView(key: 'c', name: 'Gamma', items: const [], totalCount: 0, enabledCount: 0),
      ];
      container = ProviderContainer(overrides: [
        modPresetsServiceProvider.overrideWithValue(svc),
      ]);
      await container.read(modPresetsControllerProvider.future);
    });

    tearDown(() => container.dispose());

    test('filteredModPresetsProvider: 쿼리로 필터(부분 일치, lower-case)', () async {
      container.read(modPresetsQueryProvider.notifier).state = 'a';
      final filtered = container.read(filteredModPresetsProvider).value!;
      expect(filtered.map((e) => e.name).toList(), containsAll(['Alpha', 'Gamma']));
    });

    test('ModPresetsWorkingOrder: syncFrom/move/setAll/reset 동작', () async {
      final wo = container.read(modPresetsWorkingOrderProvider.notifier);
      wo.syncFrom(container.read(modPresetsControllerProvider).value!);
      expect(container.read(modPresetsWorkingOrderProvider), ['a', 'b', 'c']);

      wo.move(0, 2); // a -> 끝으로
      expect(container.read(modPresetsWorkingOrderProvider), ['b', 'c', 'a']);

      wo.setAll(const ['c', 'b', 'a']);
      expect(container.read(modPresetsWorkingOrderProvider), ['c', 'b', 'a']);

      wo.reset();
      expect(container.read(modPresetsWorkingOrderProvider), isEmpty);
    });

    test('orderedModPresetsForUiProvider: reorder 모드에서 working order 적용', () async {
      // 기본: reorder 모드 off
      final base = container.read(orderedModPresetsForUiProvider).value!;
      expect(base.map((e) => e.key).toList(), ['a', 'b', 'c']);

      // reorder on + working order 설정
      container.read(modPresetsReorderModeProvider.notifier).state = true;
      container.read(modPresetsWorkingOrderProvider.notifier).setAll(const ['c', 'a', 'b']);
      final ordered = container.read(orderedModPresetsForUiProvider).value!;
      expect(ordered.map((e) => e.key).toList(), ['c', 'a', 'b']);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Stub Service
// ─────────────────────────────────────────────────────────────────────────────
class _StubService extends ModPresetsService {
  _StubService() : super(repository: _NoopRepo(), envService: _NoEnv());

  List<ModPresetView> items = [];
  List<String> order = [];
  int listCalls = 0;
  final List<String> createdNames = [];
  final List<String> deletedIds = [];
  bool cloneNotFound = false;
  bool reorderShouldFail = false;

  @override
  Future<List<ModPresetView>> listAllViews({Map<String, InstalledMod>? installedOverride, String? modsRootOverride}) async {
    listCalls += 1;
    order = items.map((e) => e.key).toList();
    return List.unmodifiable(items);
  }

  @override
  Future<Result<ModPresetView>> create({
    required String name,
    required SeedMode seedMode,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
    ModSortKey? sortKey,
    bool? ascending,
  }) async {
    createdNames.add(name.trim());
    final id = name.trim().isEmpty ? 'new' : name.trim().toLowerCase();
    final v = ModPresetView(key: id, name: name.trim(), items: const [], totalCount: 0, enabledCount: 0);
    items.add(v);
    return Result.ok(data: v, code: 'modPreset.create.ok');
  }

  @override
  Future<Result<ModPresetView>> clone({
    required String sourceId,
    required String duplicateSuffix,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    if (cloneNotFound) return const Result.notFound(code: 'modPreset.clone.notFound');
    final src = items.firstWhere((e) => e.key == sourceId);
    final v = ModPresetView(key: '${src.key}_copy', name: '${src.name} $duplicateSuffix', items: const [], totalCount: 0, enabledCount: 0);
    items.add(v);
    return Result.ok(data: v, code: 'modPreset.clone.ok');
  }

  @override
  Future<Result<void>> delete(String presetId) async {
    deletedIds.add(presetId);
    items.removeWhere((e) => e.key == presetId);
    return const Result.ok(code: 'modPreset.delete.ok');
  }

  @override
  Future<Result<void>> reorderModPresets(List<String> orderedIds, {bool strict = true}) async {
    if (reorderShouldFail) return const Result.failure(code: 'modPreset.reorder.failure');
    final map = {for (final v in items) v.key: v};
    items = orderedIds.map((id) => map[id]!).toList();
    order = orderedIds;
    return const Result.ok(code: 'modPreset.reorder.ok');
  }
}

class _NoopRepo implements IModPresetsRepository {
  @override
  Future<ModPreset?> findById(String id) async => null;
  @override
  Future<List<ModPreset>> listAll() async => const [];
  @override
  Future<void> removeById(String id) async {}
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {}
  @override
  Future<void> upsert(ModPreset preset) async {}
  @override
  Future<void> upsertEntry(String presetId, ModEntry entry) async {}
  @override
  Future<void> deleteEntry(String presetId, String modKey) async {}
  @override
  Future<void> updateEntryState(String presetId, String modKey, {bool? enabled, bool? favorite}) async {}
}

class _NoEnv implements IsaacEnvironmentService {
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
