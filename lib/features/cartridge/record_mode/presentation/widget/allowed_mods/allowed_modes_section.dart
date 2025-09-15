import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';


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
    final loc = AppLocalizations.of(context);
    final (view, loading) = ref.watch(
      recordModeUiControllerProvider.select((s) => (s.preset, s.loadingPreset)),
    );

    final allowed = view?.allowedCount ?? 0;
    final installed = view?.items.where((e) => e.installed).length ?? 0;
    final enabled   = view?.items.where((e) => e.enabled).length ?? 0;

    final uiCtl = ref.read(recordModeUiControllerProvider.notifier);

    final header = Row(
      children: [
        Text(loc.allowed_title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const Spacer(),
        IconButton(
          icon: const Icon(FluentIcons.refresh),
          onPressed: loading ? null : () => uiCtl.refreshAllowedPreset(),
        ),
        Gaps.w8,
        FilledButton(
          onPressed: (loading || view == null || view.items.isEmpty)
              ? null
              : () =>
              showAllowedModsDialog(
                  context, ref, controller: _tableCtrl, rows: view.items),
          child: Text(loc.allowed_list_button),
        ),
      ],
    );

    final stats = AllowedDashboardStats(
      loading: loading || view == null,
      allowed: allowed,
      enabled: enabled,
      installed: installed,
    );

    return LayoutBuilder(
      builder: (context, c) {
        final bounded = c.hasBoundedHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Gaps.h12,
            if (bounded)
              Expanded(child: stats)
            else
              stats,
          ],
        );
      },
    );
  }
}
