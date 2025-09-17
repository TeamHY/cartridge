

import 'dart:io';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/cartridge/instances/domain/instances_service.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_view.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/option_presets_service.dart';
import 'package:cartridge/features/cartridge/runtime/application/isaac_launcher_service.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';

class InstancePlayService {
  static const _tag = 'InstancePlayService';

  final InstancesService instances;
  final OptionPresetsService optionPresets;
  final IsaacLauncherService launcher;

  InstancePlayService({
    required this.instances,
    required this.optionPresets,
    required this.launcher,
  });

  /// instanceId만으로 실행 (권장 진입점)
  Future<Process?> playByInstanceId(
      String instanceId, {
        String? optionsIniPathOverride,
        String? installPathOverride,
        List<String> extraArgs = const [],
      }) async {
    logI(_tag,
        'playByInstanceId start id=$instanceId optsOverride=${optionsIniPathOverride != null} installOverride=${installPathOverride != null} extraArgs=${extraArgs.length}');

    // 인스턴스 + 관련 뷰 확보
    final bundle = await instances.getViewWithRelated(instanceId);
    if (bundle == null) {
      logW(_tag, 'instance not found id=$instanceId');
      return null;
    }
    final (view, presetViews, optionView) = bundle;

    // 옵션 프리셋 로드 (id 없으면 기본값 처리 필요시 여기서)
    final optionPresetId = view.optionPresetId?.trim();
    final optionPreset = (optionPresetId != null && optionPresetId.isNotEmpty)
        ? await optionPresets.getById(optionPresetId) // OptionPreset 반환 메서드가 없으면 추가하세요.
        : null;           // 혹은 기본 프리셋 제공 API

    // 최종 “켜질 모드” → ModsService.applyPreset용 entries 맵 생성
    final entries = _buildEntriesFromView(view);

    try {
      final proc = await launcher.launchIsaac(
        optionPreset: optionPreset,
        entries: entries,
        optionsIniPathOverride: optionsIniPathOverride,
        installPathOverride: installPathOverride,
        extraArgs: extraArgs,
      );
      if (proc == null) {
        logW(_tag, 'launch failed instanceId=$instanceId');
      } else {
        logI(_tag, 'launch started pid=${proc.pid}');
      }
      return proc;
    } catch (e, st) {
      logE(_tag, 'launchIsaac threw', e, st);
      rethrow;
    }
  }

  /// 이미 계산된 InstanceView로 실행 (화면에서 바로 호출할 때)
  Future<Process?> playWithView(
      InstanceView view, {
        String? optionsIniPathOverride,
        String? installPathOverride,
        List<String> extraArgs = const [],
      }) async {
    logI(_tag,
        'playWithView start id=${view.id} name=${view.name} enabledCount=${view.enabledCount} optsOverride=${optionsIniPathOverride != null} installOverride=${installPathOverride != null} extraArgs=${extraArgs.length}');

    final optionPresetId = view.optionPresetId?.trim();
    final optionPreset = (optionPresetId != null && optionPresetId.isNotEmpty)
        ? await optionPresets.getById(optionPresetId)
        : null;

    final entries = _buildEntriesFromView(view);

    try {
      final proc = await launcher.launchIsaac(
        optionPreset: optionPreset,
        entries: entries,
        optionsIniPathOverride: optionsIniPathOverride,
        installPathOverride: installPathOverride,
        extraArgs: extraArgs,
      );
      if (proc == null) {
        logW(_tag, 'launch failed instanceId=${view.id}');
      } else {
        logI(_tag, 'launch started pid=${proc.pid}');
      }
      return proc;
    } catch (e, st) {
      logE(_tag, 'launchIsaac threw', e, st);
      rethrow;
    }
  }

  /// InstanceView.items(effectiveEnabled 기준) → ModsService.applyPreset 입력
  Map<String, ModEntry> _buildEntriesFromView(InstanceView view) {
    final now = DateTime.now();
    final map = <String, ModEntry>{};

    for (final v in view.items) {
      if (!v.effectiveEnabled) continue; // “켤 목록(나머지는 disable)” 정책
      final wid = (v.installedRef?.metadata.id.trim().isNotEmpty ?? false)
          ? v.installedRef!.metadata.id
          : (v.id.isNotEmpty ? v.id : null);
      map[v.id] = ModEntry(
        key: v.id,                       // folderName
        workshopId: wid,                 // 있을 때만
        workshopName: v.displayName,
        enabled: true,                   // applyPreset 입력은 “켜질 목록”
        favorite: v.favorite,            // 디스크 상태에 영향 없지만 보존 가능
        updatedAt: now,
      );
    }
    return map;
  }
}
