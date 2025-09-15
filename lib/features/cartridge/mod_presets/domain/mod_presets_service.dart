import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/id.dart';

import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

class ModPresetsService {
  static const _tag = 'ModPresetsService';

  final IModPresetsRepository _repo;
  final ModsService _modsService;
  final IsaacEnvironmentService _env;
  final ModPresetProjector _projector;

  ModPresetsService({
    required IModPresetsRepository repository,
    ModsService? modsService,
    required IsaacEnvironmentService envService,
    ModPresetProjector? projector,
  })  : _repo        = repository,
        _modsService = modsService ?? ModsService(),
        _env         = envService,
        _projector   = projector ?? const ModPresetProjector();

  // ── Queries(조회) [View 반환] ───────────────────────────────────────────────────────────
  Future<List<ModPresetView>> listAllViews({
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final list      = await _repo.listAll();
    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    return list
        .map((p) => _projector.toView(preset: p, installed: installed))
        .toList(growable: false);
  }

  Future<Result<ModPresetView>> getViewById({
    required String presetId,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final src = await _repo.findById(presetId);
    if (src == null) return const Result.notFound(code: 'modPreset.getViewById.notFound');

    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );

    final view = _projector.toView(preset: src, installed: installed);
    return Result.ok(
      data: view,
      code: 'modPreset.getViewById.ok',
      ctx : {'presetId': presetId, 'installedCount': installed.length},
    );
  }

  Future<ModPresetView?> getById({
    required String presetId,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final src = await _repo.findById(presetId);
    if (src == null) return null;

    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    return _projector.toView(preset: src, installed: installed);
  }


  Future<List<ModPreset>> getRawPresetsByIds(Set<String> ids) async {
    if (ids.isEmpty) return const <ModPreset>[];
    // 개별 조회로 불필요한 전체 로드를 피함
    final hits = await Future.wait(ids.map(_repo.findById));
    return hits.whereType<ModPreset>().toList(growable: false);
  }

  // ── Commands(생성/수정/삭제/복제) ───────────────────────────────────────────────────────────
  Future<Result<ModPresetView>> create({
    required String name,
    required SeedMode seedMode,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
    ModSortKey? sortKey,
    bool? ascending,
  }) async {
    final now = DateTime.now();

    late final List<ModEntry> entries;
    late final Map<String, InstalledMod> installedForView;

    if (seedMode == SeedMode.allOff) {
      entries          = const <ModEntry>[];
      installedForView = const <String, InstalledMod>{};
    } else {
      final installed = await _getInstalledModsMap(
        installedOverride: installedOverride,
        modsRootOverride : modsRootOverride,
      );
      installedForView = installed;

      entries = installed.entries
          .where((e) => e.value.isEnabled)
          .map((e) {
        final m   = e.value;
        final key = e.key; // 폴더명(고유키)
        final wid = m.metadata.id.trim();
        final wnm = m.metadata.name.trim();
        return ModEntry(
          key         : key,
          workshopId  : wid.isEmpty ? null : wid,
          workshopName: wnm.isEmpty ? '알 수 없음' : wnm,
          enabled     : true,
          favorite    : false,
          updatedAt   : now,
        );
      })
          .toList(growable: false);
    }

    final preset = ModPreset.withGeneratedKey(
      genId    : IdUtil.genId,
      name     : name,
      entries  : entries,
      sortKey  : sortKey,
      ascending: ascending,
    );

    final normalized = ModPresetPolicy.normalize(preset);
    final vr = ModPresetPolicy.validate(normalized);
    if (!vr.isOk) {
      return Result<ModPresetView>.invalid(
        violations: vr.violations,
        code: 'modPreset.create.invalid',
      );
    }

    await _repo.upsert(normalized);
    final view = _projector.toView(preset: normalized, installed: installedForView);
    logI(_tag, 'op=create fn=create msg=완료 id=${normalized.id} entries=${entries.length} seed=$seedMode');

    return Result.ok(
      data: view,
      code: 'modPreset.create.ok',
      ctx : {'name': normalized.name, 'entryCount': entries.length, 'seed': seedMode.toString()},
    );
  }

  Future<Result<ModPresetView>> rename(
      String id,
      String newName, {
        Map<String, InstalledMod>? installedOverride,
        String? modsRootOverride,
      }) async {
    final cur = await _repo.findById(id);
    if (cur == null) return const Result.notFound(code: 'modPreset.rename.notFound');

    final next       = cur.copyWith(name: newName, updatedAt: DateTime.now());
    final normalized = ModPresetPolicy.normalize(next);
    final isSameName = normalized.name == cur.name;

    if (isSameName) {
      final installed = await _getInstalledModsMap(
        installedOverride: installedOverride,
        modsRootOverride : modsRootOverride,
      );
      final view = _projector.toView(preset: cur, installed: installed);
      return Result.ok(data: view, code: 'modPreset.rename.noop', ctx: {'name': view.name});
    }

    final vr = ModPresetPolicy.validate(normalized);
    if (!vr.isOk) {
      return Result<ModPresetView>.invalid(violations: vr.violations, code: 'modPreset.rename.invalid');
    }

    await _repo.upsert(normalized);
    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    final view = _projector.toView(preset: normalized, installed: installed);
    return Result.ok(data: view, code: 'modPreset.rename.ok', ctx: {'name': view.name});
  }

  Future<Result<void>> delete(String presetId) async {
    final cur = await _repo.findById(presetId);
    if (cur == null) {
      logI(_tag, 'op=delete fn=delete msg=원본 없음 id=$presetId');
      return const Result.notFound(code: 'modPreset.delete.notFound');
    }
    await _repo.removeById(presetId);
    logI(_tag, 'op=delete fn=delete msg=완료 id=$presetId');
    return Result.ok(code: 'modPreset.delete.ok', ctx: {'name': cur.name});
  }

  Future<Result<ModPresetView>> clone({
    required String sourceId,
    required String duplicateSuffix,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final src = await _repo.findById(sourceId);
    if (src == null) return const Result.notFound(code: 'modPreset.clone.notFound');

    final base           = src.name.trim();
    final suffix         = duplicateSuffix.trim();
    final effectiveBase  = base.isEmpty ? '모드 프리셋' : base;
    final effectiveSuffix= suffix.isEmpty ? '(사본)' : suffix;
    final newName        = base.isEmpty ? effectiveBase : '$effectiveBase $effectiveSuffix';

    final next       = src.duplicated(newName);
    final normalized = ModPresetPolicy.normalize(next);
    final vr         = ModPresetPolicy.validate(normalized);
    if (!vr.isOk) {
      return Result<ModPresetView>.invalid(violations: vr.violations, code: 'modPreset.clone.invalid');
    }

    await _repo.upsert(normalized);
    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    final view = _projector.toView(preset: normalized, installed: installed);
    logI(_tag, 'op=clone fn=clone msg=완료 newId=${normalized.id}');
    return Result.ok(data: view, code: 'modPreset.clone.ok', ctx: {'name': view.name});
  }

  Future<Result<ModPresetView>> removeMissing({
    required String presetId,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final prev = await _repo.findById(presetId);
    if (prev == null) return const Result.notFound(code: 'modPreset.removeMissing.notFound');

    final installed     = await _getInstalledModsMap(
      installedOverride: installedOverride,
      modsRootOverride : modsRootOverride,
    );
    final installedKeys = installed.keys.toSet();

    final kept         = prev.entries.where((e) => installedKeys.contains(e.key)).toList(growable: false);
    final removedCount = prev.entries.length - kept.length;
    final next         = (removedCount == 0)
        ? prev
        : prev.copyWith(entries: kept, updatedAt: DateTime.now());

    final vr = ModPresetPolicy.validate(next);
    if (!vr.isOk) {
      return Result<ModPresetView>.invalid(violations: vr.violations, code: 'modPreset.removeMissing.invalid');
    }

    if (removedCount != 0) await _repo.upsert(next);
    final view = _projector.toView(preset: next, installed: installed);
    return Result.ok(
      data: view,
      code: removedCount == 0 ? 'modPreset.removeMissing.noop' : 'modPreset.removeMissing.ok',
      ctx : {'removed': removedCount},
    );
  }

  // ── Sorting(정렬) ───────────────────────────────────────────────────────────
  Future<Result<void>> reorderModPresets(
      List<String> orderedIds, {
        bool strict = true,
      }) async {
    try {
      await _repo.reorderByIds(orderedIds, strict: strict);
      return const Result.ok(code: 'modPreset.reorder.ok');
    } on ArgumentError catch (e, st) {
      logE(_tag, 'op=reorder fn=reorderModPresets msg=invalid orderedIds', e, st);
      return Result.failure(code: 'modPreset.reorder.invalid', ctx: {'error': e.toString()});
    } catch (e, st) {
      logE(_tag, 'op=reorder fn=reorderModPresets msg=unexpected', e, st);
      return Result.failure(code: 'modPreset.reorder.failure', ctx: {'error': e.toString()});
    }
  }

  // ── State Changes(상태 변경) ───────────────────────────────────────────────────────────
  Future<Result<ModPresetView>> setItemState({
    required String presetId,
    required ModView item,
    bool? enabled,
    bool? favorite,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final cur = await _repo.findById(presetId);
    if (cur == null) {
      return const Result.notFound(code: 'modPreset.item.notFoundPreset');
    }

    final now     = DateTime.now();
    final entries = [...cur.entries];
    final idx     = entries.indexWhere((e) => e.key == item.id);

    bool? resolveEnabled(bool? v, {bool fallback = false}) =>
        v ?? (idx >= 0 ? entries[idx].enabled : fallback);
    bool resolveFavorite(bool? v, {bool fallback = false}) =>
        v ?? (idx >= 0 ? entries[idx].favorite : fallback);

    final nextEnabled  = resolveEnabled(enabled,  fallback: false);
    final nextFavorite = resolveFavorite(favorite, fallback: false);

    List<ModEntry> nextEntries;

    if (idx < 0) {
      if ((nextEnabled == null || nextEnabled == false) && !nextFavorite) {
        final installed = await _getInstalledModsMap(
          installedOverride: installedOverride, modsRootOverride: modsRootOverride,
        );
        final view = _projector.toView(preset: cur, installed: installed);
        return Result.ok(data: view, code: 'modPreset.item.noop', ctx: {'key': item.id});
      }

      final wid = item.installedRef?.metadata.id.trim() ?? '';
      final stub = ModEntry(
        key         : item.id,
        workshopId  : wid.isEmpty ? null : wid,
        workshopName: item.displayName,
        enabled     : nextEnabled,
        favorite    : nextFavorite,
        updatedAt   : now,
      );
      nextEntries = [...entries, stub];
    } else {
      final updated = entries[idx].copyWith(
        enabled  : nextEnabled,
        favorite : nextFavorite,
        updatedAt: now,
      );

      nextEntries = ((updated.enabled == null || updated.enabled == false) && !updated.favorite)
          ? entries.where((e) => e.key != item.id).toList(growable: false)
          : [
        for (int i = 0; i < entries.length; i++)
          if (i == idx) updated else entries[i]
      ];
    }

    final next = cur.copyWith(entries: nextEntries, updatedAt: now);

    final vr = ModPresetPolicy.validate(next);
    if (!vr.isOk) {
      return Result<ModPresetView>.invalid(
        violations: vr.violations,
        code: 'modPreset.item.setState.invalid',
      );
    }

    await _repo.upsert(next);

    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride, modsRootOverride: modsRootOverride,
    );
    final view = _projector.toView(preset: next, installed: installed);

    return Result.ok(
      data: view,
      code: 'modPreset.item.setState.ok',
      ctx : {'key': item.id, 'reinserted': idx < 0},
    );
  }

  Future<Result<ModPresetView>> bulkSetItemState({
    required String presetId,
    required Iterable<ModView> items,
    bool? enabled,
    bool? favorite,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final src = await _repo.findById(presetId);
    if (src == null) {
      return const Result.notFound(code: 'modPreset.item.bulk.notFoundPreset');
    }

    final now   = DateTime.now();
    final keys  = items.map((v) => v.id).toSet();
    final index = {for (int i = 0; i < src.entries.length; i++) src.entries[i].key: i};
    final list  = [...src.entries];

    var reinserts = 0;

    for (final v in items) {
      final key = v.id;
      final i   = index[key];

      if (i == null) {
        final nextEnabled  = enabled  ?? false;
        final nextFavorite = favorite ?? false;

        if (!nextEnabled && !nextFavorite) continue;

        final wid = v.installedRef?.metadata.id.trim() ?? '';
        final stub = ModEntry(
          key         : key,
          workshopId  : wid.isEmpty ? null : wid,
          workshopName: v.displayName,
          enabled     : nextEnabled,
          favorite    : nextFavorite,
          updatedAt   : now,
        );
        list.add(stub);
        index[key] = list.length - 1;
        reinserts++;
      } else {
        final cur = list[i];
        final next = cur.copyWith(
          enabled  : enabled  ?? cur.enabled,
          favorite : favorite ?? cur.favorite,
          updatedAt: now,
        );

        if ((next.enabled == null || next.enabled == false) && !next.favorite) {
          list.removeAt(i);
          index.remove(key);
          for (final entry in index.entries.toList()) {
            if (entry.value > i) index[entry.key] = entry.value - 1;
          }
        } else {
          list[i] = next;
        }
      }
    }

    final next = src.copyWith(entries: list, updatedAt: now);

    final vr = ModPresetPolicy.validate(next);
    if (!vr.isOk) {
      return Result<ModPresetView>.invalid(
        violations: vr.violations,
        code: 'modPreset.item.bulk.invalid',
      );
    }

    await _repo.upsert(next);

    final installed = await _getInstalledModsMap(
      installedOverride: installedOverride, modsRootOverride: modsRootOverride,
    );
    final view = _projector.toView(preset: next, installed: installed);

    return Result.ok(
      data: view,
      code: 'modPreset.item.bulk.ok',
      ctx : {'count': keys.length, 'reinserts': reinserts},
    );
  }

  Future<Result<void>> deleteItem({
    required String presetId,
    required String itemId,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    final cur = await _repo.findById(presetId);
    if (cur == null) return const Result.notFound(code: 'modPreset.item.notFoundPreset');

    final entries = [...cur.entries];
    final i = entries.indexWhere((e) => e.key == itemId);
    if (i < 0) return const Result.notFound(code: 'modPreset.item.notFound');

    final nextEntries = entries.where((e) => e.key != itemId).toList();
    final next = cur.copyWith(entries: nextEntries, updatedAt: DateTime.now());

    await _repo.upsert(next);
    return const Result<void>.ok(code: 'modPreset.item.delete.ok');
  }

  // ── Internals ───────────────────────────────────────────────────────────
  Future<Map<String, InstalledMod>> _getInstalledModsMap({
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    if (installedOverride != null) return installedOverride;
    if (modsRootOverride != null) return _modsService.getInstalledMap(modsRootOverride);
    return _env.getInstalledModsMap();
  }
}
