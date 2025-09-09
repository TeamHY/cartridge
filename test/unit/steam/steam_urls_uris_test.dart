import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';

void main() {
  group('SteamUrls/SteamUris — Unit', () {
    test('스토어/워크샵 URL이 올바르게 생성된다 (AAA)', () {
      expect(SteamUrls.appPage(250900), 'https://store.steampowered.com/app/250900/');
      expect(SteamUrls.appWorkshopHub(250900), 'https://steamcommunity.com/app/250900/workshop/');
      expect(SteamUrls.workshopItem('123'), 'https://steamcommunity.com/sharedfiles/filedetails/?id=123');
    });

    test('Steam URI가 올바르게 생성된다 (AAA)', () {
      expect(SteamUris.appPage(250900), 'steam://url/StoreAppPage/250900'); // StoreAppPage로 수정된 버전 기준
      expect(SteamUris.gameProperties(250900), 'steam://gameproperties/250900');
      expect(SteamUris.validate(250900), 'steam://validate/250900');
      expect(SteamUris.workshopItem('123'), 'steam://url/CommunityFilePage/123');
    });

    test('openUrl 포맷 확인 (AAA)', () {
      const web = 'https://store.steampowered.com/app/250900/';
      expect(SteamUris.openUrl(web), 'steam://openurl/$web');
    });
  });
}
