import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqlite_api.dart';

import 'package:cartridge/core/infra/app_database.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/models/auth_user.dart' as cartridge;
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/cartridge/runtime/application/isaac_launcher_service.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/options/isaac_options.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/isaac/save/isaac_save.dart';
import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/features/steam_news/steam_news.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// ── 0) App-wide Database (SQLite) ───────────────────────────────────────────────────────────
final appDatabaseProvider =
Provider<Future<Database> Function()>((ref) => appDatabase);


// ── 1) Steam Layer (Ports & Adapters) ───────────────────────────────────────────────────────────
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
  final settings = ref.watch(settingServiceProvider);
  return SteamUsersVdfRepository(install: install, settings: settings);
});


// ── 2) Isaac Runtime & Environment ───────────────────────────────────────────────────────────
final isaacRuntimeServiceProvider = Provider<IsaacRuntimeService>((ref) {
  final links = ref.read(steamLinksPortProvider);
  final library = ref.read(steamLibraryPortProvider);
  return IsaacRuntimeService(links: links, library: library);
});

final isaacPathResolverProvider = Provider<IsaacPathResolver>((ref) {
// 테스트에서는 environment/documentsProvider를 주입하세요.
  return IsaacPathResolver(
// environment: {'USERPROFILE': '...'},
// documentsProvider: () => Directory('test_docs'),
  );
});

final modsServiceProvider = Provider<ModsService>((ref) {
  final library = ref.read(steamLibraryPortProvider);
  return ModsService(steamLibrary: library);
});
final isaacOptionsIniService =
Provider<IsaacOptionsIniService>((ref) => IsaacOptionsIniService());

final isaacEnvironmentServiceProvider = Provider<IsaacEnvironmentService>((ref) {
  return IsaacEnvironmentService(
    settings: ref.read(settingServiceProvider),
    isaac: ref.read(isaacRuntimeServiceProvider),
    pathResolver: ref.read(isaacPathResolverProvider),
    mods: ref.read(modsServiceProvider),
  );
});

final isaacSteamLinksProvider = Provider<IsaacSteamLinks>((ref) {
  final port = ref.read(steamLinksPortProvider);
  final sls = SteamLinksService(port: port);
  return IsaacSteamLinks(steam: sls);
});

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

// ── 3) Core Domain Services (App-wide) ───────────────────────────────────────────────────────────
// Settings (SQLite)
final settingRepositoryProvider = Provider<ISettingRepository>(
      (ref) => SqliteSettingRepository(dbOpener: ref.read(appDatabaseProvider)),
);
final settingServiceProvider = Provider<SettingService>(
      (ref) => SettingService(repo: ref.read(settingRepositoryProvider)),
);

// Option Presets (SQLite)
final optionPresetsRepositoryProvider = Provider<IOptionPresetsRepository>(
      (ref) => SqliteOptionPresetsRepository(
    dbOpener: ref.read(appDatabaseProvider),
  ),
);
final optionPresetsServiceProvider = Provider<OptionPresetsService>(
      (ref) => OptionPresetsService(
    repo: ref.read(optionPresetsRepositoryProvider),
  ),
);

// Mod Presets (SQLite)
final modPresetsRepositoryProvider = Provider<IModPresetsRepository>(
      (ref) => SqliteModPresetsRepository(
    dbOpener: ref.read(appDatabaseProvider),
  ),
);
final modPresetsServiceProvider = Provider<ModPresetsService>((ref) {
  return ModPresetsService(
    repository: ref.read(modPresetsRepositoryProvider),
    modsService: ref.read(modsServiceProvider),
    envService: ref.read(isaacEnvironmentServiceProvider),
    projector: null, // 기존 구조 유지
  );
});

// Instances (SQLite)
final instancesRepositoryProvider = Provider<IInstancesRepository>(
      (ref) => SqliteInstancesRepository(
    dbOpener: ref.read(appDatabaseProvider),
  ),
);
final instancesServiceProvider = Provider<InstancesService>((ref) {
  return InstancesService(
    repo: ref.read(instancesRepositoryProvider),
    optionPresetsService: ref.read(optionPresetsServiceProvider),
    modPresetsService: ref.read(modPresetsServiceProvider),
    modsService: ref.read(modsServiceProvider),
    envService: ref.read(isaacEnvironmentServiceProvider),
  );
});
// instances pack (export/import)
final instancePackServiceProvider = Provider<InstancePackService>((ref) {
  return InstancePackService(
    instancesRepo: ref.read(instancesRepositoryProvider),
    modPresetsRepo: ref.read(modPresetsRepositoryProvider),
    env: ref.read(isaacEnvironmentServiceProvider),
  );
});
// ── 4) Feature: Slot Machine (SQLite) ───────────────────────────────────────────────────────────
final slotMachineRepositoryProvider = Provider<ISlotMachineRepository>(
      (ref) => SqliteSlotMachineRepository(
    dbOpener: ref.read(appDatabaseProvider),
  ),
);

final slotMachineServiceProvider = Provider<SlotMachineService>(
      (ref) => SlotMachineService(
    repo: ref.read(slotMachineRepositoryProvider),
  ),
);


// ── 5) Application Services (Launch/Play) ───────────────────────────────────────────────────────────
final isaacLauncherServiceProvider = Provider<IsaacLauncherService>((ref) {
  return IsaacLauncherService(
    runtime: ref.read(isaacRuntimeServiceProvider),
    modsService: ref.read(modsServiceProvider),
    optionsIniService: ref.read(isaacOptionsIniService),
    isaacEnvironmentService: ref.read(isaacEnvironmentServiceProvider),
  );
});

final instancePlayServiceProvider = Provider<InstancePlayService>((ref) {
  return InstancePlayService(
    instances: ref.read(instancesServiceProvider),
    optionPresets: ref.read(optionPresetsServiceProvider),
    launcher: ref.read(isaacLauncherServiceProvider),
  );
});


// ── 6) UI Controllers / ViewModel-ish Providers ───────────────────────────────────────────────────────────
final optionPresetsControllerProvider =
AsyncNotifierProvider<OptionPresetsController, List<OptionPresetView>>(
  OptionPresetsController.new,
);

final repentogonInstalledProvider = FutureProvider<bool>((ref) async {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final path = await env.resolveInstallPath();
  return path != null && await Repentogon.isInstalled(path);
});

// ── 7) Record Mode (Supabase-backed) ───────────────────────────────────────────────────────────
final recordModeGoalReadServiceProvider = Provider<GoalReadService>((ref) {
  final sp = Supabase.instance.client;
  return SupabaseGoalReadService(sp);
});

final recordModeLeaderboardServiceProvider =
Provider<LeaderboardService>((ref) {
  final sp = Supabase.instance.client;
  return LeaderboardServiceImpl(sp);
});

final recordModeGameIndexServiceProvider =
Provider<GameIndexService>((ref) => DefaultGameIndexService());

final recordModeSessionServiceProvider = Provider<GameSessionService>((ref) {
  final svc = GameSessionServiceImpl(
    Supabase.instance.client,
    ref.read(isaacEnvironmentServiceProvider),
    ref.read(isaacLauncherServiceProvider),
    presetService: ref.read(recordModePresetServiceProvider),
    allowedPrefs: ref.read(recordModeAllowedPrefsServiceProvider),
  );

  ref.onDispose(svc.dispose);

  return svc;
});

final recordModeAuthUserProvider =
StreamProvider.autoDispose<cartridge.AuthUser?>((ref) {
  final auth = ref.read(recordModeAuthServiceProvider);
  return auth.authStateChanges();
});

final recordModeAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final sp = Supabase.instance.client;
  return SupabaseAuthRepository(sp);
});

final recordModeAuthServiceProvider = Provider<AuthService>((ref) {
  final sp = Supabase.instance.client;
  final repo = ref.read(recordModeAuthRepositoryProvider);
  return SupabaseAuthService(sp, repo);
});

final recordModeAllowedPrefsRepositoryProvider =
Provider<RecordModeAllowedPrefsRepository>(
      (ref) => FileRecordModeAllowedPrefsRepository(),
);

final recordModeAllowedPrefsServiceProvider =
Provider<RecordModeAllowedPrefsService>(
      (ref) => RecordModeAllowedPrefsServiceImpl(
    ref.read(recordModeAllowedPrefsRepositoryProvider),
  ),
);

final recordModePresetServiceProvider = Provider<RecordModePresetService>((ref) {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final prefs = ref.read(recordModeAllowedPrefsServiceProvider);
  return RecordModePresetServiceImpl(env, prefs);
});

final recordModeSessionProvider = Provider<GameSessionService>((ref) {
  final sp        = Supabase.instance.client;
  final env       = ref.read(isaacEnvironmentServiceProvider);
  final launcher  = ref.read(isaacLauncherServiceProvider);
  final presetSvc = ref.read(recordModePresetServiceProvider);
  final allowed   = ref.read(recordModeAllowedPrefsServiceProvider);

  final svc = GameSessionServiceImpl(
    sp, env, launcher,
    presetService: presetSvc,
    allowedPrefs: allowed,
  );
  ref.onDispose(svc.dispose);
  return svc;
});
// ── 8) Steam News ───────────────────────────────────────────────────────────
final steamNewsServiceProvider = Provider<SteamNewsService>((ref) {
  return SteamNewsService(
    repo: SteamNewsRepository(),
    api: SteamNewsApi(),
    preview: ref.read(webPreviewCacheProvider),
  );
});