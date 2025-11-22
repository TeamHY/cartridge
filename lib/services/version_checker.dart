import 'dart:convert';
import 'dart:io';

import 'package:cartridge/main.dart';
import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionChecker {
  static Future<void> checkAppVersion(BuildContext context) async {
    final response = await http.get(Uri.parse(AppUrls.githubApiLatestRelease));

    if (response.statusCode != 200) {
      return;
    }
    final loc = AppLocalizations.of(context);

    final latestVersion = Version.parse(jsonDecode(response.body)['tag_name']);

    if (currentVersion.nextMinor <= latestVersion && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: Text(loc.home_dialog_update_title),
            content: Text(loc.home_dialog_update_required),
            actions: [
              FilledButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(AppUrls.githubLatestRelease));
                  exit(0);
                },
                child: Text(loc.common_confirm),
              )
            ],
          );
        },
      );
    } else if (currentVersion < latestVersion && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: Text(loc.home_dialog_update_title),
            content: Text(loc.home_dialog_update_optional),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.common_cancel),
              ),
              FilledButton(
                onPressed: () {
                  launchUrl(Uri.parse(AppUrls.githubLatestRelease));
                  Navigator.pop(context);
                },
                child: Text(loc.common_confirm),
              )
            ],
          );
        },
      );
    }
  }
}
