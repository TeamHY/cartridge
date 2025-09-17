import 'package:cartridge/core/constants/urls.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_header_refresh_button.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

class IsaacInstallDetectCard extends ConsumerWidget {
  const IsaacInstallDetectCard({
    super.key,
    this.showRepentogon = false,
  });

  final bool showRepentogon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc   = AppLocalizations.of(context);
    final theme = FluentTheme.of(context);
    final sem   = ref.watch(themeSemanticsProvider);
    final autoInfo = ref.watch(isaacAutoInfoProvider);

    String statusMessage(InstallPathStatus s, InstallPathSource src, String? path) {
      switch (s) {
        case InstallPathStatus.ok:
          return loc.install_detect_status_ok;
        case InstallPathStatus.dirNotFound:
          return (src == InstallPathSource.manual
              ? loc.install_detect_status_dir_not_found_manual
              : loc.install_detect_status_dir_not_found_auto) + (path == null ? '' : ':\n$path');
        case InstallPathStatus.exeNotFound:
          return loc.install_detect_status_exe_not_found + (path == null ? '' : ':\n$path');
        case InstallPathStatus.autoDetectFailed:
          return loc.install_detect_status_auto_detect_failed;
        case InstallPathStatus.notConfigured:
          return loc.install_detect_status_not_configured;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.resources.controlStrokeColorDefault),
      ),
      child: autoInfo.when(
        loading: () => const SizedBox(
          height: 72,
          child: Align(alignment: Alignment.centerLeft, child: ProgressBar()),
        ),
        error: (_, __) => InfoBar(
          title: Text(loc.common_error),
          content: Text(loc.install_detect_load_failed),
          severity: InfoBarSeverity.error,
        ),
        data: (info) {
          final editionLabel = info.editionName ?? loc.install_detect_edition_unknown;

          final Widget thumb = (info.editionAsset != null)
              ? ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset(
              info.editionAsset!,
              width: 72, height: 72, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(FluentIcons.photo2, size: 32),
            ),
          )
              : Container(
            width: 72, height: 72, alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: theme.resources.controlStrokeColorDefault),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(FluentIcons.photo2, size: 28),
          );

          final badges = <BadgeSpec>[
            BadgeSpec(
              info.installSource == InstallPathSource.manual
                  ? loc.install_detect_badge_manual_path
                  : loc.install_detect_badge_auto_detected,
              info.installSource == InstallPathSource.manual ? sem.info : sem.warning,
            ),
            if (info.canUseRepentogon && info.repentogonInstalled)
              BadgeSpec(loc.option_use_repentogon_label, repentogonStatusOf(context, ref)),
          ];

          final pathLine = (info.installPath == null || info.installPath!.isEmpty)
              ? loc.install_detect_path_not_found
              : loc.install_detect_path_label(info.installPath!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  thumb,
                  Gaps.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(editionLabel, style: AppTypography.sectionTitle),
                        Gaps.h2,
                        Text(pathLine, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Gaps.h8,
                        BadgeStrip(badges: badges),
                      ],
                    ),
                  ),
                  UTHeaderRefreshButton(
                    tooltip: loc.common_refresh,
                    onRefresh: () async {
                      ref.invalidate(isaacAutoInfoProvider);
                      try {
                        final refreshed = await ref.read(isaacAutoInfoProvider.future);
                        if (!context.mounted) return;
                        final msg = statusMessage(refreshed.installStatus, refreshed.installSource, refreshed.installPath);
                        if (refreshed.installStatus == InstallPathStatus.ok) {
                          UiFeedback.success(context, title: loc.common_refresh, content: msg);
                        } else {
                          UiFeedback.warn(context, title: loc.install_detect_install_path_attention, content: msg);
                        }
                      } catch (_) {
                        if (!context.mounted) return;
                        UiFeedback.error(context, content: loc.install_detect_refresh_failed);
                      }
                    },
                  ),
                ],
              ),

              if (showRepentogon && info.canUseRepentogon && !info.repentogonInstalled) ...[
                Gaps.h8,
                Expander(
                  header: Text(loc.install_detect_repentogon_help_title),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.edition == IsaacEdition.repentance)
                        Text('· ${loc.install_detect_repentogon_help_repentance}')
                      else
                        Text('· ${loc.install_detect_repentogon_help_prerepentance}'),
                      Gaps.h8,
                      Text('※ ${loc.install_detect_repentogon_help_verify}'),
                      Gaps.h8,
                      Button(child: Text(loc.common_open),
                        onPressed: () => ul.launchUrl(
                          Uri.parse(AppUrls.repentogon),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
