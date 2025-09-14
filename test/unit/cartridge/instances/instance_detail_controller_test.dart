import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

void main() {
  group('InstanceDetailController', () {
    late ProviderContainer container;
    late _StubInstancesService stub;

    setUp(() {
      stub = _StubInstancesService();
      container = ProviderContainer(overrides: [
        instancesServiceProvider.overrideWithValue(stub),
      ]);
      addTearDown(container.dispose);
    });

    test('빌드: Service에서 View 로드 후 sortKey/ascending 기준으로 정렬 반영', () async {
      final v = _view(
        id: 'inst',
        sortKey: InstanceSortKey.name,
        ascending: true,
        items: [
          _mv(id: 'b.mod', name: 'Bravo', enabled: false),
          _mv(id: 'a.mod', name: 'Alpha', enabled: false),
        ],
      );
      stub.views['inst'] = v;

      final built = await container.read(instanceDetailControllerProvider('inst').future);

      // 이름 오름차순 정렬 기대: Alpha, Bravo
      expect(built.items.map((e) => e.displayName).toList(), ['Alpha', 'Bravo']);
      expect(built.sortKey, InstanceSortKey.name);
      expect(built.ascending, isTrue);
    });

    test('mapCheckedToOverrideEnabled(): checked=false 이고 presetEnabled=true → false / presetEnabled=false → null', () async {
      final c = container.read(instanceDetailControllerProvider('x').notifier);
      expect(c.mapCheckedToOverrideEnabled(checked: false, presetEnabled: true), isFalse);
      expect(c.mapCheckedToOverrideEnabled(checked: false, presetEnabled: false), isNull);
      expect(c.mapCheckedToOverrideEnabled(checked: true, presetEnabled: false), isTrue);
    });

    test('setEnabled(): preset에 켜져있으면 false, 아니면 null 로 위임(checked=false)', () async {
      final v = _view(
        id: 'inst',
        items: [
          _mv(id: 'p.on', name: 'POn', enabled: true, enabledByPresets: {'p1'}),
          _mv(id: 'p.off', name: 'POff', enabled: false, enabledByPresets: const {}),
        ],
      );
      stub.views['inst'] = v;

      final notifier = container.read(instanceDetailControllerProvider('inst').notifier);

      // 1) presetEnabled = true, checked=false -> enabled=false 로 위임
      stub.nextViewAfterRefresh = v; // 리프레시 시 같은 뷰로 유지(호출만 검증)
      await notifier.setEnabled(v.items[0], false);
      expect(stub.lastSetItemStateKey, 'p.on');
      expect(stub.lastSetItemStateEnabled, isFalse); // false 위임

      // 2) presetEnabled = false, checked=false -> enabled=null 로 위임
      await notifier.setEnabled(v.items[1], false);
      expect(stub.lastSetItemStateKey, 'p.off');
      expect(stub.lastSetItemStateEnabled, isNull); // null 위임
    });

    test('toggleFavorite(): favorite 반전 위임 후 새로고침', () async {
      final v0 = _view(
        id: 'inst',
        items: [_mv(id: 'k', name: 'K', enabled: true, favorite: false)],
      );
      final v1 = v0.copyWith(
        items: [v0.items.first.copyWith(favorite: true)],
      );
      stub.views['inst'] = v0;
      stub.nextViewAfterRefresh = v1;

      final notifier = container.read(instanceDetailControllerProvider('inst').notifier);
      await notifier.toggleFavorite(v0.items.first);

      final fresh = container.read(instanceDetailControllerProvider('inst')).requireValue;
      expect(fresh.items.first.favorite, isTrue);
    });

    test('setOptionPreset(): 동일하면 no-op, 다르면 저장 후 상태 업데이트', () async {
      // 초기: optionPresetId = null
      final v0 = _view(id: 'inst', optionPresetId: null, items: const []);
      final v1 = v0.copyWith(optionPresetId: 'opt1');
      stub.views['inst'] = v0;

      final notifier = container.read(instanceDetailControllerProvider('inst').notifier);

      // 동일값 → no-op (호출 안함)
      await notifier.setOptionPreset(null);
      expect(stub.setOptionPresetCalls, isEmpty);

      // 변경 → 호출 + 리프레시 후 상태 변경
      stub.nextViewAfterRefresh = v1;
      await notifier.setOptionPreset('opt1');
      expect(stub.setOptionPresetCalls, ['inst:opt1']);

      final fresh = container.read(instanceDetailControllerProvider('inst')).requireValue;
      expect(fresh.optionPresetId, 'opt1');
    });

    test('setPresetIds(): 동일 서명이면 호출 안 함, 다르면 replace 호출 + 리프레시', () async {
      final labels = [
        AppliedPresetLabelView(presetId: 'p1', presetName: 'P1', isMandatory: false),
        AppliedPresetLabelView(presetId: 'p2', presetName: 'P2', isMandatory: true),
      ];
      final v0 = _view(id: 'inst', items: const [], applied: labels);
      stub.views['inst'] = v0;

      final notifier = container.read(instanceDetailControllerProvider('inst').notifier);

      // 동일 서명 -> 호출 안 함
      await notifier.setPresetIds([
        AppliedPresetRef(presetId: 'p1', isMandatory: false),
        AppliedPresetRef(presetId: 'p2', isMandatory: true),
      ]);
      expect(stub.replaceAppliedCalls, isEmpty);

      // 변경 서명 -> 호출 + 리프레시
      final changed = v0.copyWith(
        appliedPresets: [
          AppliedPresetLabelView(presetId: 'p2', presetName: 'P2', isMandatory: true),
          AppliedPresetLabelView(presetId: 'p1', presetName: 'P1', isMandatory: false),
        ],
      );
      stub.nextViewAfterRefresh = changed;

      await notifier.setPresetIds([
        AppliedPresetRef(presetId: 'p2', isMandatory: true),
        AppliedPresetRef(presetId: 'p1', isMandatory: false),
      ]);
      expect(stub.replaceAppliedCalls.single, 'inst:[p2:true,p1:false]');

      final fresh = container.read(instanceDetailControllerProvider('inst')).requireValue;
      expect(fresh.appliedPresets.map((e) => e.presetId).toList(), ['p2', 'p1']);
    });

    test('removeItem(): 삭제 위임 후 리프레시', () async {
      final v0 = _view(
        id: 'inst',
        items: [_mv(id: 'x', name: 'X', enabled: true)],
      );
      final v1 = v0.copyWith(items: const []);
      stub.views['inst'] = v0;
      stub.nextViewAfterRefresh = v1;

      final notifier = container.read(instanceDetailControllerProvider('inst').notifier);
      await notifier.removeItem(v0.items.first);

      expect(stub.deleteItemCalls.single, 'inst:x');
      final fresh = container.read(instanceDetailControllerProvider('inst')).requireValue;
      expect(fresh.items, isEmpty);
    });
  });
}

/// ───────────────────────── helpers / stubs ─────────────────────────

InstanceView _view({
  required String id,
  List<ModView> items = const [],
  String? optionPresetId,
  InstanceSortKey sortKey = InstanceSortKey.name,
  bool ascending = true,
  List<AppliedPresetLabelView> applied = const [],
}) {
  return InstanceView(
    id: id,
    name: 'Inst',
    optionPresetId: optionPresetId,
    items: items,
    totalCount: items.length,
    enabledCount: items.where((e) => e.effectiveEnabled).length,
    missingCount: items.where((e) => !e.isInstalled).length,
    sortKey: sortKey,
    ascending: ascending,
    gameMode: GameMode.normal,
    updatedAt: null,
    lastSyncAt: null,
    group: null,
    categories: const [],
    appliedPresets: applied,
    image: null,
  );
}

ModView _mv({
  required String id,
  required String name,
  required bool enabled,
  bool favorite = false,
  Set<String> enabledByPresets = const <String>{},
}) {
  return ModView(
    id: id,
    isInstalled: true,
    explicitEnabled: enabled,
    effectiveEnabled: enabled,
    favorite: favorite,
    displayName: name,
    installedRef: InstalledMod(
      metadata: ModMetadata(
        id: '', // 로컬 모드도 허용
        name: name,
        directory: id,
        version: '1.0',
        visibility: ModVisibility.public,
        tags: const <String>[],
      ),
      disabled: !enabled,
    ),
    status: ModRowStatus.ok,
    enabledByPresets: enabledByPresets,
    updatedAt: DateTime.now(),
  );
}

class _StubInstancesService extends InstancesService {
  _StubInstancesService()
      : super(
    repo: _NoRepo(),
    envService: _NoEnv(),
    optionPresetsService: _NoOptSvc(),
    modPresetsService: _NoModSvc(),
  );

  final Map<String, InstanceView> views = {};
  InstanceView? nextViewAfterRefresh;

  // call records
  String? lastSetItemStateKey;
  bool? lastSetItemStateEnabled;
  bool lastSetItemStateFavorite = false;

  final List<String> setOptionPresetCalls = [];
  final List<String> replaceAppliedCalls = [];
  final List<String> deleteItemCalls = [];

  // ── overrides used by controller ──
  @override
  Future<InstanceView?> getViewById(String id, {Map<String, InstalledMod>? installedOverride, String? modsRootOverride}) async {
    return views[id];
  }

  @override
  Future<Result<Instance?>> setItemState({
    required String instanceId,
    required ModView item,
    bool? enabled,
    bool? favorite,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    lastSetItemStateKey = item.id;
    lastSetItemStateEnabled = enabled;
    lastSetItemStateFavorite = favorite ?? false;
    // 컨트롤러는 결과값은 무시하고, 이후 _refresh()에서 getViewById를 부르므로
    if (nextViewAfterRefresh != null) {
      views[instanceId] = nextViewAfterRefresh!;
    }
    return const Result.ok(code: 'instance.item.setState.ok');
  }

  @override
  Future<void> deleteItem({required String instanceId, required String itemId}) async {
    deleteItemCalls.add('$instanceId:$itemId');
    if (nextViewAfterRefresh != null) {
      views[instanceId] = nextViewAfterRefresh!;
    }
  }

  @override
  Future<Result<Instance?>> setOptionPreset(String instanceId, String? optionPresetId) async {
    setOptionPresetCalls.add('$instanceId:${optionPresetId ?? 'null'}');
    if (nextViewAfterRefresh != null) {
      views[instanceId] = nextViewAfterRefresh!;
    }
    // 컨트롤러는 updatedAt만 사용 → dummy Instance 반환
    final dummy = Instance(
      id: instanceId,
      name: 'dummy',
      optionPresetId: optionPresetId,
      appliedPresets: const [],
      gameMode: GameMode.normal,
      overrides: const [],
      image: null,
      sortKey: InstanceSortKey.name,
      ascending: true,
      updatedAt: DateTime.now(),
      lastSyncAt: null,
      group: null,
      categories: const [],
    );
    return Result.ok(data: dummy, code: 'instance.setOptionPreset.ok');
  }

  @override
  Future<Instance?> replaceAppliedPresets({
    required String instanceId,
    required List<AppliedPresetRef> refs,
  }) async {
    replaceAppliedCalls.add('$instanceId:[${refs.map((e) => '${e.presetId}:${e.isMandatory}').join(',')}]');
    if (nextViewAfterRefresh != null) {
      views[instanceId] = nextViewAfterRefresh!;
    }
    return Instance(
      id: instanceId,
      name: 'dummy',
      optionPresetId: null,
      appliedPresets: refs,
      gameMode: GameMode.normal,
      overrides: const [],
      image: null,
      sortKey: InstanceSortKey.name,
      ascending: true,
      updatedAt: DateTime.now(),
      lastSyncAt: null,
      group: null,
      categories: const [],
    );
  }
}

// 최소 더미 의존성들
class _NoRepo implements IInstancesRepository {
  @override
  Future<Instance?> findById(String id) async => null;
  @override
  Future<List<Instance>> listAll() async => const [];
  @override
  Future<void> removeById(String id) async {}
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {}
  @override
  Future<void> upsert(Instance i) async {}
}

class _NoEnv implements IsaacEnvironmentService {
  @override
  Future<Map<String, InstalledMod>> getInstalledModsMap() async => const {};
  @override
  Future<String?> detectOptionsIniPathAuto({List<String> fallbackCandidates = const []}) => throw UnimplementedError();
  @override
  Future<bool> isValidInstallDir(String? dir) => throw UnimplementedError();
  @override
  Future<LaunchEnvironment?> resolveEnvironment({String? optionsIniPathOverride, List<String> fallbackIniCandidates = const []}) => throw UnimplementedError();
  @override
  Future<String?> resolveInstallPath() => throw UnimplementedError();
  @override
  Future<InstallPathResolution> resolveInstallPathDetailed({String? installPathOverride}) => throw UnimplementedError();
  @override
  Future<String?> resolveModsRoot() => throw UnimplementedError();
  @override
  Future<String?> resolveOptionsIniPath({String? override, List<String> fallbackCandidates = const []}) => throw UnimplementedError();
}

class _NoOptSvc extends OptionPresetsService {
  _NoOptSvc() : super(repo: _NoOptRepo());
}

class _NoOptRepo implements IOptionPresetsRepository {
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

class _NoModSvc extends ModPresetsService {
  _NoModSvc() : super(repository: _NoModRepo(), envService: _NoEnv());
}

class _NoModRepo implements IModPresetsRepository {
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
