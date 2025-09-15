import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/workshop_util.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/l10n/app_localizations.dart';


class AllowedModsTable extends ConsumerWidget {
  const AllowedModsTable({
    super.key,
    required this.controller,
    required this.rows,
  });

  final UTTableController<AllowedModRow> controller;
  final List<AllowedModRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    final columns = <UTColumnSpec>[
      UTColumnSpec(id: 'name', title: loc.common_name, width: UTWidth.flex(4), minPx: 180, sortable: true),
      UTColumnSpec(id: 'installed', title: loc.allowed_col_installed, width: UTWidth.px(96), sortable: true),
      UTColumnSpec(id: 'enabled', title: loc.allowed_col_enabled, width: UTWidth.px(112), sortable: true),
    ];

    int boolDesc(bool a, bool b) => (b ? 1 : 0) - (a ? 1 : 0);
    String effectiveName(AllowedModRow r) {
      if (r.alwaysOn) return r.name;
      final wid = r.workshopId;
      if (wid == null || wid.isEmpty) return r.name;
      final url = SteamUrls.workshopItem(wid);
      final previewAsync = ref.watch(webPreviewProvider(url));
      final title = previewAsync.maybeWhen(data: (p) => p?.title, orElse: () => null);
      final fromWeb = extractWorkshopModName(title);
      return (fromWeb != null && fromWeb.isNotEmpty) ? fromWeb : r.name;
    }

    final comparators = <String, int Function(AllowedModRow, AllowedModRow)>{
      'name': (a, b) => effectiveName(a).toLowerCase().compareTo(effectiveName(b).toLowerCase()),
      'installed': (a, b) => boolDesc(a.installed == true, b.installed == true),
      'enabled': (a, b) => boolDesc(a.enabled == true, b.enabled == true),
    };

    return UTTableFrame<AllowedModRow>(
      controller: controller,
      columns: columns,
      rows: rows,
      rowHeight: 52,
      compactRowHeight: 40,
      tileRowHeight: 56,
      initialDensity: UTTableDensity.compact,
      initialSortColumnId: 'installed',
      initialAscending: false,
      comparators: comparators,
      selectionEnabled: false,
      reserveLeading: false,
      showFloatingSelectionBar: false,
      cellBuilder: (ctx, r) => [
        AllowedModTitleCell(row: r),
        Icon(
          (r.installed == true) ? FluentIcons.check_mark : FluentIcons.cancel,
          size: 14,
          color: (r.installed == true)
              ? FluentTheme.of(ctx).accentColor
              : FluentTheme.of(ctx).resources.textFillColorSecondary,
        ),
        ToggleSwitch(
          // 🔒 alwaysOn: 토글 비활성 + 상태는 설치여부 기준으로 표시(설치 시 항상 켜짐)
          checked: r.alwaysOn ? (r.installed == true) : (r.enabled == true),
          onChanged: r.alwaysOn
              ? null
              : (r.installed == true)
              ? (v) async {
            final prefs = ref.read(recordModeAllowedPrefsServiceProvider);
            await prefs.setEnabled(r, v);
            ref.read(recordModeUiControllerProvider.notifier).refreshAllowedPreset();
          }
              : null,
        ),
      ],
      showSearch: true,
      searchHintText: loc.allowed_search_hint,
      stringify: (it) => '${effectiveName(it)} ${it.name} ${it.workshopId ?? ''}',
      quickFilters: [
        UTQuickFilter<AllowedModRow>(id: 'installed', label: loc.allowed_col_installed, test: (r) => r.installed == true),
        UTQuickFilter<AllowedModRow>(id: 'enabled', label: loc.allowed_col_enabled, test: (r) => r.enabled == true),
      ],
      quickFiltersAreAnd: true,
    );
  }
}
