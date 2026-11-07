import 'package:cartridge/components/dialogs/repentogon_install_dialog.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/repentogon_status.dart';
import 'package:cartridge/providers/repentogon_provider.dart';
import 'package:cartridge/utils/repentogon_error_text.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// REPENTOGON status and install / update / repair actions.
class RepentogonSettingsSection extends ConsumerStatefulWidget {
  const RepentogonSettingsSection({super.key});

  @override
  ConsumerState<RepentogonSettingsSection> createState() =>
      _RepentogonSettingsSectionState();
}

class _RepentogonSettingsSectionState
    extends ConsumerState<RepentogonSettingsSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(repentogonProvider).refreshIfInstalled());
  }

  String _statusText(AppLocalizations loc, RepentogonNotifier repentogon) {
    if (repentogon.isBusy) return loc.repentogon_status_checking;

    final error = repentogon.lastError;
    if (error != null) return describeRepentogonError(loc, error);

    final status = repentogon.status;
    if (status == null) return loc.repentogon_status_unchecked;
    if (!status.isaacValid) return loc.repentogon_status_isaac_invalid;
    if (!status.isaacCompatible) {
      return loc.repentogon_status_isaac_incompatible(
          status.isaacReason ?? loc.common_unknown);
    }
    if (status.launchable) {
      return loc.repentogon_status_ready(status.version ?? loc.common_unknown);
    }
    if (status.state == 'none') return loc.repentogon_status_not_installed;
    return loc.repentogon_status_not_launchable;
  }

  String _installLabel(AppLocalizations loc, RepentogonStatus? status) {
    if (status == null || status.state == 'none') {
      return loc.repentogon_button_install;
    }
    return status.launchable
        ? loc.repentogon_button_update
        : loc.repentogon_button_repair;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final repentogon = ref.watch(repentogonProvider);
    final status = repentogon.status;

    final isHealthy = status != null &&
        status.launchable &&
        repentogon.lastError == null &&
        !repentogon.isBusy;
    final canInstall = !repentogon.isBusy &&
        status != null &&
        status.isaacValid &&
        status.isaacCompatible;

    return AppLabeled(
      label: loc.repentogon_section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (repentogon.isBusy) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _statusText(loc, repentogon),
                  style: TextStyle(
                    color: repentogon.lastError != null
                        ? c.danger
                        : isHealthy
                            ? c.success
                            : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppButton(
                onPressed:
                    repentogon.isBusy ? null : () => repentogon.refresh(),
                child: Text(loc.repentogon_button_check),
              ),
              const SizedBox(width: 8),
              AppButton.primary(
                onPressed: canInstall
                    ? () => showAppDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const RepentogonInstallDialog(),
                        )
                    : null,
                child: Text(_installLabel(loc, status)),
              ),
              if (repentogon.cliTag != null) ...[
                const SizedBox(width: 12),
                Text(
                  loc.repentogon_cli_version(repentogon.cliTag!),
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
