import 'package:cartridge/core/log.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cartridge/features/steam/domain/steam_links_port.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:cartridge/features/steam/domain/steam_link_builder.dart';

class SteamUrlLauncherAdapter implements SteamLinksPort {
  static const _tag = 'SteamUrlLauncherAdapter';

  @override
  Future<void> openUri(String target) async {
    logI(_tag, 'launch target=$target');
    try {
      final ok = await launchUrlString(
        target,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        logW(_tag, 'launch failed target=$target');
      }
    } catch (e, st) {
      logE(_tag, 'launch exception target=$target', e, st);
      rethrow;
    }
  }

  @override
  Future<void> openAppPage(int appId) =>
      openUri(SteamLinkBuilder.preferSteamClientIfPossible(
        SteamUrls.appPage(appId),
      ));

  @override
  Future<void> openAppWorkshopHub(int appId) =>
      openUri(SteamUris.workshopApp(appId));

  @override
  Future<void> openWorkshopItem(String id) =>
      openUri(SteamUris.workshopItem(id));

  @override
  Future<void> openGameProperties(int appId) =>
      openUri(SteamUris.gameProperties(appId));

  @override
  Future<void> startVerifyIntegrity(int appId) =>
      openUri(SteamUris.validate(appId));
}
