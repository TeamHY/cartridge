import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/steam/domain/steam_links_port.dart';
import 'package:cartridge/features/steam/domain/steam_link_builder.dart';

class SteamLinksService {
  static const _tag = 'SteamLinksService';
  final SteamLinksPort port;
  const SteamLinksService({required this.port});

  Future<void> openWebUrl(String url) => _safe('openWebUrl', () async {
    final target = SteamLinkBuilder.preferSteamClientIfPossible(url);
    await port.openUri(target);
  });

  Future<void> openUri(String uri) => _safe('openUri', () => port.openUri(uri));
  Future<void> openAppPage(int appId) => _safe('openAppPage', () => port.openAppPage(appId));
  Future<void> openAppWorkshopHub(int appId) => _safe('openAppWorkshopHub', () => port.openAppWorkshopHub(appId));
  Future<void> openWorkshopItem(String id) => _safe('openWorkshopItem', () => port.openWorkshopItem(id));
  Future<void> openGameProperties(int appId) => _safe('openGameProperties', () => port.openGameProperties(appId));
  Future<void> startVerifyIntegrity(int appId) => _safe('startVerifyIntegrity', () => port.startVerifyIntegrity(appId));

  Future<void> _safe(String op, Future<void> Function() run) async {
    try { await run(); }
    catch (e, st) { logE(_tag, 'op=$op msg=failed', e, st); }
  }
}
