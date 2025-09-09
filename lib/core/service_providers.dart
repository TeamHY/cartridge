import 'package:cartridge/features/steam/application/steam_links_service.dart';
import 'package:cartridge/features/steam/domain/steam_install_port.dart';
import 'package:cartridge/features/steam/domain/steam_library_port.dart';
import 'package:cartridge/features/steam/domain/steam_links_port.dart';
import 'package:cartridge/features/steam/domain/steam_users_port.dart';
import 'package:cartridge/features/steam/infra/links/steam_url_launcher_adapter.dart';
import 'package:cartridge/features/steam/infra/steam_users_vdf_repository.dart';
import 'package:cartridge/features/steam/infra/windows/steam_app_library.dart';
import 'package:cartridge/features/steam/infra/windows/steam_install_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// ─────────────────────────────────────────────────────────────────────────────
// 1) Steam Layer (Ports & Adapters)
// ─────────────────────────────────────────────────────────────────────────────
// Links (url_launcher 단독)
final steamLinksPortProvider = Provider<SteamLinksPort>((ref) {
  return SteamUrlLauncherAdapter();
});

final steamLinksServiceProvider = Provider<SteamLinksService>((ref) {
  return SteamLinksService(port: ref.watch(steamLinksPortProvider));
});

// Install locator (스팀 설치 경로)
final steamInstallPortProvider = Provider<SteamInstallPort>((ref) {
  return WindowsSteamInstallLocator();
});

// Steam library (appmanifest/appworkshop 파싱 등) — 설치 경로 주입
final steamLibraryPortProvider = Provider<SteamLibraryPort>((ref) {
  final install = ref.watch(steamInstallPortProvider);
  return SteamAppLibrary(install: install);
});

// Steam users (loginusers.vdf/세이브 경로) — 설치 경로 주입
final steamUsersPortProvider = Provider<SteamUsersPort>((ref) {
  final install = ref.watch(steamInstallPortProvider);
  return SteamUsersVdfRepository(install: install);
});