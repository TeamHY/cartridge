import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/utils/clipboard_share.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/workshop_util.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

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
    final env = ref.read(isaacEnvironmentServiceProvider);

    // 설치된 모드 맵을 한 번만 읽어서 버전 표시에 사용
    return FutureBuilder<Map<String, InstalledMod>>(
      future: env.getInstalledModsMap(),
      builder: (ctx, snap) {
        final installedMap = snap.data ?? const <String, InstalledMod>{};

        String lc(String s) => s.toLowerCase();

        String versionOf(AllowedModRow r) {
          final k = r.key;
          if (k == null) return '';
          final m = installedMap[k];
          return m?.metadata.version ?? '';
        }
        bool effectiveEnabled(AllowedModRow r) =>
            (r.installed == true) && (r.alwaysOn || r.enabled == true);

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


        int cmpName(AllowedModRow a, AllowedModRow b) =>
            lc(effectiveName(a)).compareTo(lc(effectiveName(b)));

        int cmpVersion(AllowedModRow a, AllowedModRow b) {
          final av = versionOf(a).isEmpty ? '-' : versionOf(a);
          final bv = versionOf(b).isEmpty ? '-' : versionOf(b);
          final z = lc(av).compareTo(lc(bv));
          return z != 0 ? z : cmpName(a, b);
        }

        // true 우선(오름차순 기준) → 동률이면 이름
        int cmpInstalled(AllowedModRow a, AllowedModRow b) {
          final ai = a.installed ? 0 : 1;
          final bi = b.installed ? 0 : 1;
          final z = ai.compareTo(bi);
          return z != 0 ? z : cmpName(a, b);
        }

        // 표시상 활성 우선(오름차순 기준) → 동률이면 이름
        int cmpEnabled(AllowedModRow a, AllowedModRow b) {
          final ae = effectiveEnabled(a) ? 0 : 1;
          final be = effectiveEnabled(b) ? 0 : 1;
          final z = ae.compareTo(be);
          return z != 0 ? z : cmpName(a, b);
        }
        final columns = <UTColumnSpec>[
          UTColumnSpec(id: 'name', title: loc.common_name, width: UTWidth.flex(4), minPx: 180, sortable: true),
          UTColumnSpec(id: 'version', title: loc.mod_table_header_version, width: UTWidth.px(100), sortable: true, hideBelowPx: AppBreakpoints.sm),
          UTColumnSpec(id: 'installed', title: loc.allowed_col_installed, width: UTWidth.px(96), sortable: true),
          UTColumnSpec(id: 'enabled', title: loc.allowed_col_enabled, width: UTWidth.px(112), sortable: true),
        ];

        final comparators = <String, int Function(AllowedModRow, AllowedModRow)>{
          'name'     : (a, b) => cmpName(a, b),
          'version'  : (a, b) => cmpVersion(a, b),
          'installed': (a, b) => cmpInstalled(a, b),
          'enabled'  : (a, b) => cmpEnabled(a, b),
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
          selectionEnabled: true,
          reserveLeading: true,
          showFloatingSelectionBar: true,
          canEnable: (m)  => (m.installed == true) && !m.alwaysOn && (m.enabled == false),
          canDisable: (m) => (m.installed == true) && !m.alwaysOn && (m.enabled == true),

          onEnableSelected: (selected) async {
            final editable = selected.where((r) => r.installed == true && !r.alwaysOn).toList();
            ref.read(recordModeUiControllerProvider.notifier)
                .setAllowedEnabledManyLocal(editable, true);
            await ref.read(recordModeAllowedPrefsServiceProvider)
                .setManyByRows(editable, true);
            controller.clearSelection();
          },

          onDisableSelected: (selected) async {
            final editable = selected.where((r) => r.installed == true && !r.alwaysOn).toList();
            ref.read(recordModeUiControllerProvider.notifier)
                .setAllowedEnabledManyLocal(editable, false);
            await ref.read(recordModeAllowedPrefsServiceProvider)
                .setManyByRows(editable, false);
            controller.clearSelection();
          },
          onSharePlainSelected: (selected) async {
            final items = [
              for (final r in selected)
                ShareItem(
                  name: effectiveName(r),
                  workshopId: (r.workshopId ?? '').trim().isEmpty ? null : r.workshopId!.trim(),
                ),
            ];
            try {
              if (items.isEmpty) {
                UiFeedback.warn(context, title: loc.common_copied, content: loc.common_nothing_selected);
                return;
              }
              await ClipboardShare.copyNamesPlain(items);
              if (!context.mounted) return;
              UiFeedback.success(context, title: loc.common_copied, content: '${items.length}${loc.common_items_copied}');
            } catch (_) {
              UiFeedback.error(context, content: loc.common_copy_failed, title: loc.common_error);
            }
          },
          onShareMarkdownSelected: (selected) async {
            final items = [
              for (final r in selected)
                ShareItem(
                  name: effectiveName(r),
                  workshopId: (r.workshopId ?? '').trim().isEmpty ? null : r.workshopId!.trim(),
                ),
            ];
            try {
              if (items.isEmpty) {
                if (!context.mounted) return;
                UiFeedback.warn(context, title: loc.common_copied, content: loc.common_nothing_selected);
                return;
              }
              await ClipboardShare.copyNamesMarkdown(items);
              if (!context.mounted) return;
              UiFeedback.success(context, title: loc.common_copied, content: '${items.length}${loc.common_items_copied}');
            } catch (_) {
              UiFeedback.error(context, content: loc.common_copy_failed, title: loc.common_error);
            }
          },
          onShareRichSelected: (selected) async {
            final items = [
              for (final r in selected)
                ShareItem(
                  name: effectiveName(r),
                  workshopId: (r.workshopId ?? '').trim().isEmpty ? null : r.workshopId!.trim(),
                ),
            ];
            try {
              if (items.isEmpty) {
                if (!context.mounted) return;
                UiFeedback.warn(context, title: loc.common_copied, content: loc.common_nothing_selected);
                return;
              }
              await ClipboardShare.copyNamesRich(items);
              if (!context.mounted) return;
              UiFeedback.success(context, title: loc.common_copied, content: '${items.length}${loc.common_items_copied}');
            } catch (_) {
              UiFeedback.error(context, content: loc.common_copy_failed, title: loc.common_error);
            }
          },
          cellBuilder: (ctx, r) {
            final isInstalled = r.installed == true;
            final checked = isInstalled && (r.alwaysOn ? true : (r.enabled == true));
            final sem = ProviderScope.containerOf(ctx).read(themeSemanticsProvider);

            return [
              AllowedModTitleCell(row: r, version: versionOf(r)),   // 이름 타일(좁을 때 버전 라인/뱃지처럼 아래로 붙음)
              Text(versionOf(r).isEmpty ? '—' : versionOf(r)),      // 버전 컬럼
              // 설치 여부 아이콘
              Icon(
                (r.installed == true) ? FluentIcons.check_mark : FluentIcons.cancel,
                size: 16,
                color: (r.installed == true)
                    ? FluentTheme.of(ctx).accentColor
                    : sem.danger.fg,
              ),
              // 활성 토글 (alwaysOn은 잠금)
              ToggleSwitch(
                checked: checked,
                onChanged: (!isInstalled || r.alwaysOn)
                    ? null
                    : (v) async {
                  ref.read(recordModeUiControllerProvider.notifier)
                      .setAllowedEnabledLocal(r, v);
                  await ref.read(recordModeAllowedPrefsServiceProvider)
                      .setEnabled(r, v);
                  controller.clearSelection();
                },
              ),
            ];
          },

          showSearch: true,
          searchHintText: loc.allowed_search_hint,
          stringify: (it) => '${effectiveName(it)} ${it.name} ${it.workshopId ?? ''} ${versionOf(it)}',

          quickFilters: [
            UTQuickFilter<AllowedModRow>(id: 'installed', label: loc.allowed_col_installed, test: (r) => r.installed == true),
            UTQuickFilter<AllowedModRow>(id: 'enabled', label: loc.allowed_col_enabled, test: (r) => effectiveEnabled(r)),
            UTQuickFilter<AllowedModRow>(id: 'missing', label: loc.allowed_col_missing, test: (r) => r.installed == false),
          ],
          quickFiltersAreAnd: true,
        );
      },
    );
  }
}
