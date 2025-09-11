// ComputeModViewsUseCase
// - 입력: InstalledMod(K), 선택된 ModPreset들(M), Instance(N: overrides/favorite)
// - 처리: 증분 패치(Delta) + 단일패스(Map Accumulator) 병합
// - 출력: List<ModView>
// 정책 요약:
//   * enabled = (presetEnabled || instEnable) && !instDisable && installed
//   * favorite = Instance.overrides.favorite 만 반영 (Preset favorite 무시)
//   * displayName = installed.name → instance.workshopName → preset.workshopName → key(folderName)

import 'package:cartridge/features/cartridge/instances/domain/models/instance.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

typedef ModId = String;

/// 유스케이스 본체: ModView 리스트 산출
class ComputeModViewsUseCase {
  List<ModView> call({
    required List<InstalledMod> installedMods,
    required List<ModPreset> selectedPresets,
    required Instance instance,
  }) {
    // Accumulator (id -> 누적 상태)
    final acc = <ModId, _ModMergeAccum>{};

    _ModMergeAccum get(ModId id) => acc.putIfAbsent(id, () => _ModMergeAccum());
    void addBit(ModId id, int bit) => get(id).bits |= bit;

    // 1) 설치 목록 K
    for (final im in installedMods) {
      final id = im.folderName;
      final x = get(id);
      x.bits |= _ModMergeBits.installed;
      x.installedRef ??= im;
      // 이름은 생성 단계에서 installed 메타가 최우선으로 사용됨
    }

    // 2) 프리셋 OR 누적 (favorite 무시, enabled만 반영)
    for (final p in selectedPresets) {
      for (final e in p.entries) {
        final id = e.key;
        if (e.enabled == true) {
          addBit(id, _ModMergeBits.presetEnabled);
          // 어떤 프리셋들이 이 모드를 켰는지 모두 기록 (presetId 기준)
          get(id).enabledByPresetIds.add(p.id);
        }
        // 미설치 대비 이름 힌트(설치명이 없을 때만 사용)
        get(id).presetNameHint ??= e.workshopName;
      }
    }

    // 3) 인스턴스 델타/즐겨찾기(Instance 전용)
    final overrideIndex = {for (final o in instance.overrides) o.key: o};
    for (final o in overrideIndex.values) {
      final id = o.key;
      // ★ tri-state 처리: true→instEnable, false→instDisable, null→무시
      final eo = o.enabled; // bool?
      if (eo == true) {
        addBit(id, _ModMergeBits.instEnable);
      } else if (eo == false) {
        addBit(id, _ModMergeBits.instDisable);
      }
      if (o.favorite) addBit(id, _ModMergeBits.instFavorite);
      get(id).instNameHint ??= o.workshopName; // 미설치 대비 표시명
    }

    // 4) 최종 ModView 생성(단일 맵 순회)
    final out = <ModView>[];
    acc.forEach((id, x) {
      final b = x.bits;
      final installed  = (b & _ModMergeBits.installed) != 0;      // 설치 정보
      final pEnabled   = (b & _ModMergeBits.presetEnabled) != 0;  // preset 정보
      final iEnable    = (b & _ModMergeBits.instEnable)  != 0;    // 인스턴스 정보
      final iDisable   = (b & _ModMergeBits.instDisable) != 0;    // 인스턴스 정보
      final favorite   = (b & _ModMergeBits.instFavorite)!= 0;

      // 최종/명시 활성 계산
      final effectiveEnabled = (pEnabled || iEnable) && !iDisable;
      final explicitEnabled  = (iEnable) && !iDisable;

      // 표시 이름 우선순위:
      // 1) 설치 메타 이름 → 2) 인스턴스 엔트리 이름 → 3) 프리셋 엔트리 이름 → 4) 폴더명
      final displayName =
      (x.installedRef?.metadata.name.isNotEmpty == true)
          ? x.installedRef!.metadata.name
          : (x.instNameHint ?? x.presetNameHint ?? id);

      out.add(ModView(
        id: id,
        isInstalled: installed,
        effectiveEnabled: effectiveEnabled,
        explicitEnabled: explicitEnabled,
        favorite: favorite,
        displayName: displayName,
        enabledByPresets: x.enabledByPresetIds,
        installedRef: x.installedRef,
        status: ModRowStatus.ok,
      ));
    });

    return out;
  }
}

/// 파일 내부 전용 비트플래그(구현 디테일)
class _ModMergeBits {
  static const int installed     = 1 << 0;
  static const int presetEnabled = 1 << 1;
  static const int instEnable    = 1 << 2;
  static const int instDisable   = 1 << 3;
  static const int instFavorite  = 1 << 4;
}

/// 파일 내부 전용 누적 상태(구현 디테일)
class _ModMergeAccum {
  int bits = 0;
  InstalledMod? installedRef;
  String? instNameHint;    // Instance.overrides.workshopName
  String? presetNameHint;  // Preset.entries.workshopName
  final Set<String> enabledByPresetIds = <String>{}; // 영향을 준 모든 presetId
}
