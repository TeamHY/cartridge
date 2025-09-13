import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/theme/theme.dart';

class InstancePresetSidebar extends ConsumerStatefulWidget {
  const InstancePresetSidebar({
    super.key,
    required this.instanceId,
    required this.presets,
    required this.onAddPresets,
  });

  final String instanceId;
  final List<AppliedPresetLabelView> presets;
  final VoidCallback onAddPresets;

  @override
  ConsumerState<InstancePresetSidebar> createState() => _InstancePresetSidebarState();
}

class _InstancePresetSidebarState extends ConsumerState<InstancePresetSidebar> {
  late final ScrollController _listCtrl;

  @override
  void initState() { super.initState(); _listCtrl = ScrollController(); }
  @override
  void dispose() { _listCtrl.dispose(); super.dispose(); }

  Set<String> _activePresetIdsOf(UTTableController controller, Set<String> allPresetIds) {
    final out = <String>{};
    for (final pid in allPresetIds) {
      if (controller.activeFilterIds.contains('mp_$pid')) out.add(pid);
    }
    return out;
  }

  void _applyPresetSelection(UTTableController controller, Set<String> next, Set<String> allPresetIds) {
    final current = _activePresetIdsOf(controller, allPresetIds);
    for (final pid in current.difference(next)) { controller.toggleFilter('mp_$pid', enable: false); }
    for (final pid in next.difference(current)) { controller.toggleFilter('mp_$pid', enable: true); }
  }

  bool _modeAll(UTTableController c)  => !c.activeFilterIds.contains('mpt_has') && !c.activeFilterIds.contains('mpt_none');
  bool _modeHas(UTTableController c)  =>  c.activeFilterIds.contains('mpt_has');
  bool _modeNone(UTTableController c) =>  c.activeFilterIds.contains('mpt_none');

  void _ensureModeHas(UTTableController c) {
    // '프리셋 없음'을 끄고 '프리셋만'을 켬
    if (c.activeFilterIds.contains('mpt_none')) {
      c.toggleFilter('mpt_none', enable: false);
    }
    if (!c.activeFilterIds.contains('mpt_has')) {
      c.toggleFilter('mpt_has', enable: true);
    }
  }

  void _setModeAll(UTTableController c, Set<String> allPresetIds)  {
    if (c.activeFilterIds.contains('mpt_has')) c.toggleFilter('mpt_has', enable: false);
    if (c.activeFilterIds.contains('mpt_none')) c.toggleFilter('mpt_none', enable: false);
    for (final pid in allPresetIds) {
      if (c.activeFilterIds.contains('mp_$pid')) {
        c.toggleFilter('mp_$pid', enable: false);
      }
    }
  }

  void _setModeHas(UTTableController c)  {
    if (c.activeFilterIds.contains('mpt_none')) c.toggleFilter('mpt_none', enable: false);
    if (!c.activeFilterIds.contains('mpt_has')) c.toggleFilter('mpt_has', enable: true);
  }
  void _setModeNone(UTTableController c, Set<String> allPresetIds) {
    if (c.activeFilterIds.contains('mpt_has')) c.toggleFilter('mpt_has', enable: false);
    // 프리셋 개별 선택은 모두 끕니다(AND 충돌 방지)
    for (final pid in allPresetIds) {
      if (c.activeFilterIds.contains('mp_$pid')) c.toggleFilter('mp_$pid', enable: false);
    }
    if (!c.activeFilterIds.contains('mpt_none')) c.toggleFilter('mpt_none', enable: true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final tableCtrl = ref.watch(instanceTableCtrlProvider(widget.instanceId));
    final appAsync  = ref.watch(instanceDetailControllerProvider(widget.instanceId));

    // 카운트 계산
    int total = 0, withPreset = 0, noPreset = 0;
    final isLoading = appAsync.isLoading;
    final hasError = appAsync.hasError;

    appAsync.whenData((v) {
      total = v.items.length;
      withPreset = v.items.where((m) => m.enabledByPresets.isNotEmpty).length;
      noPreset = total - withPreset;
    });

    return AnimatedBuilder(
      animation: tableCtrl,
      builder: (context, _) {
        final allIds = widget.presets.map((e) => e.presetId).toSet();
        final activeIds = _activePresetIdsOf(tableCtrl, allIds);
        final isModeAll  = _modeAll(tableCtrl);
        final isModeHas  = _modeHas(tableCtrl);
        final isModeNone = _modeNone(tableCtrl);

        void togglePreset(String id) {
          _ensureModeHas(tableCtrl);
          final next = Set<String>.from(activeIds);
          next.contains(id) ? next.remove(id) : next.add(id);
          _applyPresetSelection(tableCtrl, next, allIds);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 메일형 내비게이션 3종
            SidebarTile(
              icon: FluentIcons.view_all,
              label: loc.instance_sidebar_all,
              count: total,
              selected: isModeAll,
              onTap: () => _setModeAll(tableCtrl, allIds),
            ),
            Gaps.h6,
            SidebarTile(
              icon: FluentIcons.tag,
              label: loc.instance_sidebar_with_preset,
              count: withPreset,
              selected: isModeHas,
              onTap: () => _setModeHas(tableCtrl),
            ),
            Gaps.h6,
            SidebarTile(
              icon: FluentIcons.clear_filter,
              label: loc.instance_sidebar_no_preset,
              count: noPreset,
              selected: isModeNone,
              onTap: () => _setModeNone(tableCtrl, allIds),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(
                style: DividerThemeData(
                  horizontalMargin: EdgeInsets.zero,
                ),
              ),
            ),

            // 프리셋 섹션 헤더 + 편집
            Row(
              children: [
                Text(
                  loc.instance_sidebar_presets,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Tooltip(
                  message: loc.instance_sidebar_edit_tooltip,
                  child: IconButton(
                    icon: const Icon(FluentIcons.edit),
                    onPressed: widget.onAddPresets,
                  ),
                ),
              ],
            ),
            Gaps.h8,
            if (isLoading || hasError) ...[
              // 텍스트만 가볍게 노출 (에러 코드는 숨김)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  isLoading ? loc.instance_sidebar_loading : loc.instance_sidebar_load_failed,
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
            ],
            // 프리셋 다중 선택(합집합). "프리셋 없음" 모드에선 비활성화
            Expanded(
              child: PresetTileList(
                presets: widget.presets,
                selectedIds: activeIds,
                onToggleSelected: togglePreset,
                controller: _listCtrl,
                ensurePresetOnlyMode: () => _ensureModeHas(tableCtrl),
              ),
            ),
          ],
        );
      },
    );
  }
}
