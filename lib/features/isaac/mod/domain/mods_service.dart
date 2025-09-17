import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_steam_ids.dart';
import 'package:cartridge/features/steam/domain/steam_library_port.dart';

/// {@template mods_service}
/// # ModsService
///
/// 설치 모드 목록 조회와 프리셋 적용을 제공하는 **Domain Service**.
///
/// ## 유스케이스(Use cases)
/// - [getInstalledMap]: 루트 경로에서 설치 모드 스캔(Map, 불변)
/// - [applyPreset]: 요청된 [ModEntry] (key=폴더명) 기준으로 활성/비활성 적용
///
/// ## 전제(Preconditions)
/// - 스캔/적용의 상세는 [ModsRepository]가 수행
/// - 본 서비스는 정책/로깅/파라미터 전달을 책임
///
/// ## 비기능(Non-functional)
/// - 성능: 동시성은 Repository 생성 시 기본값으로 제어
///
/// ## 정책(Policy)
/// - Windows 전용. 키는 **실제 폴더명**.
/// - 요청 Map에 **없는 폴더는 OFF**(disable.it 생성), 있는 폴더에서 `enabled==true`만 ON.
/// {@endtemplate}
/// {@macro mods_service}
class ModsService {
  static const _tag = 'ModsService';
  final ModsRepository repo;
  final SteamLibraryPort? _steamLibrary;

  ModsService({
    ModsRepository? repository,
    SteamLibraryPort? steamLibrary,
  })  : repo = repository ??
            ModsRepository(
              defaultScanConcurrency: 16,
              defaultApplyConcurrency: 16,
            ),
        _steamLibrary = steamLibrary;

  /// 설치된 모드 목록 조회.
  ///
  /// 파라미터:
  /// - [root]: 설치 루트 경로.
  ///
  /// 반환:
  /// - [Map<InstalledMod>] (루트 폴더가 없거나 비어 있으면 Empty Map)
  Future<Map<String, InstalledMod>> getInstalledMap(
      String root, {
        int? appId = IsaacSteamIds.appId,
        String? steamBaseOverride,
      }) async {
    logI(_tag, 'op=list fn=getInstalledMap msg=시작 root=$root appId=$appId');
    final raw = await repo.scanInstalledMap(root);

    // appId가 없거나 steamLibrary가 없으면 그냥 반환(호환)
    if (appId == null || _steamLibrary == null) {
      logI(_tag, 'op=list fn=getInstalledMap msg=완료(count=${raw.length}) origin=skip');
      return raw;
    }

    // 1) 구독/설치 워크샵 ID 수집
    final acfIds = await _steamLibrary!.readWorkshopItemIdsFromAcf(
      appId, steamBaseOverride: steamBaseOverride,
    );
    logI(_tag, 'op=list fn=getInstalledMap msg=workshop ids=${acfIds.length}');

    // 2) 각 모드별로 origin 결정
    final withOrigin = <String, InstalledMod>{};
    raw.forEach((folder, mod) {
      final origin = _decideOrigin(folder, mod, acfIds);
      withOrigin[folder] = mod.copyWith(origin: origin);
    });

    logI(_tag, 'op=list fn=getInstalledMap msg=완료(count=${withOrigin.length}) origin=resolved');
    return withOrigin;
  }

  /// 프리셋 적용: `requested[key].enabled == true`만 ON, 그 외 OFF
  ///
  /// 파라미터:
  /// - [root]: 설치 루트 경로.
  /// - [requested]: 사용자가 선택/요청한 [ModEntry] 목록.
  Future<void> applyPreset(String root, Map<String, ModEntry> requested) async {
    logI(_tag, 'op=apply fn=applyPreset msg=시작 entries=${requested.length} root=$root');
    await repo.applyPreset(root, requested);
    logI(_tag, 'op=apply fn=applyPreset msg=완료 root=$root');
  }


  ModInstallOrigin _decideOrigin(
      String folder,
      InstalledMod mod,
      Set<int> workshopIds,
      ) {
    // 후보 1: metadata.id
    int? asInt(String s) => int.tryParse(s.trim());
    int? id = mod.metadata.id.isNotEmpty ? asInt(mod.metadata.id) : null;

    // 후보 2: 폴더명 접미사 _<digits>
    id ??= _extractFolderSuffixNumericId(folder);

    if (id != null && workshopIds.contains(id)) {
      return ModInstallOrigin.workshop;
    }

    return ModInstallOrigin.local;
  }

  int? _extractFolderSuffixNumericId(String folder) {
    final m = RegExp(r'_(\d+)$').firstMatch(folder);
    return (m == null) ? null : int.tryParse(m.group(1)!);
  }
}
