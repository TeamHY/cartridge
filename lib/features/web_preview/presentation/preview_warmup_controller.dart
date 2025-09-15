import 'package:cartridge/features/isaac/mod/domain/models/installed_mod.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/preview_warmup_service.dart';
import '../application/web_preview_cache.dart';
import '../data/web_preview_repository.dart';
import 'package:cartridge/core/service_providers.dart';

typedef ModWarmupService = PreviewWarmupService<InstalledMod>;

final previewWarmupServiceProvider = Provider<PreviewWarmupService>((ref) {
  final repo = WebPreviewRepository();
  final cache = WebPreviewCache(repo);

  // 설치 모드 목록 로더(비동기) — 기존 서비스로 교체
  Future<List<InstalledMod>> loadInstalled() async {
    final env = ref.read(isaacEnvironmentServiceProvider);
    final map = await env.getInstalledModsMap(); // Map<String, InstalledMod>
    // 워크샵 ID 없는 항목은 프리뷰 대상 아님
    return map.values
        .where((m) => (m.metadata.id.isNotEmpty))
        .toList(growable: false);
  }

  String workshopIdOf(InstalledMod m) => m.metadata.id;

  String urlOf(String modId) =>
      SteamUris.workshopItem(modId);

  return ModWarmupService(
    cache: cache,
    loadInstalledMods: loadInstalled,      // Future<List<InstalledMod>>
    workshopIdOf: workshopIdOf,            // InstalledMod -> String
    workshopUrlOf: urlOf,                  // String -> String
  );
});
