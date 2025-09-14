import 'dart:io';

import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/setting/domain/models/app_setting.dart';
import 'package:cartridge/features/isaac/options/isaac_options.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/cartridge/runtime/application/isaac_launcher_service.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';


void main() {
  group('InstancePlayService', () {
    late _StubInstances instances;
    late _StubOptionPresets optionPresets;
    late _SpyLauncher launcher;
    late InstancePlayService svc;

    setUp(() {
      instances = _StubInstances();
      optionPresets = _StubOptionPresets();
      launcher = _SpyLauncher();
      svc = InstancePlayService(
        instances: instances,
        optionPresets: optionPresets,
        launcher: launcher,
      );
    });

    test('playByInstanceId(): 인스턴스 뷰 없음 → null, launch 호출 안 함', () async {
      instances.bundleById.clear(); // 등록 없음

      final p = await svc.playByInstanceId('ghost');
      expect(p, isNull);
      expect(launcher.called, isFalse);
    });

    test('playByInstanceId(): optionPresetId 없으면 null로 launch, enabled만 entries에 포함', () async {
      final view = _view(
        id: 'i1',
        optionPresetId: null,
        items: [
          _modView(
            id: 'mod.a',
            name: 'A',
            effectiveEnabled: true,
            favorite: true,
            installedWorkshopId: '111', // workshopId 채워짐
          ),
          _modView(
            id: 'mod.b',
            name: 'B',
            effectiveEnabled: false, // 비활성 → entries 미포함
          ),
        ],
      );
      instances.bundleById['i1'] = (view, const <ModPresetView>[], null);

      final p = await svc.playByInstanceId('i1', extraArgs: const ['--foo']);
      expect(p, isNull); // spy는 실제 Process를 만들지 않음

      expect(launcher.called, isTrue);
      expect(launcher.lastExtraArgs, ['--foo']);
      expect(launcher.lastOptionPreset, isNull);

      // enabled 항목만 포함
      expect(launcher.lastEntries.keys, ['mod.a']);
      final e = launcher.lastEntries['mod.a']!;
      expect(e.key, 'mod.a');
      expect(e.enabled, isTrue);
      expect(e.favorite, isTrue);
      expect(e.workshopId, '111', reason: 'installedRef.metadata.id가 있으면 그 값을 사용');
      expect(e.workshopName, 'A');
    });

    test('playByInstanceId(): optionPresetId 있으면 OptionPreset 로드해서 전달', () async {
      optionPresets.registry['opt1'] = OptionPreset(
        id: 'opt1',
        name: 'Option One',
        useRepentogon: null,
        options: IsaacOptions(), // 최소값
        updatedAt: null,
      );

      final view = _view(
        id: 'i2',
        optionPresetId: 'opt1',
        items: [_modView(id: 'mod.x', name: 'X', effectiveEnabled: true)],
      );
      instances.bundleById['i2'] = (view, const <ModPresetView>[], null);

      await svc.playByInstanceId('i2');

      expect(optionPresets.lastRequestedId, 'opt1');
      expect(launcher.lastOptionPreset?.id, 'opt1');
      expect(launcher.lastEntries.containsKey('mod.x'), isTrue);
    });

    test('playWithView(): 전달 인자(override 경로/args) 그대로 위임', () async {
      final view = _view(
        id: 'i3',
        optionPresetId: 'opt1',
        items: [_modView(id: 'mod.k', name: 'K', effectiveEnabled: true)],
      );
      optionPresets.registry['opt1'] = OptionPreset(
        id: 'opt1',
        name: 'Opt',
        useRepentogon: null,
        options: IsaacOptions(),
        updatedAt: null,
      );

      await svc.playWithView(
        view,
        optionsIniPathOverride: '/tmp/ini',
        installPathOverride: '/games/isaac',
        extraArgs: const ['-seed', 'foo'],
      );

      expect(launcher.lastOptionsIniPath, '/tmp/ini');
      expect(launcher.lastInstallPath, '/games/isaac');
      expect(launcher.lastExtraArgs, ['-seed', 'foo']);
      expect(launcher.lastEntries.containsKey('mod.k'), isTrue);
    });

    test('_buildEntriesFromView(): workshopId가 없으면 id로 대체', () async {
      final view = _view(
        id: 'i4',
        optionPresetId: null,
        items: [
          _modView(
            id: 'local.mod', // installedRef 없음 → fallback
            name: 'Local Mod',
            effectiveEnabled: true,
          ),
        ],
      );
      instances.bundleById['i4'] = (view, const <ModPresetView>[], null);

      await svc.playByInstanceId('i4');

      final m = launcher.lastEntries['local.mod']!;
      expect(m.workshopId, 'local.mod', reason: 'installedRef.id 비어있으면 row key(id) 사용');
    });
  });
}

/// ───────────────────────── helpers/stubs ─────────────────────────

InstanceView _view({
  required String id,
  String? optionPresetId,
  required List<ModView> items,
}) {
  return InstanceView(
    id: id,
    name: 'Inst',
    optionPresetId: optionPresetId,
    items: items,
    totalCount: items.length,
    enabledCount: items.where((e) => e.effectiveEnabled).length,
    missingCount: items.where((e) => !e.isInstalled).length,
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
}

ModView _modView({
  required String id,
  required String name,
  required bool effectiveEnabled,
  bool favorite = false,
  String installedWorkshopId = '',
}) {
  final installed = (installedWorkshopId.isNotEmpty)
      ? InstalledMod(
    metadata: ModMetadata(
      id: installedWorkshopId,
      name: name,
      directory: id,
      version: '1.0',
      visibility: ModVisibility.public,
      tags: const <String>[],
    ),
    disabled: !effectiveEnabled,
  )
      : null;

  return ModView(
    id: id,
    isInstalled: installed != null,
    explicitEnabled: false, // InstancePlayService는 explicit 여부와 무관
    effectiveEnabled: effectiveEnabled,
    favorite: favorite,
    displayName: name,
    installedRef: installed,
    status: ModRowStatus.ok,
    enabledByPresets: const <String>{},
    updatedAt: DateTime.now(),
  );
}

/// InstancesService 대역: getViewWithRelated만 사용
class _StubInstances extends InstancesService {
  _StubInstances()
      : super(
    repo: _NoInstRepo(),
    envService: _NoEnv(),
    optionPresetsService: _NoOptSvc(),
    modPresetsService: _NoModSvc(),
  );

  final Map<String, (InstanceView, List<ModPresetView>, OptionPresetView?)>
  bundleById = {};

  @override
  Future<(InstanceView, List<ModPresetView>, OptionPresetView?)?> getViewWithRelated(
      String id, {
        Map<String, InstalledMod>? installedOverride,
        String? modsRootOverride,
      }) async {
    return bundleById[id];
  }
}

/// OptionPresetsService 대역: getById만 사용(OptionPreset 반환)
class _StubOptionPresets extends OptionPresetsService {
  _StubOptionPresets() : super(repo: _NoOptRepo());
  final Map<String, OptionPreset> registry = {};
  String? lastRequestedId;

  @override
  Future<OptionPreset?> getById(String id) async {
    lastRequestedId = id;
    return registry[id];
  }
}

/// IsaacLauncherService 스파이: 전달 인자를 기록
class _SpyLauncher implements IsaacLauncherService {
  bool called = false;
  OptionPreset? lastOptionPreset;
  Map<String, ModEntry> lastEntries = const {};
  String? lastOptionsIniPath;
  String? lastInstallPath;
  List<String> lastExtraArgs = const [];


  @override
  ModsService get modsService => throw UnimplementedError();

  @override
  IsaacOptionsIniService get optionsIniService => throw UnimplementedError();

  @override
  IsaacRuntimeService get runtime => throw UnimplementedError();

  @override
  Future<Process?> launchIsaac({
    OptionPreset? optionPreset,
    Map<String, ModEntry> entries = const <String, ModEntry>{},
    AppSetting? appSetting,
    String? optionsIniPathOverride,
    String? installPathOverride,
    List<String> extraArgs = const [],
  }) async {
    called = true;
    lastOptionPreset = optionPreset;
    lastEntries = Map.of(entries);
    lastOptionsIniPath = optionsIniPathOverride;
    lastInstallPath = installPathOverride;
    lastExtraArgs = List.of(extraArgs);
    return null; // 실제 프로세스 실행 안 함
  }
}

/// 아래는 사용되지 않는 의존성들의 더미 구현
class _NoInstRepo implements IInstancesRepository {
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
  Future<String?> detectOptionsIniPathAuto({List<String> fallbackCandidates = const []}) =>
      throw UnimplementedError();
  @override
  Future<bool> isValidInstallDir(String? dir) => throw UnimplementedError();
  @override
  Future<LaunchEnvironment?> resolveEnvironment(
      {String? optionsIniPathOverride, List<String> fallbackIniCandidates = const []}) =>
      throw UnimplementedError();
  @override
  Future<String?> resolveInstallPath() => throw UnimplementedError();
  @override
  Future<InstallPathResolution> resolveInstallPathDetailed({String? installPathOverride}) =>
      throw UnimplementedError();
  @override
  Future<String?> resolveModsRoot() => throw UnimplementedError();
  @override
  Future<String?> resolveOptionsIniPath({String? override, List<String> fallbackCandidates = const []}) =>
      throw UnimplementedError();
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
