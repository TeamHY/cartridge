import 'package:cartridge/features/steam/domain/steam_app_urls.dart';

/// 스팀 클라이언트가 내부 웹뷰로 열 수 있으면 steam:// 로 감싸고, 아니면 원본 유지.
class SteamLinkBuilder {
  static String preferSteamClientIfPossible(String webUrl) {
    try {
      final uri = Uri.parse(webUrl);
      if (uri.scheme.startsWith('http') && SteamWebHosts.isSteamWebUrl(uri)) {
        return SteamUris.openUrl(webUrl);
      }
    } catch (_) {}
    return webUrl;
  }
}
