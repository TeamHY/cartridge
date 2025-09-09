import 'package:meta/meta.dart';

@immutable
abstract class SteamLinksPort {
  Future<void> openUri(String target);
  Future<void> openAppPage(int appId);
  Future<void> openAppWorkshopHub(int appId);
  Future<void> openWorkshopItem(String workshopId);
  Future<void> openGameProperties(int appId);
  Future<void> startVerifyIntegrity(int appId);
}
