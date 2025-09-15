import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

class InstancesService {
  static const _tag = 'InstancesService';

  final IInstancesRepository _repo;
  final OptionPresetsService _optionPresets;
  final ModPresetsService _modPresets;
  final ModsService _modsService;
  final IsaacEnvironmentService _env;
  final ComputeModViewsUseCase _compute;

  InstancesService({
    required IInstancesRepository repo,
    required IsaacEnvironmentService envService,
    required OptionPresetsService optionPresetsService,
    required ModPresetsService modPresetsService,
    ModsService? modsService,
    ComputeModViewsUseCase? computeModViewsUseCase,
  })  : _repo          = repo,
        _env           = envService,
        _optionPresets = optionPresetsService,
        _modPresets    = modPresetsService,
        _modsService   = modsService ?? ModsService(),
        _compute       = computeModViewsUseCase ?? ComputeModViewsUseCase();


  // ── Queries ───────────────────────────────────────────────────────────

  Future<List<InstanceView>> listAllViews({
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    logI(_tag, 'op=list fn=listAllViews msg=시작');

    // ① 인스턴스/설치모드 병렬 로드
    final instancesF = _repo.listAll();
    final installedF = _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );

    final instances = await instancesF;                    // List<Instance>
    final installedMap = await installedF;
    final installedList = installedMap.values.toList(growable: false);

    // ② 인스턴스들이 참조하는 프리셋 id 모으기 → 필요한 것만 조회
    final wantedPresetIds = <String>{
      for (final inst in instances) ...inst.appliedPresets.map((e) => e.presetId),
    };
    final neededPresets = await _modPresets.getRawPresetsByIds(wantedPresetIds);
    final presetMap = {for (final p in neededPresets) p.id: p};

    // ③ 인스턴스별 요약 View 합성 (ModView 목록은 비움)
    final out = <InstanceView>[];
    for (final inst in instances) {
      final applied = <ModPreset>[
        for (final r in inst.appliedPresets) if (presetMap[r.presetId] != null) presetMap[r.presetId]!,
      ];

      final items = _compute(
        installedMods  : installedList,
        selectedPresets: applied,
        instance       : inst,
      );

      final totalCount   = items.length;
      final enabledCount = items.where((e) => e.effectiveEnabled).length;
      final missingCount = items.where((e) => !e.isInstalled).length;

      out.add(InstanceView(
        id              : inst.id,
        name            : inst.name,
        optionPresetId  : inst.optionPresetId,
        items           : const <ModView>[],  // 목록에서는 비움
        totalCount      : totalCount,
        enabledCount    : enabledCount,
        missingCount    : missingCount,
        sortKey         : inst.sortKey,
        ascending       : inst.ascending,
        gameMode        : inst.gameMode,
        updatedAt       : inst.updatedAt,
        lastSyncAt      : inst.lastSyncAt,
        group           : inst.group,
        categories      : inst.categories,
        appliedPresets  : _buildAppliedLabels(inst.appliedPresets, presetMap),
        image           : inst.image,
      ));
    }

    logI(_tag, 'op=list fn=listAllViews msg=완료 count=${out.length}');
    return List.unmodifiable(out);
  }

  Future<InstanceView?> getViewById(
      String id, {
        Map<String, InstalledMod>? installedOverride,
        String? modsRootOverride,
      }) async {
    final inst = await _repo.findById(id);
    if (inst == null) return null;

    final installedMap = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    final installedList = installedMap.values.toList(growable: false);

    final appliedIds = inst.appliedPresets.map((e) => e.presetId).toSet();
    final applied    = await _getAppliedPresetsByIds(appliedIds);
    final presetMap  = {for (final p in applied) p.id: p};

    final items = _compute(
      installedMods  : installedList,
      selectedPresets: applied,
      instance       : inst,
    );

    final totalCount   = items.length;
    final enabledCount = items.where((e) => e.effectiveEnabled).length;
    final missingCount = items.where((e) => !e.isInstalled).length;

    return InstanceView(
      id              : inst.id,
      name            : inst.name,
      optionPresetId  : inst.optionPresetId,
      items           : items,
      totalCount      : totalCount,
      enabledCount    : enabledCount,
      missingCount    : missingCount,
      sortKey         : inst.sortKey,
      ascending       : inst.ascending,
      gameMode        : inst.gameMode,
      updatedAt       : inst.updatedAt,
      lastSyncAt      : inst.lastSyncAt,
      group           : inst.group,
      categories      : inst.categories,
      appliedPresets  : _buildAppliedLabels(inst.appliedPresets, presetMap),
      image           : inst.image,
    );
  }

  Future<(InstanceView, List<ModPresetView>, OptionPresetView?)?> getViewWithRelated(
      String id, {
        Map<String, InstalledMod>? installedOverride,
        String? modsRootOverride,
      }) async {
    final inst = await _repo.findById(id);
    if (inst == null) return null;

    // 설치 목록 공유
    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );

    final view = await getViewById(
      id,
      installedOverride: installed,
      modsRootOverride : modsRootOverride,
    );
    if (view == null) return null;

    // 적용 프리셋 뷰
    final presetIds = inst.appliedPresets.map((e) => e.presetId).toList(growable: false);
    final modPresetViews = <ModPresetView>[];
    for (final pid in presetIds) {
      final pv = await _modPresets.getById(
        presetId: pid,
        installedOverride: installed,
        modsRootOverride : modsRootOverride,
      );
      if (pv != null) modPresetViews.add(pv);
    }

    // 옵션 프리셋 뷰(있으면)
    OptionPresetView? optionView;
    if ((inst.optionPresetId ?? '').trim().isNotEmpty) {
      optionView = await _optionPresets.getViewById(inst.optionPresetId!.trim());
    }

    return (view, modPresetViews, optionView);
  }

  // ── Commands ───────────────────────────────────────────────────────────

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
    final installedMap  = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    final installedList = installedMap.values.toList(growable: false);

    final now = DateTime.now();
    var overrides = switch (seedMode) {
      SeedMode.allOff => <ModEntry>[],
      SeedMode.currentEnabled => _seedFromInstalledCurrentEnabled(
        installedList: installedList,
        now: now,
      ),
    };

    var inst = Instance.withGeneratedKey(
      genId         : IdUtil.genId,
      name          : name,
      optionPresetId: optionPresetId,
      appliedPresets: appliedPresets,
      overrides     : overrides,
      gameMode      : GameMode.normal,
      sortKey       : sortKey,
      ascending     : ascending,
    );

    final defaultImage = image ?? InstanceImage.sprite(
      index: InstanceImage.pickRandomUsableSpriteIndex(),
    );
    inst = inst.copyWith(image: defaultImage);

    if (seedMode == SeedMode.currentEnabled && appliedPresets.isNotEmpty) {
      final selected = await _getAppliedPresetsByIds(
        appliedPresets.map((e) => e.presetId).toSet(),
      );
      overrides = _pruneOverridesCoveredByPresets(
        instance: inst,
        installedList: installedList,
        selectedPresets: selected,
        now: now,
      );
      inst = inst.copyWith(overrides: overrides, updatedAt: now);
    }

    final normalized = InstancePolicy.normalize(inst);
    final vr = InstancePolicy.validate(normalized);
    if (!vr.isOk) {
      logI(_tag, 'op=create invalid violations=${vr.violations.map((e)=>e.code).toList()}');
      return Result.invalid(violations: vr.violations, code: 'instance.create.invalid');
    }

    await _repo.upsert(normalized);
    logI(_tag, 'op=create fn=create msg=완료 id=${inst.id} overrides=${overrides.length}');
    return Result.ok(data: normalized, code: 'instance.create.ok');
  }

  Future<Result<Instance>> rename(String id, String newName) async {
    final cur = await _repo.findById(id);
    if (cur == null) return const Result.notFound(code: 'instance.rename.notFound');

    final next = cur.copyWith(name: newName, updatedAt: DateTime.now());
    final normalized = InstancePolicy.normalize(next);
    if (normalized.name == cur.name) {
      return Result.ok(data: cur, code: 'instance.rename.noop', ctx: {'name': cur.name});
    }
    final vr = InstancePolicy.validate(normalized);
    if (!vr.isOk) {
      return Result<Instance>.invalid(violations: vr.violations, code: 'instance.rename.invalid');
    }
    await _repo.upsert(normalized);
    return Result.ok(data: normalized, code: 'instance.rename.ok', ctx: {'name': normalized.name});
  }

  Future<Result<void>> delete(String instanceId) async {
    final cur = await _repo.findById(instanceId);
    if (cur == null) return const Result.notFound(code: 'instance.delete.notFound');
    await _repo.removeById(instanceId);
    return Result.ok(code: 'instance.delete.ok', ctx: {'name': cur.name});
  }

  Future<Result<Instance?>> clone({
    required String sourceId,
    required String duplicateSuffix,
  }) async {
    final src = await _repo.findById(sourceId);
    if (src == null) return const Result.notFound(code: 'instance.clone.notFound');

    final base = src.name.trim();
    final suffix = duplicateSuffix.trim();
    final effectiveBase = base.isEmpty ? '인스턴스' : base;
    final effectiveSuffix = suffix.isEmpty ? '(사본)' : suffix;
    final newName = base.isEmpty ? effectiveBase : '$effectiveBase $effectiveSuffix';

    final next = src.duplicated(newName);
    final normalized = InstancePolicy.normalize(next);
    final vr = InstancePolicy.validate(normalized);
    if (!vr.isOk) {
      return Result<Instance>.invalid(violations: vr.violations, code: 'instance.clone.invalid');
    }
    await _repo.upsert(normalized);
    logI(_tag, 'op=clone fn=clone msg=완료 newId=${next.id}');
    return Result.ok(data: normalized, code: 'instance.clone.ok', ctx: {'name': normalized.name});
  }

  Future<Result<Instance?>> setImageToSprite({
    required String instanceId,
    required int index,
  }) async {
    final cur = await _repo.findById(instanceId);
    if (cur == null) return const Result.notFound(code: 'instance.image.set.notFound');

    final next = cur.copyWith(image: InstanceImage.sprite(index: index), updatedAt: DateTime.now());
    final vr = InstancePolicy.validate(next);
    if (!vr.isOk) {
      return Result.invalid(violations: vr.violations, code: 'instance.image.set.invalid');
    }
    await _repo.upsert(next);
    return Result.ok(data: next, code: 'instance.image.set.ok');
  }

  Future<Result<Instance?>> setImageToUserFile({
    required String instanceId,
    required String path,
    BoxFit fit = BoxFit.cover,
  }) async {
    final cur = await _repo.findById(instanceId);
    if (cur == null) return const Result.notFound(code: 'instance.image.set.notFound');

    final next = cur.copyWith(image: InstanceImage.userFile(path: path, fit: fit), updatedAt: DateTime.now());
    final vr = InstancePolicy.validate(next);
    if (!vr.isOk) {
      return Result.invalid(violations: vr.violations, code: 'instance.image.set.invalid');
    }
    await _repo.upsert(next);
    return Result.ok(data: next, code: 'instance.image.set.ok');
  }

  Future<Result<Instance?>> setImageToRandomSprite({
    required String instanceId,
    int? seed,
  }) async {
    final idx = InstanceImage.pickRandomUsableSpriteIndex(seed: seed);
    return setImageToSprite(instanceId: instanceId, index: idx);
  }

  Future<Result<Instance?>> clearImage(String instanceId) async {
    final cur = await _repo.findById(instanceId);
    if (cur == null) return const Result.notFound(code: 'instance.image.clear.notFound');

    final next = cur.copyWith(image: null, updatedAt: DateTime.now());
    await _repo.upsert(next);
    return Result.ok(data: next, code: 'instance.image.clear.ok');
  }

  Future<Result<void>> removeMissingFromAllAppliedPresets({
    required String instanceId,
    required Map<String, InstalledMod>? installedOverride,
  }) async {
    final inst = await _repo.findById(instanceId);
    if (inst == null) return const Result.notFound(code: 'instance.removeMissingFromAllAppliedPresets.notFound');

    for (final applied in inst.appliedPresets) {
      await _modPresets.removeMissing(
        presetId         : applied.presetId,
        installedOverride: installedOverride,
      );
    }
    return const Result.ok(code: 'instance.removeMissingFromAllAppliedPresets.ok');
  }

  Future<Result<void>> reorderInstances(
      List<String> orderedIds, {
        bool strict = true,
      }) async {
    try {
      await _repo.reorderByIds(orderedIds, strict: strict);
      return const Result.ok(code: 'instance.reorder.ok');
    } on ArgumentError catch (e, st) {
      logE(_tag, 'op=reorder fn=reorderInstances msg=invalid orderedIds', e, st);
      return Result.failure(code: 'instance.reorder.invalid', ctx: {'error': e.toString()});
    } catch (e, st) {
      logE(_tag, 'op=reorder fn=reorderInstances msg=unexpected', e, st);
      return Result.failure(code: 'instance.reorder.failure', ctx: {'error': e.toString()});
    }
  }

  Future<Result<Instance?>> setItemState({
    required String instanceId,
    required ModView item,
    bool? enabled,
    bool? favorite,
  }) async {
    final res = await setModelState(
      instanceId: instanceId,
      item: item,
      enabled: enabled,
      favorite: favorite,
    );
    return Result.ok(data: res, code: 'instance.item.setState.ok', ctx: {'key': res?.id});
  }

  Future<Instance?> setModelState({
    required String instanceId,
    required ModView item,
    bool? enabled,
    bool? favorite,
  }) async {
    final cur = await _repo.findById(instanceId);
    if (cur == null) {
      logI(_tag, 'op=update fn=setItemState msg=원본 없음 id=$instanceId');
      return null;
    }

    final now = DateTime.now();
    final map = {for (final e in cur.overrides) e.key: e};
    final prev = map[item.id];
    final next = _deriveOverride(
      item: item,
      prev: prev,
      enabled: enabled,
      favorite: favorite,
      now: now,
    );

    if (next == null) {
      map.remove(item.id);
    } else {
      map[item.id] = next;
    }

    final res = cur.copyWith(
      overrides: map.values.toList(growable: false),
      updatedAt: now,
    );

    await _repo.upsert(res);
    return res;
  }

  Future<Result<Instance?>> bulkSetItemState({
    required String instanceId,
    required Iterable<ModView> items,
    bool? enabled,
    bool? favorite,
  }) async {
    final cur0 = await _repo.findById(instanceId);
    if (cur0 == null) {
      return const Result.notFound(code: 'instance.item.bulk.notFound');
    }

    final now = DateTime.now();
    final map = <String, ModEntry>{for (final e in cur0.overrides) e.key: e};

    for (final v in items) {
      final prev = map[v.id];
      final next = _deriveOverride(
        item: v,
        prev: prev,
        enabled: enabled,
        favorite: favorite,
        now: now,
      );
      if (next == null) {
        if (prev != null) map.remove(v.id);
      } else {
        map[v.id] = next;
      }
    }

    final cur = cur0.copyWith(
      overrides: map.values.toList(growable: false),
      updatedAt: now,
    );

    await _repo.upsert(cur);
    return Result.ok(data: cur, code: 'instance.item.bulk.ok', ctx: {'name': cur.name});
  }

  Future<Result<Instance?>> setOptionPreset(String instanceId, String? optionPresetId) async {
    final src = await _repo.findById(instanceId);
    if (src == null) return const Result.notFound(code: 'instance.setOptionPreset.notFound');

    final next = src.copyWith(optionPresetId: optionPresetId, updatedAt: DateTime.now());
    final normalized = InstancePolicy.normalize(next);
    final vr = InstancePolicy.validate(normalized);
    if (!vr.isOk) {
      return Result<Instance>.invalid(violations: vr.violations, code: 'instance.setOptionPreset.invalid');
    }
    await _repo.upsert(normalized);
    return Result.ok(data: normalized, code: 'instance.setOptionPreset.ok', ctx: {'optionPresetId': optionPresetId});
  }

  Future<Instance?> replaceAppliedPresets({
    required String instanceId,
    required List<AppliedPresetRef> refs,
  }) async {
    final src = await _repo.findById(instanceId);
    if (src == null) {
      logI(_tag, 'op=update fn=replaceAppliedPresets msg=원본 없음 id=$instanceId');
      return null;
    }

    final seen = <String>{};
    final dedup = <AppliedPresetRef>[];
    for (final r in refs) {
      if (seen.add(r.presetId)) dedup.add(r);
    }

    final now = DateTime.now();
    final next = src.copyWith(appliedPresets: dedup, updatedAt: now);
    final normalized  = InstancePolicy.normalize(next);
    final vr = InstancePolicy.validate(normalized);
    if (!vr.isOk) {
      logI(_tag, 'op=update fn=replaceAppliedPresets invalid violations=${vr.violations.map((e)=>e.code).toList()}');
      return null;
    }
    await _repo.upsert(normalized);
    return normalized;
  }

  Future<void> deleteItem({
    required String instanceId,
    required String itemId,
  }) async {
    final cur = await _repo.findById(instanceId);
    if (cur == null) {
      logI(_tag, 'op=delete fn=deleteItem msg=원본 없음 id=$instanceId');
      return;
    }
    final overrides = [...cur.overrides]..removeWhere((e) => e.key == itemId);
    final next = cur.copyWith(overrides: overrides, updatedAt: DateTime.now());
    await _repo.upsert(next);
  }

  // ── Internals (로직 유틸) ───────────────────────────────────────────────────────────

  ModEntry? _deriveOverride({
    required ModView item,
    required ModEntry? prev,
    bool? enabled,
    bool? favorite,
    required DateTime now,
  }) {
    final bool removeIntent = (enabled == null) && (favorite == null || favorite == false);
    if (removeIntent) {
      return null;
    }

    final bool mustSave = (enabled != null) || (favorite == true);

    final String? workshopId =
        prev?.workshopId ??
            ((item.installedRef?.metadata.id.trim().isNotEmpty ?? false)
                ? item.installedRef!.metadata.id
                : null);

    if (prev == null) {
      if (!mustSave) return null;
      return ModEntry(
        key: item.id,
        workshopId: workshopId,
        workshopName: item.displayName,
        enabled: enabled,
        favorite: favorite ?? false,
        updatedAt: now,
      );
    }

    return prev.copyWith(
      enabled: enabled ?? prev.enabled,
      favorite: favorite ?? prev.favorite,
      updatedAt: now,
    );
  }

  List<ModEntry> _pruneOverridesCoveredByPresets({
    required Instance instance,
    required List<InstalledMod> installedList,
    required List<ModPreset> selectedPresets,
    required DateTime now,
  }) {
    final views = _compute(
      installedMods  : installedList,
      selectedPresets: selectedPresets,
      instance       : instance,
    );

    final covered = <String>{
      for (final v in views) if (v.enabledByPresets.isNotEmpty) v.id,
    };

    final out = <ModEntry>[];
    for (final o in instance.overrides) {
      final enabledSeed = o.enabled == true;
      if (enabledSeed && covered.contains(o.key)) continue;
      out.add(o);
    }
    return out;
  }

  List<ModEntry> _seedFromInstalledCurrentEnabled({
    required List<InstalledMod> installedList,
    required DateTime now,
  }) {
    final seenKeys = <String>{};
    final out = <ModEntry>[];
    for (final m in installedList) {
      if (!m.isEnabled) continue;
      final key = m.folderName;
      if (key.isEmpty || seenKeys.contains(key)) continue;
      seenKeys.add(key);
      final wid = m.metadata.id.trim();
      final nm  = m.metadata.name.trim();
      out.add(ModEntry(
        key         : key,
        workshopId  : wid.isEmpty ? null : wid,
        workshopName: nm.isEmpty ? '알 수 없음' : nm,
        enabled     : true,
        favorite    : false,
        updatedAt   : now,
      ));
    }
    return out;
  }

  Future<List<ModPreset>> _getAppliedPresetsByIds(Set<String> ids) async {
    return _modPresets.getRawPresetsByIds(ids);
  }

  Future<Map<String, InstalledMod>> _getInstalledModsMap({
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    if (installedOverride != null) return installedOverride;
    if (modsRootOverride != null) return _modsService.getInstalledMap(modsRootOverride);
    return _env.getInstalledModsMap();
  }

  List<AppliedPresetLabelView> _buildAppliedLabels(
      List<AppliedPresetRef> refs,
      Map<String, ModPreset> presetMap,
      ) {
    final labels = <AppliedPresetLabelView>[];
    for (final r in refs) {
      final p = presetMap[r.presetId];
      labels.add(AppliedPresetLabelView(
        presetId   : r.presetId,
        presetName : p?.name ?? r.presetId,
        isMandatory: r.isMandatory,
      ));
    }
    return labels;
  }
}
