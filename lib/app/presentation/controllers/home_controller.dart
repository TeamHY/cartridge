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



Future<bool> isRepentogonInstalled(WidgetRef ref) async {
  return await ref.read(repentogonInstalledProvider.future);
}

Future<void> openInstallFolder(BuildContext context, WidgetRef ref) async {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final path = await env.resolveInstallPath();
  if (path == null) {
    if (context.mounted) UiFeedback.warn(context, '설치 경로를 찾지 못했어요', '설치 경로 자동 탐지가 실패했습니다. Settings에서 확인해 주세요.');
    return;
  }
  if (!context.mounted) return;
  await openFolder(path);
}

Future<void> openOptionsFolder(BuildContext context, WidgetRef ref) async {
  final env = ref.read(isaacEnvironmentServiceProvider);
  final ini = await env.resolveOptionsIniPath();
  if (ini == null) {
    if (context.mounted) UiFeedback.warn(context, 'options.ini 경로를 찾지 못했어요', '자동 탐지가 실패했습니다. Settings에서 확인해 주세요.');
    return;
  }
  final dir = p.dirname(ini);
  if (!context.mounted) return;
  await openFolder(dir);
}

Future<void> openSaveFolder(BuildContext context, WidgetRef ref) async {
  const tag = 'HomeController';
  const op = 'openSaveFolder';

  logI(tag, 'op=$op fn=openSaveFolder msg=start');
  final svc = ref.read(isaacSaveServiceProvider);

  List<SteamAccountProfile> candidates;
  try {
    candidates = await svc.findSaveCandidates();
  } catch (e, st) {
    logE(tag, 'op=$op fn=openSaveFolder msg=candidate fetch failed', e, st);
    if (context.mounted) {
      UiFeedback.error(context, '조회 실패', '세이브 후보 조회 중 오류가 발생했습니다.');
    }
    return;
  }

  if (candidates.isEmpty) {
    logW(tag, 'op=$op fn=openSaveFolder msg=no candidates');
    if (context.mounted) {
      UiFeedback.warn(context, '세이브를 찾지 못했어요',
          'Steam Cloud 또는 로컬 세이브가 감지되지 않았습니다.');
    }
    return;
  }

  if (candidates.length == 1) {
    final c = candidates.first;
    logI(tag, 'op=$op fn=openSaveFolder msg=auto open '
        'accountId=${c.accountId} sid64_tail=${c.steamId64.substring(c.steamId64.length-6)} '
        'path=${c.savePath}');
    try {
      await openFolder(c.savePath);
    } catch (e, st) {
      logE(tag, 'op=$op fn=openSaveFolder msg=openFolder failed path=${c.savePath}', e, st);
      if (context.mounted) UiFeedback.error(context, '열기 실패', '폴더를 열 수 없습니다.');
    }
    return;
  }

  logI(tag, 'op=$op fn=openSaveFolder msg=multi candidates count=${candidates.length} showDialog=1');
  if (!context.mounted) return;
  final chosen = await showChooseSteamAccountDialog(context, items: candidates);
  if (chosen == null) {
    logW(tag, 'op=$op fn=openSaveFolder msg=user cancelled dialog=1');
    return;
  }

  logI(tag, 'op=$op fn=openSaveFolder msg=user selected '
      'accountId=${chosen.accountId} sid64_tail=${chosen.steamId64.substring(chosen.steamId64.length-6)} '
      'path=${chosen.savePath}');
  try {
    await openFolder(chosen.savePath);
  } catch (e, st) {
    logE(tag, 'op=$op fn=openSaveFolder msg=openFolder failed path=${chosen.savePath}', e, st);
    if (context.mounted) UiFeedback.error(context, '열기 실패', '폴더를 열 수 없습니다.');
  }
}
