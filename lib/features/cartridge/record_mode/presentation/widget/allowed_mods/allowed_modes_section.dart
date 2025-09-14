import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';

import 'allowed_dashboard_stats.dart';
import 'allowed_mods_dialog.dart';

class AllowedModsSection extends ConsumerStatefulWidget {
  const AllowedModsSection({super.key});
  @override
  ConsumerState<AllowedModsSection> createState() => _AllowedModsSectionState();
}

class _AllowedModsSectionState extends ConsumerState<AllowedModsSection> {
  late final UTTableController<AllowedModRow> _tableCtrl;
  @override
  void initState() {
    super.initState();
    _tableCtrl = UTTableController(initialQuery: '');
  }
  @override
  void dispose() {
    _tableCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc   = AppLocalizations.of(context);
    final ui    = ref.watch(recordModeUiControllerProvider);
    final uiCtl = ref.read(recordModeUiControllerProvider.notifier);

    final view     = ui.preset;
    final loading  = ui.loadingPreset;
    final allowed  = view?.allowedCount ?? 0;
    final installed= view?.items.where((e) => e.installed).length ?? 0;
    final enabled  = view?.items.where((e) => e.enabled).length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // header
        Row(
          children: [
            Text(loc.allowed_title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            IconButton(
              icon: const Icon(FluentIcons.refresh),
              onPressed: loading ? null : () => uiCtl.refreshAllowedPreset(),
            ),
            Gaps.w8,
            FilledButton(
              onPressed: (loading || view == null || view.items.isEmpty)
                  ? null
                  : () => showAllowedModsDialog(context, ref, controller: _tableCtrl, rows: view.items),
              child: Text(loc.allowed_list_button),
            ),
          ],
        ),
        Gaps.h8,
        AllowedDashboardStats(
          loading: loading || view == null,
          allowed: allowed,
          enabled: enabled,
          installed: installed,
        ),
      ],
    );
  }
}
