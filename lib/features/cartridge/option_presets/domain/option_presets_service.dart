import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/option_presets/data/i_option_presets_repository.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset_view.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/policy/option_preset_policy.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';

/// {@template option_presets_service}
/// 옵션 프리셋 목록/검색/뷰 변환/CRUD를 제공하는 Domain Service.
/// - 저장/조회는 IOptionPresetsRepository(SQLite)로 위임
/// - 정렬은 DB의 pos(사용자 정렬 순서)를 따른다
/// {@endtemplate}
class OptionPresetsService {
  static const _tag = 'OptionPresetsService';

  final IOptionPresetsRepository _repo;
  OptionPresetsService({required IOptionPresetsRepository repo}) : _repo = repo;

  // ── Queries (View) ───────────────────────────────────────────────────────────
  Future<List<OptionPresetView>> listAllViews() async {
    final list = await _listModels();
    return list.map(OptionPresetView.fromModel).toList(growable: false);
  }

  Future<OptionPresetView?> getViewById(String id) async {
    logI(_tag, 'op=get fn=getViewById id=$id');
    final v = await _repo.findById(id);
    return v == null ? null : OptionPresetView.fromModel(v);
  }

  Future<OptionPreset?> getById(String id) async {
    logI(_tag, 'op=get fn=getById id=$id');
    return _repo.findById(id);
  }

  // ── Commands ───────────────────────────────────────────────────────────
  Future<Result<void>> deleteView(String id) async {
    logI(_tag, 'op=delete id=$id');
    final curr = await _repo.findById(id);
    if (curr == null) {
      logW(_tag, 'op=delete msg=notFound id=$id');
      return const Result<void>.notFound(code: 'optionPreset.delete.notFound');
    }
    await _repo.removeById(id);
    return Result<void>.ok(code: 'optionPreset.delete.ok', ctx: {'name': curr.name});
  }

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
    logI(_tag, 'op=create name="$name"');

    final rawOptions = IsaacOptions(
      windowWidth: windowWidth,
      windowHeight: windowHeight,
      windowPosX: windowPosX,
      windowPosY: windowPosY,
      fullscreen: fullscreen,
      gamma: gamma,
      enableDebugConsole: enableDebugConsole,
      pauseOnFocusLost: pauseOnFocusLost,
      mouseControl: mouseControl,
    );

    final preset = OptionPreset.withGeneratedKey(
      genId: IdUtil.genId,
      name: name,
      useRepentogon: useRepentogon,
      options: rawOptions,
      updatedAt: DateTime.now(),
    );

    final normalized = OptionPresetPolicy.normalize(preset);
    final vr = OptionPresetPolicy.validate(normalized);
    if (!vr.isOk) {
      logW(_tag, 'op=create msg=invalid violations=${vr.violations.map((e)=>e.code).toList()}');
      return Result<OptionPresetView>.invalid(
        violations: vr.violations,
        code: 'optionPreset.create.invalid',
      );
    }

    await _repo.upsert(normalized);
    return Result<OptionPresetView>.ok(
      data: OptionPresetView.fromModel(normalized),
      code: 'optionPreset.create.ok',
      ctx: {'name': normalized.name},
    );
  }

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
    logI(_tag, 'op=update id=$id');

    final curr = await _repo.findById(id);
    if (curr == null) {
      logW(_tag, 'op=update msg=notFound id=$id');
      return const Result<OptionPresetView>.notFound(code: 'optionPreset.update.notFound');
    }

    final nextOptions = IsaacOptions(
      windowWidth: windowWidth ?? curr.options.windowWidth,
      windowHeight: windowHeight ?? curr.options.windowHeight,
      windowPosX: windowPosX ?? curr.options.windowPosX,
      windowPosY: windowPosY ?? curr.options.windowPosY,
      fullscreen: fullscreen ?? curr.options.fullscreen,
      gamma: gamma ?? curr.options.gamma,
      enableDebugConsole: enableDebugConsole ?? curr.options.enableDebugConsole,
      pauseOnFocusLost: pauseOnFocusLost ?? curr.options.pauseOnFocusLost,
      mouseControl: mouseControl ?? curr.options.mouseControl,
    );

    final next = curr.copyWith(
      name: (name == null || name.trim().isEmpty) ? curr.name : name.trim(),
      options: nextOptions,
      useRepentogon: useRepentogon ?? curr.useRepentogon,
      updatedAt: DateTime.now(),
    );

    final normalized = OptionPresetPolicy.normalize(next);
    final vr = OptionPresetPolicy.validate(normalized);
    if (!vr.isOk) {
      logW(_tag, 'op=update msg=invalid violations=${vr.violations.map((e)=>e.code).toList()}');
      return Result<OptionPresetView>.invalid(
        violations: vr.violations,
        code: 'optionPreset.update.invalid',
      );
    }

    await _repo.upsert(normalized);
    return Result<OptionPresetView>.ok(
      data: OptionPresetView.fromModel(normalized),
      code: 'optionPreset.update.ok',
      ctx: {'name': normalized.name},
    );
  }

  Future<Result<OptionPresetView>> cloneView(
      String sourceId, {
        required String duplicateSuffix,
      }) async {
    logI(_tag, 'op=clone src=$sourceId');

    final src = await _repo.findById(sourceId);
    if (src == null) {
      logW(_tag, 'op=clone msg=notFound id=$sourceId');
      return const Result<OptionPresetView>.notFound(code: 'optionPreset.clone.notFound');
    }

    final suffix = duplicateSuffix.trim();
    final newName = suffix.isEmpty ? src.name : '${src.name} $suffix';
    final copy = src.duplicated(newName);
    final normalized = OptionPresetPolicy.normalize(copy);
    final vr = OptionPresetPolicy.validate(normalized);
    if (!vr.isOk) {
      logW(_tag, 'op=clone msg=invalid violations=${vr.violations.map((e)=>e.code).toList()}');
      return Result<OptionPresetView>.invalid(
        violations: vr.violations,
        code: 'optionPreset.clone.invalid',
      );
    }

    await _repo.upsert(normalized);
    return Result<OptionPresetView>.ok(
      data: OptionPresetView.fromModel(normalized),
      code: 'optionPreset.clone.ok',
      ctx: {'name': normalized.name},
    );
  }

  // ── Sorting ───────────────────────────────────────────────────────────
  Future<Result<void>> reorderOptionPresets(
      List<String> orderedIds, {
        bool strict = true,
      }) async {
    try {
      await _repo.reorderByIds(orderedIds, strict: strict);
      return const Result.ok(code: 'optionPreset.reorder.ok');
    } on ArgumentError catch (e, st) {
      logE(_tag, 'op=reorder msg=invalid orderedIds', e, st);
      return Result.failure(code: 'optionPreset.reorder.invalid', ctx: {'error': e.toString()});
    } catch (e, st) {
      logE(_tag, 'op=reorder msg=unexpected', e, st);
      return Result.failure(code: 'optionPreset.reorder.failure', ctx: {'error': e.toString()});
    }
  }

  // ── Internals (model fetchers) ───────────────────────────────────────────────────────────
  Future<List<OptionPreset>> _listModels() async {
    final list = await _repo.listAll(); // pos ASC
    logI(_tag, 'op=list count=${list.length}');
    return list;
  }
}
