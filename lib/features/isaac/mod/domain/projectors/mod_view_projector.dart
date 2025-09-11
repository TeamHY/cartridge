import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

/// ModEntry / InstalledMod 를 받아 ModView로 **합성**하는 Projector.
/// - View 내부 규칙(이름 보정, effectiveEnabled, status 등)을 한 곳에서 관리합니다.
/// - Service/Projector에서만 사용하세요(UI에서 직접 호출 금지).
class ModViewProjector {
  const ModViewProjector();

  /// 합성(Entry + Installed + Preset 기여)
  ///
  /// 규칙:
  /// - workshopId/name: installed 우선, 비어있으면 entry 값 사용
  /// - version/directory/visibility/tags: installed 기준
  /// - explicitEnabled: entry.enabled
  /// - effectiveEnabled: explicitEnabled || enabledByPresets.isNotEmpty
  /// - status: effectiveEnabled && !isInstalled → warning, 그 외 ok
  ModView compose({
    required String key,
    ModEntry? entry,
    InstalledMod? installed,
    Set<String> enabledByPresets = const <String>{},
    Map<String, String>? presetNameLookup,
    ModRowStatus? statusOverride,
  }) {
    final isInstalled = installed != null;

    String? pickInstalledFirst(String? a, String? b) {
      final ai = (a ?? '').trim();
      if (ai.isNotEmpty) return ai;
      final bi = (b ?? '').trim();
      return bi.isNotEmpty ? bi : null;
    }

    final name = pickInstalledFirst(
      installed?.metadata.name,
      entry?.workshopName,
    ) ?? '알 수 없는 모드';

    final explicitEnabled = entry?.enabled ?? false;
    final favorite = entry?.favorite ?? false;

    final effectiveEnabled = explicitEnabled || enabledByPresets.isNotEmpty;

    final status = statusOverride ??
        (() {
          if (isInstalled && installed.metadata.directory != key) {
            return ModRowStatus.error; // 키 불일치
          }
          if (effectiveEnabled && !isInstalled) {
            return ModRowStatus.warning; // 활성인데 미설치
          }
          return ModRowStatus.ok;
        }());

    return ModView(
      id: key,
      isInstalled: isInstalled,
      explicitEnabled: explicitEnabled,
      effectiveEnabled: effectiveEnabled,
      favorite: favorite,
      displayName: name,
      installedRef: installed,
      status: status,
      enabledByPresets: enabledByPresets,
      updatedAt: entry?.updatedAt,
    );
  }
}
