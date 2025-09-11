import 'package:cartridge/features/isaac/runtime/domain/isaac_steam_ids.dart';
import 'package:cartridge/features/steam/application/steam_links_service.dart';

class IsaacSteamLinks {
  final SteamLinksService steam;
  IsaacSteamLinks({required this.steam});
  Future<void> openWebUrl(String url) => steam.openUri(url);
  Future<void> openIsaacPage() => steam.openAppPage(IsaacSteamIds.appId);
  Future<void> openIsaacWorkshopHub() => steam.openAppWorkshopHub(IsaacSteamIds.appId);
  Future<void> openIsaacWorkshopItem(String workshopId) => steam.openWorkshopItem(workshopId);
  Future<void> openIsaacProperties() => steam.openGameProperties(IsaacSteamIds.appId);
  Future<void> verifyIsaacIntegrity() => steam.startVerifyIntegrity(IsaacSteamIds.appId);
}
