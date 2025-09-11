import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';

/// ModPreset -> ModPresetView
class ModPresetProjector {
  final ModViewProjector modViewProjector;

  const ModPresetProjector({
    this.modViewProjector = const ModViewProjector(),
  });

  ModPresetView toView({
    required ModPreset preset,
    required Map<String, InstalledMod> installed,
    bool includeInstalledExtras = true, // extras = preset에 없는 설치 모드
  }) {
    final items = <ModView>[];
    final seenKeys = <String>{};
    var enabledCount = 0;

    // 1) 프리셋 엔트리
    for (final e in preset.entries) {
      if (!seenKeys.add(e.key)) continue; // duplicate preset key -> first-win
      final m = installed[e.key];
      final v = modViewProjector.compose(
        key: e.key,
        entry: e,
        installed: m,
        enabledByPresets: e.enabled == true ? <String>{preset.id} : const <String>{},
      );
      items.add(v);
      if (v.effectiveEnabled) enabledCount++;
    }

    // 2) extras: 설치되어 있으나 preset에 없는 항목
    if (includeInstalledExtras) {
      for (final entry in installed.entries) {
        final k = entry.key;
        if (seenKeys.contains(k)) continue;
        final v = modViewProjector.compose(
          key: k,
          entry: null,
          installed: entry.value,
          enabledByPresets: const <String>{},
        );
        items.add(v);
        if (v.effectiveEnabled) enabledCount++;
      }
    }

    return ModPresetView(
      key: preset.id,
      name: preset.name,
      items: items,
      totalCount: items.length,
      enabledCount: enabledCount,
      sortKey: preset.sortKey,
      ascending: preset.ascending,
      updatedAt: preset.updatedAt,
    );
  }
}
