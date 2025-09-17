import 'dart:convert';
import 'dart:io' as io;

import 'package:cartridge/app/presentation/widgets/app_update_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:cartridge/core/constants/urls.dart';
import 'package:cartridge/core/log.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

class AppUpdateService {
  static const _tag = 'AppUpdateService';
  bool _askedOnce = false;

  Future<void> checkAndPrompt(BuildContext context) async {
    if (_askedOnce) {
      logI(_tag, 'already asked in this run → skip');
      return;
    }
    _askedOnce = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentStr = info.version.trim(); // e.g., "4.14.1"
      final current = Version.parse(_normalizeTag(currentStr));
      logI(_tag, 'current=$current');

      final res = await http.get(
        Uri.parse(AppUrls.githubApiLatestRelease),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'cartridge-app', // 깃허브 API는 UA 없으면 403 날 수 있음
        },
      );
      if (res.statusCode != 200) {
        logW(_tag, 'latest release fetch failed | ${res.statusCode}');
        return;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (body['tag_name'] as String?)?.trim();
      if (tag == null || tag.isEmpty) {
        logW(_tag, 'tag_name missing in release payload');
        return;
      }

      final latest = Version.parse(_normalizeTag(tag));
      logI(_tag, 'latest=$latest');

      if (!context.mounted) return;
      if (current.nextMinor <= latest) {
        if (!context.mounted) return;
        await showMandatoryUpdateDialog(
          context,
          releaseUrl: Uri.parse(AppUrls.githubLatestRelease),
          latestVersionLabel: 'v${latest.toString()}',
          onAfterLaunch: () { io.exit(0); },
        );
      } else if (current < Version.parse("4.16.1")) {
        if (!context.mounted) return;
        await showOptionalUpdateDialog(
          context,
          releaseUrl: Uri.parse(AppUrls.githubLatestRelease),
          latestVersionLabel: 'v${latest.toString()}',
        );
      } else {
        logI(_tag, 'up-to-date');
      }
    } catch (e, st) {
      logE(_tag, 'check failed', e, st);
    }
  }

  String _normalizeTag(String raw) {
    final s = raw.trim();
    return (s.startsWith('v') || s.startsWith('V')) ? s.substring(1) : s;
    // 필요 시 접미 빌드메타(+build) 제거 로직도 추가 가능
  }
}
