import 'package:url_launcher/url_launcher_string.dart';
import 'package:cartridge/features/steam/domain/steam_links_port.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:cartridge/features/steam/domain/steam_link_builder.dart';

class SteamUrlLauncherAdapter implements SteamLinksPort {
  @override
  Future<void> openUri(String target) async {
    // 외부 앱(스팀 클라이언트 / 기본 브라우저)로 여는 것이 의도에 부합
    await launchUrlString(
      target,
      mode: LaunchMode.externalApplication,
    );
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
