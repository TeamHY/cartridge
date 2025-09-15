import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

// ── Tests ───────────────────────────────────────────────────────────
void main() {
  group('InstancesController', () {
    late ProviderContainer container;
    late _StubInstancesService stub;

    setUp(() async {
      stub = _StubInstancesService();
      // 초기 목록 2개 구성
      stub.views.addAll([
        _v('a', enabledCount: 1),
        _v('b', enabledCount: 3),
      ]);
      container = ProviderContainer(overrides: [
        instancesServiceProvider.overrideWithValue(stub),
      ]);
      addTearDown(container.dispose);
    });

    test('build(): listAllViews 결과를 상태로 노출', () async {
      final list = await container.read(instancesControllerProvider.future);
      expect(list.map((e) => e.id).toList(), ['a', 'b']);
      expect(stub.listAllCalls, 1);
    });

    test('refresh(): 목록을 다시 불러온다', () async {
      // 초기 빌드
      await container.read(instancesControllerProvider.future);
      expect(stub.listAllCalls, 1);

      // 원본 데이터 변경
      stub.views
        ..clear()
        ..addAll([_v('x'), _v('y'), _v('z')]);

      // 새로고침
      await container.read(instancesControllerProvider.notifier).refresh();
      final list = container.read(instancesControllerProvider).requireValue;
      expect(list.map((e) => e.id).toList(), ['x', 'y', 'z']);
      expect(stub.listAllCalls, 2);
    });

    test('createInstance(): Result.ok 시 refresh 수행', () async {
      await container.read(instancesControllerProvider.future); // 초기화
      final r = await container.read(instancesControllerProvider.notifier).createInstance(
        name: 'N',
        presetIds: const ['p1', 'p2'],
        optionPresetId: null,
        seedMode: SeedMode.allOff,
      );
      r.maybeMap(
        ok: (_) => expect(true, isTrue),
        orElse: () => fail('expected ok'),
      );

      // 스텁은 생성 시 id=gen-1, view 추가
      final list = container.read(instancesControllerProvider).requireValue;
      expect(list.map((e) => e.id), contains('gen-1'));
      expect(stub.listAllCalls, 2); // build + refresh
    });

    test('deleteInstance(): 삭제 후 refresh', () async {
      await container.read(instancesControllerProvider.future); // ['a','b']
      await container.read(instancesControllerProvider.notifier).deleteInstance('a');

      final list = container.read(instancesControllerProvider).requireValue;
      expect(list.map((e) => e.id).toList(), ['b']);
      expect(stub.deleteCalls.single, 'a');
      expect(stub.listAllCalls, 2);
    });

    test('duplicateInstance(): 복제 후 refresh', () async {
      await container.read(instancesControllerProvider.future);
      await container.read(instancesControllerProvider.notifier).duplicateInstance(
        sourceId: 'b',
        duplicateSuffix: '(copy)',
      );

      final list = container.read(instancesControllerProvider).requireValue;
      expect(list.any((e) => e.id == 'gen-1'), isTrue);
      expect(list.firstWhere((e) => e.id == 'gen-1').name, 'b (copy)');
      expect(stub.cloneCalls.single, 'b:(copy)');
      expect(stub.listAllCalls, 2);
    });

    test('getEnabledCount(): 캐시가 있으면 캐시 사용, 없으면 Service.getViewById', () async {
      await container.read(instancesControllerProvider.future); // cache: a(1), b(3)

      // 캐시 히트
      final c1 = await container.read(instancesControllerProvider.notifier).getEnabledCount('b');
      expect(c1, 3);
      expect(stub.getViewCalls, isEmpty);

      // 캐시 미스 → Service 조회
      stub.singleViews['x'] = _v('x', enabledCount: 7);
      final c2 = await container.read(instancesControllerProvider.notifier).getEnabledCount('x');
      expect(c2, 7);
      expect(stub.getViewCalls.single, 'x');
    });

    test('getByIdFast(): 캐시 우선, 없으면 Service 조회', () async {
      await container.read(instancesControllerProvider.future); // cache: a,b

      // 캐시 히트
      final hit = await container.read(instancesControllerProvider.notifier).getByIdFast('a');
      expect(hit!.id, 'a');

      // 캐시 미스 → Service 조회
      stub.singleViews['q'] = _v('q', enabledCount: 9);
      final miss = await container.read(instancesControllerProvider.notifier).getByIdFast('q');
      expect(miss!.enabledCount, 9);
      expect(stub.getViewCalls.single, 'q');
    });

    test('reorderInstances(): ok면 refresh, 실패면 refresh 하지 않음', () async {
      await container.read(instancesControllerProvider.future);
      expect(container.read(instancesControllerProvider).requireValue.map((e) => e.id).toList(), ['a', 'b']);

      // ok
      final r1 = await container.read(instancesControllerProvider.notifier).reorderInstances(const ['b', 'a']);
      r1.maybeMap(ok: (_) => expect(true, isTrue), orElse: () => fail('expected ok'));
      final list1 = container.read(instancesControllerProvider).requireValue;
      expect(list1.map((e) => e.id).toList(), ['b', 'a']);
      expect(stub.reorderCalls.single, 'b,a');

      // failure (generic)
      stub.failReorder = true;
      final prevListAllCalls = stub.listAllCalls;
      final r2 = await container.read(instancesControllerProvider.notifier).reorderInstances(const ['a', 'b']);
      r2.maybeMap(failure: (f) => expect(f.code, 'instance.reorder.failure'), orElse: () => fail('expected failure'));
      // refresh 안 함
      expect(stub.listAllCalls, prevListAllCalls);
    });

    test('instanceViewByIdProvider: 목록 캐시에서 단건 찾아 반환', () async {
      await container.read(instancesControllerProvider.future);
      final a = container.read(instanceViewByIdProvider('a'));
      final x = container.read(instanceViewByIdProvider('x'));
      expect(a?.id, 'a');
      expect(x, isNull);
    });

    test('instanceEnabledCountProvider: 내부적으로 controller.getEnabledCount 사용', () async {
      await container.read(instancesControllerProvider.future);
      final val = await container.read(instanceEnabledCountProvider('b').future);
      expect(val, 3);
    });
  });
}

// ── Stubs & helpers ───────────────────────────────────────────────────────────
InstanceView _v(String id, {int enabledCount = 0, String? name}) => InstanceView(
  id: id,
  name: name ?? id,
  optionPresetId: null,
  items: const [],
  totalCount: enabledCount, // 크게 중요치 않음
  enabledCount: enabledCount,
  missingCount: 0,
  sortKey: InstanceSortKey.name,
  ascending: true,
  gameMode: GameMode.normal,
  updatedAt: null,
  lastSyncAt: null,
  group: null,
  categories: const [],
  appliedPresets: const [],
  image: null,
);

class _StubInstancesService extends InstancesService {
  _StubInstancesService()
      : super(
    repo: _NoRepo(),
    envService: _NoEnv(),
    optionPresetsService: _NoOptSvc(),
    modPresetsService: _NoModSvc(),
  );

  /// 목록 저장소(정렬 = 인덱스 순서)
  final List<InstanceView> views = [];

  /// 개별 조회용 저장소(캐시 미스 시 사용)
  final Map<String, InstanceView> singleViews = {};

  // call records / toggles
  int listAllCalls = 0;
  final List<String> getViewCalls = [];
  final List<String> deleteCalls = [];
  final List<String> cloneCalls = [];
  final List<String> reorderCalls = [];
  bool failReorder = false;

  int _gen = 1;
  String _nextId() => 'gen-${_gen++}';

  // ── overrides ──
  @override
  Future<List<InstanceView>> listAllViews({Map<String, InstalledMod>? installedOverride, String? modsRootOverride}) async {
    listAllCalls++;
    return List.unmodifiable(views);
  }

  @override
  Future<InstanceView?> getViewById(String id, {Map<String, InstalledMod>? installedOverride, String? modsRootOverride}) async {
    getViewCalls.add(id);
    final hit = views.where((e) => e.id == id).toList();
    if (hit.isNotEmpty) return hit.first;
    return singleViews[id];
  }

  @override
  Future<Result<Instance?>> create({
    required String name,
    required SeedMode seedMode,
    String? optionPresetId,
    List<AppliedPresetRef> appliedPresets = const [],
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
    InstanceSortKey? sortKey,
    bool? ascending,
    InstanceImage? image,
  }) async {
    final id = _nextId();
    views.add(_v(id, enabledCount: 0, name: name));
    final inst = Instance(
      id: id,
      name: name,
      optionPresetId: optionPresetId,
      appliedPresets: appliedPresets,
      gameMode: GameMode.normal,
      overrides: const [],
      image: null,
      sortKey: sortKey ?? InstanceSortKey.name,
      ascending: ascending ?? true,
      updatedAt: DateTime.now(),
      lastSyncAt: null,
      group: null,
      categories: const [],
    );
    return Result.ok(data: inst, code: 'instance.create.ok');
  }

  @override
  Future<Result<void>> delete(String instanceId) async {
    deleteCalls.add(instanceId);
    views.removeWhere((e) => e.id == instanceId);
    return const Result.ok(code: 'instance.delete.ok');
  }

  @override
  Future<Result<Instance?>> clone({
    required String sourceId,
    required String duplicateSuffix,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    cloneCalls.add('$sourceId:$duplicateSuffix');
    final src = views.firstWhere((e) => e.id == sourceId, orElse: () => _v(''));
    if (src.id.isEmpty) return const Result.notFound(code: 'instance.clone.notFound');
    final id = _nextId();
    views.add(src.copyWith(id: id, name: '${src.name} $duplicateSuffix'));
    final inst = Instance(
      id: id,
      name: '${src.name} $duplicateSuffix',
      optionPresetId: null,
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
    return Result.ok(data: inst, code: 'instance.clone.ok');
  }

  @override
  Future<Result<void>> reorderInstances(List<String> orderedIds, {bool strict = true}) async {
    if (failReorder) {
      return Result.failure(code: 'instance.reorder.failure', ctx: {'error': 'boom'});
    }
    final map = {for (final v in views) v.id: v};
    views
      ..clear()
      ..addAll(orderedIds.map((id) => map[id]!).toList());
    reorderCalls.add(orderedIds.join(','));
    return const Result.ok(code: 'instance.reorder.ok');
  }
}

// 최소 더미 의존성
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
