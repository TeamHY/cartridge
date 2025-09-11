import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/workshop_util.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/theme/theme.dart';

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
    final ui = ref.watch(recordModeUiControllerProvider);
    final uiCtrl = ref.read(recordModeUiControllerProvider.notifier);

    final view = ui.preset;
    final loading = ui.loadingPreset;

    final allowed = view?.allowedCount ?? 0;
    final installed = view?.items.where((e) => e.installed).length ?? 0;
    final enabled = view?.items.where((e) => e.enabled).length ?? 0;

    return sectionCard(
      context,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Row(
            children: [
              const Text('허용 모드', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(FluentIcons.refresh),
                onPressed: loading ? null : () => uiCtrl.refreshAllowedPreset(),
              ),
              Gaps.w8,
              FilledButton(
                onPressed: loading || view == null || view.items.isEmpty
                    ? null
                    : () => _showAllowedModsDialog(context, view),
                child: const Text('목록 보기'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LazySwitcher(
            loading: loading,
            skeleton: const _AllowedModsSkeleton(),
            empty: const SizedBox.shrink(),
            child: (view == null)
                ? const SizedBox.shrink()
                : SizedBox(
              height: 250,
              child: _DashboardStats(
                allowed: allowed,
                enabled: enabled,
                installed: installed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAllowedModsDialog(BuildContext context, GamePresetView view) async {
    final uiCtrl = ref.read(recordModeUiControllerProvider.notifier);
    await showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 980),
        title: const Text('허용 모드 목록'),
        content: SizedBox(
          width: 940,
          height: 560,
          child: _AllowedModsTable(
            controller: _tableCtrl,
            rows: view.items,
          ),
        ),
        actions: [
          Button(
            child: const Text('새로고침'),
            onPressed: () async {
              await uiCtrl.refreshAllowedPreset();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(); // 간단히 닫고 다시 열게 두거나, 필요시 상태만 갱신하도록 변경 가능
            },
          ),
          Button(child: const Text('닫기'), onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.allowed, required this.enabled, required this.installed});
  final int allowed;
  final int enabled;
  final int installed;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final missing = (allowed - installed).clamp(0, allowed);

    Widget tile(String label, int value, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.resources.cardBackgroundFillColorDefault,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.resources.controlStrokeColorDefault, width: .8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: t.accentColor),
            Gaps.h12,
            Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A))),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: tile('허용 모드', allowed, FluentIcons.accept)),
        Gaps.w12,
        Expanded(child: tile('활성', enabled, FluentIcons.power_button)),
        Gaps.w12,
        Expanded(child: tile('설치됨', installed, FluentIcons.accept_medium)),
        Gaps.w12,
        Expanded(child: tile('미설치', missing, FluentIcons.cancel)),
      ],
    );
  }
}

// ───────────────── 다이얼로그 테이블 ─────────────────
class _AllowedModsTable extends ConsumerWidget {
  const _AllowedModsTable({
    required this.controller,
    required this.rows,
  });

  final UTTableController<AllowedModRow> controller;
  final List<AllowedModRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = <UTColumnSpec>[
      UTColumnSpec(id: 'name', title: '이름', width: UTWidth.flex(4), minPx: 180, sortable: true),
      UTColumnSpec(id: 'installed', title: '설치됨', width: UTWidth.px(96), sortable: true),
      UTColumnSpec(id: 'enabled', title: '활성', width: UTWidth.px(112), sortable: true),
    ];

    int boolDesc(bool a, bool b) => (b ? 1 : 0) - (a ? 1 : 0);
    String effectiveName(AllowedModRow r) {
      // 항상On 모드는 웹 프리뷰/링크 불가 → 그냥 로컬 이름 사용
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
        _TitleCell(row: r),
        Icon(
          (r.installed == true) ? FluentIcons.check_mark : FluentIcons.cancel,
          size: 14,
          color: (r.installed == true)
              ? FluentTheme.of(ctx).accentColor
              : FluentTheme.of(ctx).resources.textFillColorSecondary,
        ),
        // 🔒 alwaysOn: 토글 비활성 + 상태는 설치여부 기준으로 표시(설치 시 항상 켜짐)
        ToggleSwitch(
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
      searchHintText: '모드 검색',
      stringify: (it) => '${effectiveName(it)} ${it.name} ${it.workshopId ?? ''}',
      quickFilters: [
        UTQuickFilter<AllowedModRow>(id: 'installed', label: '설치됨', test: (r) => r.installed == true),
        UTQuickFilter<AllowedModRow>(id: 'enabled', label: '활성', test: (r) => r.enabled == true),
      ],
      quickFiltersAreAnd: true,
    );
  }
}

// ───────────────── 이름 셀: alwaysOn이면 링크/프리뷰 비활성 ─────────────────
class _TitleCell extends ConsumerWidget {
  const _TitleCell({required this.row});
  final AllowedModRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = row.alwaysOn;

    // alwaysOn이면 웹 프리뷰도 불필요 → 그냥 이름 그대로, 링크 없음
    if (isLocked) {
      final stub = ModView(
        id: 'allowed_${row.name}',
        isInstalled: row.installed == true,
        explicitEnabled: true,
        effectiveEnabled: true,
        favorite: false,
        displayName: row.name,
        installedRef: (row.installed == true)
            ? InstalledMod(
          metadata: ModMetadata(
            id: '',
            name: row.name,
            directory: '',
            version: '',
            visibility: ModVisibility.unknown,
            tags: const <String>[],
          ),
          disabled: false,
          installPath: '',
        )
            : null,
        status: ModRowStatus.ok,
        enabledByPresets: const {},
        updatedAt: DateTime.now(),
      );

      // 🔒 링크 X, 토글 X
      return Row(
        children: [
          Expanded(
            child: ModTitleCell(
              row: stub,
              displayName: row.name,
              showVersionUnderTitle: false,
              onTapTitle: null, // 링크 금지
              placeholderFallback: 'M',
              prewarmPreview: false,
            ),
          ),
          const SizedBox(width: 6),
          const Tooltip(
            message: '대회 필수 모드 — 항상 활성화',
            child: Icon(FluentIcons.lock_solid, size: 14),
          ),
        ],
      );
    }

    // 일반 모드: 워크샵 제목/이미지 프리뷰 가능 + 링크 로직(아이템 또는 검색)
    final wid = row.workshopId ?? '';
    final url = wid.isEmpty ? null : SteamUrls.workshopItem(wid);
    final name = () {
      if (url == null) return row.name;
      final previewAsync = ref.watch(webPreviewProvider(url));
      final title = previewAsync.maybeWhen(data: (p) => p?.title, orElse: () => null);
      final fromWeb = extractWorkshopModName(title);
      return (fromWeb != null && fromWeb.isNotEmpty) ? fromWeb : row.name;
    }();

    final stub = ModView(
      id: wid.isNotEmpty ? 'allowed_$wid' : 'allowed_${row.name}',
      isInstalled: row.installed == true,
      explicitEnabled: row.enabled == true,
      effectiveEnabled: row.enabled == true,
      favorite: false,
      displayName: name,
      installedRef: (row.installed == true)
          ? InstalledMod(
        metadata: ModMetadata(
          id: wid,
          name: row.name,
          directory: '',
          version: '',
          visibility: ModVisibility.unknown,
          tags: const <String>[],
        ),
        disabled: !(row.enabled == true),
        installPath: '',
      )
          : null,
      status: ModRowStatus.ok,
      enabledByPresets: const {},
      updatedAt: DateTime.now(),
    );

    Future<void> open() async {
      final links = ref.read(isaacSteamLinksProvider);
      if (wid.isNotEmpty) {
        await links.openIsaacWorkshopItem(wid);
      } else {
        final q = name.isNotEmpty ? name : row.name;
        final searchUrl = SteamUrls.workshopSearch(appId: IsaacSteamIds.appId, searchText: q);
        await links.openWebUrl(searchUrl);
      }
    }

    return ModTitleCell(
      row: stub,
      displayName: name,
      showVersionUnderTitle: false,
      onTapTitle: open,
      placeholderFallback: 'M',
      prewarmPreview: true,
    );
  }
}

class _AllowedModsSkeleton extends StatelessWidget {
  const _AllowedModsSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final fill = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    Widget bar(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stroke, width: .8),
      ),
    );

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          bar(32),
          Gaps.h8,
          bar(24),
          Gaps.h8,
          bar(24),
          Gaps.h12,
          bar(12),
          const Spacer(),
        ],
      ),
    );
  }
}
