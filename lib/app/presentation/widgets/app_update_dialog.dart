import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 필수(차단) 업데이트 다이얼로그
Future<void> showMandatoryUpdateDialog(
    BuildContext context, {
      required Uri releaseUrl,
      String? latestVersionLabel, // 예: "v4.15.0"
      VoidCallback? onBeforeLaunch, // (선택) 브라우저 열기 전 훅
      VoidCallback? onAfterLaunch,  // (선택) 브라우저 연 후 훅 (예: exit(0))
    }) {
  final theme = fluent.FluentTheme.of(context);
  final accent = theme.accentColor.normal;
  final loc = AppLocalizations.of(context);

  return fluent.showDialog<void>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      title: Row(
        children: [
          fluent.Icon(fluent.FluentIcons.update_restore, size: 18, color: accent),
          Gaps.w4,
          Text(loc.home_dialog_update_title),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 240),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.home_dialog_update_required,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (latestVersionLabel != null) ...[
            Gaps.h8,
            Text(latestVersionLabel, style: theme.typography.caption),
          ],
        ],
      ),
      actions: [
        fluent.FilledButton(
          child: Text(loc.common_confirm),
          onPressed: () async {
            onBeforeLaunch?.call();
            unawaited(launchUrl(releaseUrl));
            onAfterLaunch?.call();
          },
        ),
      ],
    ),
  );
}

/// 선택 업데이트 다이얼로그
Future<void> showOptionalUpdateDialog(
    BuildContext context, {
      required Uri releaseUrl,
      String? latestVersionLabel,
    }) {
  final theme = fluent.FluentTheme.of(context);
  final accent = theme.accentColor.normal;
  final loc = AppLocalizations.of(context);

  return fluent.showDialog<void>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      title: Row(
        children: [
          fluent.Icon(fluent.FluentIcons.cloud_download, size: 18, color: accent),
          Gaps.w4,
          Text(loc.home_dialog_update_title),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 240),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.home_dialog_update_optional,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (latestVersionLabel != null) ...[
            Gaps.h8,
            Text(latestVersionLabel, style: theme.typography.caption),
          ],
        ],
      ),
      actions: [
        fluent.Button(
          child: Text(loc.common_cancel),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        fluent.FilledButton(
          child: Text(loc.common_confirm),
          onPressed: () async {
            Navigator.of(ctx).pop();
            unawaited(launchUrl(releaseUrl));
          },
        ),
      ],
    ),
  );
}
