import 'package:flutter/foundation.dart';

@immutable
abstract class SteamLibraryPort {
  /// steamapps/common/{installdir}
  Future<String?> findGameInstallPath(int appId, {String? steamBaseOverride});

  /// appmanifest_{appId}.acf 의 InstalledDepots
  Future<Set<int>> readInstalledDepots(int appId, {String? steamBaseOverride});

  /// appworkshop_{appId}.acf 에서 "구독/설치된 워크샵 아이템" ID 집합
  Future<Set<int>> readWorkshopItemIdsFromAcf(int appId, {String? steamBaseOverride});

  /// steamapps/workshop/content/{appId} 폴더의 하위 디렉터리(숫자 폴더명=워크샵ID)
  /// → "설치된 스팀 워크샵 모드" ID 집합(로컬 수동 모드는 제외)
  Future<Set<int>> listWorkshopContentItemIds(int appId, {String? steamBaseOverride});
}
