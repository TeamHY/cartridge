import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/application/isaac_save_service.dart';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:cartridge/features/isaac/save/domain/ports/save_files_probe_port.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_eden_file_adapter.dart';
import 'package:cartridge/features/isaac/save/infra/isaac_save_codec.dart';
import 'package:cartridge/features/isaac/save/infra/save_files_probe_fs_adapter.dart';
import 'package:cartridge/features/steam/application/steam_links_service.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
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


// ─────────────────────────────────────────────────────────────────────────────
// 2) Isaac Runtime & Environment
// ─────────────────────────────────────────────────────────────────────────────
final isaacSaveServiceProvider = Provider<IsaacSaveService>((ref) {
  final users = ref.read(steamUsersPortProvider);
  return IsaacSaveService(users: users);
});

final isaacSaveCodecProvider = Provider<IsaacSaveCodec>((ref) => IsaacSaveCodec());

final isaacEdenAdapterProvider = Provider<IsaacEdenFileAdapter>((ref) {
  final codec = ref.read(isaacSaveCodecProvider);
  return IsaacEdenFileAdapter(codec: codec);
});

final edenTokensPortProvider = Provider<EdenTokensPort>(
      (ref) => ref.read(isaacEdenAdapterProvider),
);

final saveFilesProbePortProvider = Provider<SaveFilesProbePort>((ref) {
  return SaveFilesProbeFsAdapter();
});

final steamAccountsProvider = FutureProvider<List<SteamAccountProfile>>((ref) async {
  final svc = ref.read(isaacSaveServiceProvider);
  return svc.findSaveCandidates();
});


typedef EditionSlots = ({IsaacEdition edition, List<int> slots});
typedef EditionSlotsArgs = ({SteamAccountProfile acc, IsaacEdition? detected});

final editionAndSlotsProvider = FutureProvider.family<EditionSlots, EditionSlotsArgs>((ref, args) async {
  final probe = ref.read(saveFilesProbePortProvider);
  final prio  = IsaacEditionInfo.editionPriority;

  Future<IsaacEdition> autoPick() async {
    for (final e in prio) {
      final slots = await probe.listExistingSlots(args.acc, e);
      if (slots.isNotEmpty) return e;
    }
    return prio.first;
  }

  final target = args.detected ?? await autoPick();
  final slots  = await probe.listExistingSlots(args.acc, target);
  return (edition: target, slots: List<int>.from(slots)..sort());
});