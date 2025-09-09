/// 스팀 클라이언트가 내부 웹뷰로 여는 대표 도메인 allowlist.
class SteamWebHosts {
  static const Set<String> allowlist = {
    'steamcommunity.com',
    'store.steampowered.com',
    'help.steampowered.com',
  };

  static bool isSteamWebUrl(Uri uri) =>
      allowlist.contains(uri.host.toLowerCase());
}

/// 정규 웹 URL (http/https)
class SteamUrls {
  /// 스토어 App 페이지
  static String appPage(int appId) =>
      'https://store.steampowered.com/app/$appId/';

  /// App 워크샵 허브
  static String appWorkshopHub(int appId) =>
      'https://steamcommunity.com/app/$appId/workshop/';

  /// 워크샵 아이템
  static String workshopItem(String id) =>
      'https://steamcommunity.com/sharedfiles/filedetails/?id=$id';

  static String workshopSearch({
    required int appId,
    required String searchText,
    String sort = 'textsearch',
  }) {
    final q = Uri.encodeQueryComponent(searchText);
    return 'https://steamcommunity.com/workshop/browse/?appid=$appId&searchtext=$q&browsesort=$sort';
  }
}

/// steam:// 프로토콜 URI
///
/// https://developer.valvesoftware.com/wiki/Steam_browser_protocol
class SteamUris {
  static String openUrl(String webUrl) => 'steam://openurl/$webUrl';
  static String gameProperties(int appId) => 'steam://gameproperties/$appId';
  static String validate(int appId) => 'steam://validate/$appId';
  /// 스토어 App 페이지
  static String appPage(int appId) =>
      'steam://url/StoreAppPage/$appId';

  static String workshopApp(int appId) => 'steam://url/SteamWorkshopPage/$appId';
  static String workshopItem(String id) => 'steam://url/CommunityFilePage/$id';
}
