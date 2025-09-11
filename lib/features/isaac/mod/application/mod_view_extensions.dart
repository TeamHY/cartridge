import 'package:cartridge/features/isaac/mod/domain/models/mod_view.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';

import 'package:cartridge/core/utils/workshop_util.dart';

extension ModViewUiX on ModView {
  /// 워크샵 URL (없으면 null)
  String? get workshopUrl => modId.isNotEmpty ? SteamUrls.workshopItem(modId) : null;

  /// UI 썸네일 이니셜(도메인 독립, 순수 텍스트 로직)
  String displayInitial({String fallback = 'M'}) => extractInitialAny(displayName, fallback: fallback);
}
