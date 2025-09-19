import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/shell_open.dart';
import 'package:cartridge/features/isaac/save/isaac_save.dart';
import 'package:cartridge/features/steam/steam.dart';

final vanillaPresetIdProvider = StateProvider<String?>((ref) => null);
final recentInstanceIdProvider = StateProvider<String?>((ref) => null);
const _tag = 'HomeController';


Future<bool> isRepentogonInstalled(WidgetRef ref) async {
  return await ref.watch(repentogonInstalledProvider.future);
}

Future<void> openInstallFolder(BuildContext context, WidgetRef ref) async {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final path = await env.resolveInstallPath();
  if (!context.mounted) return;
  final loc = AppLocalizations.of(context);
  if (path == null) {
    if (context.mounted) {
      UiFeedback.warn(
        context,
        title: loc.home_open_install_fail_title,
        content: loc.home_open_install_fail_desc,
      );
    }
    return;
  }
  if (!context.mounted) return;
  await openFolder(path);
}

Future<void> openOptionsFolder(BuildContext context, WidgetRef ref) async {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final ini = await env.resolveOptionsIniPath();
  if (!context.mounted) return;
  final loc = AppLocalizations.of(context);
  if (ini == null) {
    if (context.mounted) {
      UiFeedback.warn(
        context,
        title: loc.home_open_options_fail_title,
        content: loc.home_open_options_fail_desc,
      );
    }
    return;
  }
  final dir = p.dirname(ini);
  if (!context.mounted) return;
  await openFolder(dir);
}

Future<void> openSaveFolder(BuildContext context, WidgetRef ref) async {
  const op = 'openSaveFolder';

  logI(_tag, 'op=$op fn=openSaveFolder msg=start');
  final svc = ref.read(isaacSaveServiceProvider);
  if (!context.mounted) return;
  final loc = AppLocalizations.of(context);

  List<SteamAccountProfile> candidates;
  try {
    candidates = await svc.findSaveCandidates();
  } catch (e, st) {
    logE(_tag, 'op=$op fn=openSaveFolder msg=candidate fetch failed', e, st);
    if (context.mounted) {
      UiFeedback.error(
        context,
        title: loc.home_save_candidates_fail_title,
        content: loc.home_save_candidates_fail_desc,
      );
    }
    return;
  }

  if (candidates.isEmpty) {
    logW(_tag, 'op=$op fn=openSaveFolder msg=no candidates');
    if (context.mounted) {
      UiFeedback.warn(
        context,
        title: loc.common_not_found,
        content: loc.home_save_not_found_desc,
      );
    }
    return;
  }

  if (candidates.length == 1) {
    final c = candidates.first;
    logI(_tag, 'op=$op fn=openSaveFolder msg=auto open '
        'accountId=${c.accountId} sid64_tail=${c.steamId64.substring(c.steamId64.length-6)} '
        'path=${c.savePath}');
    try {
      await openFolder(c.savePath);
    } catch (e, st) {
      logE(_tag, 'op=$op fn=openSaveFolder msg=openFolder failed path=${c.savePath}', e, st);
      if (context.mounted) {
        UiFeedback.error(context, content: loc.common_open_folder_fail_desc);
      }
    }
    return;
  }

  logI(_tag, 'op=$op fn=openSaveFolder msg=multi candidates count=${candidates.length} showDialog=1');
  if (!context.mounted) return;
  final chosen = await showChooseSteamAccountDialog(context, items: candidates);
  if (chosen == null) {
    logW(_tag, 'op=$op fn=openSaveFolder msg=user cancelled dialog=1');
    return;
  }

  logI(_tag, 'op=$op fn=openSaveFolder msg=user selected '
      'accountId=${chosen.accountId} sid64_tail=${chosen.steamId64.substring(chosen.steamId64.length-6)} '
      'path=${chosen.savePath}');
  try {
    await openFolder(chosen.savePath);
  } catch (e, st) {
    logE(_tag, 'op=$op fn=openSaveFolder msg=openFolder failed path=${chosen.savePath}', e, st);
    if (context.mounted) {
      UiFeedback.error(context, content: loc.common_open_folder_fail_desc);
    }
  }
}

Future<void> _showSteamClientError(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  UiFeedback.error(
    context,
    content: loc.steam_action_fail_desc,
  );
}


Future<void> runIntegrityCheck(BuildContext context, WidgetRef ref) async {
  const op = 'runIntegrityCheck';

  final isaac = ref.read(isaacRuntimeServiceProvider);
  try {
    await isaac.runIntegrityCheck();
    logI(_tag, 'op=$op msg=deeplink_sent');
  } catch (e, st) {
    logE(_tag, 'op=$op msg=deeplink_failed', e, st);
    if (context.mounted) await _showSteamClientError(context);
  }
}

Future<void> openGameProperties(BuildContext context, WidgetRef ref) async {
  const op = 'openGameProperties';

  final isaac = ref.read(isaacRuntimeServiceProvider);
  try {
    await isaac.openGameProperties();
    logI(_tag, 'op=$op msg=deeplink_sent');
  } catch (e, st) {
    logE(_tag, 'op=$op msg=deeplink_failed', e, st);
    if (context.mounted) await _showSteamClientError(context);
  }
}
