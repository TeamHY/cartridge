import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import 'package:cartridge/theme/theme.dart';

import 'ut_table.dart';

// ─────────────────────────────────────────────────────────
// UTTableToolbarChips (1행 툴바: Compact ▸ Filter ▸ Preset ▸ Search  |  Info chips)
// ─────────────────────────────────────────────────────────
class UTTableToolbarChips<T> extends StatefulWidget {
  const UTTableToolbarChips({
    super.key,
    // 검색
    required this.showSearch,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHintText,
    required this.onQueryChanged,
    required this.onSubmit,
    required this.onClearSearch,
    // 필터
    required this.quickFilters,
    required this.activeFilterIds,
    required this.onToggleFilter,
    required this.onClearAllFilters,
    // 밀도(컴팩트)
    required this.density,
    required this.onSelectDensity,
    required this.showSidebarToggle,
    required this.sidebarSupported,
    required this.sidebarOn,
    this.onToggleSidebar,
    // 정보 요약
    required this.totalCount,
    required this.matchedCount,
    required this.selectedCount,
    required this.showMatched,
    required this.showSelected,
    this.controller,
  });

  final bool showSearch;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchHintText;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClearSearch;

  final List<UTQuickFilter<T>> quickFilters;
  final Set<String> activeFilterIds;
  final void Function(String id, bool enable) onToggleFilter;
  final VoidCallback onClearAllFilters;

  final UTTableDensity density;
  final ValueChanged<UTTableDensity> onSelectDensity;
  final bool showSidebarToggle;
  final bool sidebarSupported;
  final bool sidebarOn;
  final ValueChanged<bool>? onToggleSidebar;

  final int totalCount;
  final int matchedCount;
  final int selectedCount;
  final bool showMatched;
  final bool showSelected;
  final UTTableToolbarController? controller;

  @override
  State<UTTableToolbarChips<T>> createState() => _UTTableToolbarChipsState<T>();
}

class _UTTableToolbarChipsState<T> extends State<UTTableToolbarChips<T>> {
  // 작은 화면에서 검색 입력창을 펼칠지 여부
  bool _searchExpanded = false;
  bool _didInit = false;

  UTTableToolbarController? _controller;
  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant UTTableToolbarChips<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController();
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController() {
    _controller = widget.controller;
    if (_controller == null) return;

    _searchExpanded = _controller!.isSearchOpen;
    _controllerListener = () {
      final wantOpen = _controller!.isSearchOpen;
      if (wantOpen == _searchExpanded) return;
      setState(() => _searchExpanded = wantOpen);
      if (wantOpen) {
        Future.delayed(const Duration(milliseconds: 10), () {
          widget.searchFocusNode.requestFocus();
          widget.searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: widget.searchController.text.length,
          );
        });
      } else {
        widget.searchFocusNode.unfocus();
        widget.onSubmit();
      }
    };
    _controller!.addListener(_controllerListener!);
  }

  void _detachController() {
    if (_controller != null && _controllerListener != null) {
      _controller!.removeListener(_controllerListener!);
    }
    _controller = null;
    _controllerListener = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;

      // 반응형 브레이크포인트
      const double bpNarrow = AppBreakpoints.md; // 이보다 좁으면 Info는 요약 칩
      const double bpSearchCollapse = AppBreakpoints.sm; // 이보다 좁으면 검색은 아이콘으로 접힘

      if (!_didInit) {
        _searchExpanded = widget.controller?.isSearchOpen ?? (w >= bpSearchCollapse);
        _didInit = true;
      }
      // 그룹 분류: 기본 필터 / 프리셋 필터
      final byId = {for (final f in widget.quickFilters) f.id: f};
      final baseFilterIds = <String>['favorite', 'installed', 'missing', 'enabled']
          .where(byId.containsKey)
          .toList();
      final presetFilterIds = widget.quickFilters
          .where((f) => f.id.startsWith('mp_') || f.id.startsWith('mpt_'))
          .map((f) => f.id)
          .toList();

      final baseActiveCount = widget.activeFilterIds
          .where((id) => baseFilterIds.contains(id))
          .length;
      final presetActiveCount = widget.activeFilterIds
          .where((id) => presetFilterIds.contains(id))
          .length;

      final showPresetToolbar = presetFilterIds.isNotEmpty && !widget.sidebarOn;

      // 왼쪽 컨트롤: Compact ▸ Filter ▸ Preset ▸ Search
      final leftControls = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1) Compact: 버튼 클릭 → 메뉴로 선택
          _ViewModeFlyoutButton(
            density: widget.density,
            onSelectDensity: widget.onSelectDensity,
            showSidebarToggle: widget.showSidebarToggle,
            sidebarSupported: widget.sidebarSupported,
            sidebarOn: widget.sidebarOn,
            onToggleSidebar: widget.onToggleSidebar,
          ),
          Gaps.w6,

          // 2) Filter 그룹 버튼
          if (baseFilterIds.isNotEmpty) ...[
            _GroupFlyoutButton<T>(
              label: 'Filter',
              icon: FluentIcons.filter,
              activeCount: baseActiveCount,
              items: [
                for (final id in baseFilterIds)
                  _GroupItem(
                    id: id,
                    label: byId[id]!.label,
                    icon: _iconForBaseFilter(id),
                  ),
              ],
              isActive: (id) => widget.activeFilterIds.contains(id),
              onToggle: (id, enable) => widget.onToggleFilter(id, enable),
              onClearAll: () {
                for (final id in baseFilterIds) {
                  if (widget.activeFilterIds.contains(id)) {
                    widget.onToggleFilter(id, false);
                  }
                }
                setState(() {});
              },
            ),
            Gaps.w6,
          ],

          // 3) Preset 그룹 버튼
          if (showPresetToolbar) ...[
            _GroupFlyoutButton<T>(
              label: 'Preset',
              icon: FluentIcons.tag,
              activeCount: presetActiveCount,
              items: [
                for (final id in presetFilterIds)
                  _GroupItem(
                    id: id,
                    label: byId[id]!.label,
                    icon: FluentIcons.puzzle,
                  ),
              ],
              isActive: (id) => widget.activeFilterIds.contains(id),
              onToggle: (id, enable) => widget.onToggleFilter(id, enable),
              onClearAll: () {
                for (final id in presetFilterIds) {
                  if (widget.activeFilterIds.contains(id)) {
                    widget.onToggleFilter(id, false);
                  }
                }
                setState(() {});
              },
            ),
            Gaps.w6,
          ],

          // 4) Search: 좁은 화면이면 아이콘 → 클릭 시 오른쪽으로 슬라이드하며 입력창 등장
          if (widget.showSearch)
            _AdaptiveSearch(
              controller: widget.searchController,
              focusNode: widget.searchFocusNode,
              hintText: widget.searchHintText,
              onChanged: (v) {
                widget.onQueryChanged(v);
                setState(() {}); // X 버튼 갱신
              },
              onSubmit: widget.onSubmit,
              onClear: () {
                widget.onClearSearch();
                setState(() {});
              },
              // 반응형: 좁으면 접고 아이콘만
              collapsed: !_searchExpanded,
              onToggleExpand: () {
                final next = !_searchExpanded;
                setState(() => _searchExpanded = next);

                if (next) {
                  widget.controller?.openSearch();
                  Future.delayed(const Duration(milliseconds: 10), () {
                    widget.searchFocusNode.requestFocus();
                    widget.searchController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: widget.searchController.text.length,
                    );
                  });
                } else {
                  widget.controller?.closeSearch();
                  widget.searchFocusNode.unfocus();
                  widget.onSubmit();
                }
              },
            ),
        ],
      );

      final rightInfo = (w < bpNarrow)
          ? _SummaryChip(
        total: widget.totalCount,
        matched: widget.matchedCount,
        selected: widget.selectedCount,
        showMatched: widget.showMatched,
        showSelected: widget.showSelected,
      )
          : UTInfoChipsRow(
        total: widget.totalCount,
        matched: widget.matchedCount,
        selected: widget.selectedCount,
        showMatched: widget.showMatched,
        showSelected: widget.showSelected,
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: leftControls,
                  ),
                ),
              ),
            ),
            // 오른쪽: Info chips
            rightInfo,
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────
// Compact Flyout Button (Comfortable / Compact 선택)
// ─────────────────────────────────────────────────────────
class _DensityFlyoutButton extends StatefulWidget {
  const _DensityFlyoutButton({
    required this.density,
    required this.onSelect,
  });

  final UTTableDensity density;
  final ValueChanged<UTTableDensity> onSelect;

  @override
  State<_DensityFlyoutButton> createState() => _DensityFlyoutButtonState();
}

class _DensityFlyoutButtonState extends State<_DensityFlyoutButton> {
  final FlyoutController _controller = FlyoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData mainIcon;
    switch (widget.density) {
      case UTTableDensity.comfortable: mainIcon = FluentIcons.density_comfy; break;
      case UTTableDensity.compact:     mainIcon = FluentIcons.density_default; break;
      case UTTableDensity.tile:        mainIcon = FluentIcons.side_panel; // 아이콘은 원하시면 교체
    }

    final fTheme = FluentTheme.of(context);

    Widget item({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final color = selected ? fTheme.accentColor.normal : null;
      return Button(
        onPressed: () {
          onTap();
          _controller.close();
        },
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            Gaps.w8,
            Expanded(child: Text(label)),
            if (selected) Icon(FluentIcons.check_mark, size: 12, color: color),
          ],
        ),
      );
    }

    return FlyoutTarget(
      controller: _controller,
      child: Button(
        style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.all(8))),
        onPressed: () {
          _controller.showFlyout(
            barrierColor: Colors.transparent,
            placementMode: FlyoutPlacementMode.bottomLeft,
            builder: (context) => FlyoutContent(
              constraints: const BoxConstraints(maxWidth: 264),
              color: fTheme.scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item(
                    icon: FluentIcons.density_default,
                    label: 'Compact',
                    selected: widget.density == UTTableDensity.compact,
                    onTap: () { widget.onSelect(UTTableDensity.compact); Flyout.of(context).close(); },
                  ),
                  Gaps.h4,
                  item(
                    icon: FluentIcons.density_comfy,
                    label: 'Comfortable',
                    selected: widget.density == UTTableDensity.comfortable,
                    onTap: () { widget.onSelect(UTTableDensity.comfortable); Flyout.of(context).close(); },
                  ),
                  Gaps.h4,
                  item(
                    icon: FluentIcons.side_panel, // 원하면 타일을 상징하는 아이콘으로 변경
                    label: 'Tile',
                    selected: widget.density == UTTableDensity.tile,
                    onTap: () { widget.onSelect(UTTableDensity.tile); Flyout.of(context).close(); },
                  ),
                ],
              ),
            ),
          );
        },
        child: Icon(mainIcon, size: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Adaptive Search (좁은 화면: 아이콘 → 펼치면 오른쪽으로 슬라이드)
// ─────────────────────────────────────────────────────────
class _AdaptiveSearch extends StatefulWidget {
  const _AdaptiveSearch({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.collapsed,
    required this.onToggleExpand,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  final bool collapsed;         // true면 아이콘만
  final VoidCallback onToggleExpand;

  @override
  State<_AdaptiveSearch> createState() => _AdaptiveSearchState();
}

class _AdaptiveSearchState extends State<_AdaptiveSearch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 140),
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(-0.12, 0), // 왼쪽에서 들어오게
    end: Offset.zero,
  ).animate(_size);

  @override
  void didUpdateWidget(covariant _AdaptiveSearch old) {
    super.didUpdateWidget(old);
    // 접힘/펼침 애니메이션 제어
    if (widget.collapsed) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 아이콘(항상 보임)
    final iconBtn = Tooltip(
      message: 'Search',
      child: Button(
        style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.all(8))),
        onPressed: () {
          if (!widget.collapsed) {
            widget.onToggleExpand();
            widget.onSubmit();
          } else {
            widget.onToggleExpand();
          }
        },
        child: Icon(
          FluentIcons.search,
          size: 14,
        ),
      ),
    );

    // 펼쳐지는 입력창 (오버플로 방어: Flexible + ClipRect)
    final field = Flexible(
      child: ClipRect(
        child: SizeTransition(
          axis: Axis.horizontal,
          sizeFactor: _size,       // 가로폭 0 → 1
          axisAlignment: -1.0,     // 왼쪽 기준으로 펼침
          child: SlideTransition(
            position: _slide,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
                },
                child: Actions(
                  actions: {
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) {
                        if (widget.controller.text.isNotEmpty) {
                          widget.onClear();
                        } else {
                          // 입력창 닫기
                          widget.onToggleExpand();
                          widget.onSubmit();
                        }
                        return null;
                      },
                    ),
                  },
                  child: TextBox(
                    focusNode: widget.focusNode,
                    controller: widget.controller,
                    placeholder: widget.hintText,
                    textInputAction: TextInputAction.search,
                    onChanged: widget.onChanged,
                    onSubmitted: (_) => widget.onSubmit(),
                    suffix: widget.controller.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: widget.onClear, // 내용만 지움, 열림 유지
                    )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBtn,
        if (!widget.collapsed) Gaps.w6,
        if (!widget.collapsed) field,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 그룹 필터 Flyout (이전 답변에서 제시했던 것 재사용)
// ─────────────────────────────────────────────────────────
class _GroupItem {
  const _GroupItem({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

class _GroupFlyoutButton<T> extends StatefulWidget {
  const _GroupFlyoutButton({
    required this.label,
    required this.icon,
    required this.items,
    required this.isActive,
    required this.onToggle,
    required this.onClearAll,
    this.activeCount = 0,
  });

  final String label;
  final IconData icon;
  final List<_GroupItem> items;
  final bool Function(String id) isActive;
  final void Function(String id, bool enable) onToggle;
  final VoidCallback onClearAll;
  final int activeCount;

  @override
  State<_GroupFlyoutButton<T>> createState() => _GroupFlyoutButtonState<T>();
}

class _GroupFlyoutButtonState<T> extends State<_GroupFlyoutButton<T>> {
  final FlyoutController _controller = FlyoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final badge = (widget.activeCount > 0)
        ? Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).accentColor.normal.withAlpha(46),
        borderRadius: AppShapes.pill,
      ),
      child: Text(
        '${widget.activeCount}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    )
        : const SizedBox.shrink();

    return FlyoutTarget(
      controller: _controller,
      child: Button(
        onPressed: () {
          _controller.showFlyout(
            barrierColor: Colors.transparent,
            placementMode: FlyoutPlacementMode.bottomLeft,
            builder: (context) => FlyoutContent(
              constraints: const BoxConstraints(maxWidth: 360),
              color: fTheme.scaffoldBackgroundColor,
              child: _GroupFlyoutBody(
                title: widget.label,
                items: widget.items,
                isActive: widget.isActive,
                onToggle: widget.onToggle,
                onClearAll: widget.onClearAll,
              ),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 14),
            Gaps.w6,
            Text(widget.label),
            badge,
            Gaps.w4,
            const Icon(FluentIcons.chevron_down, size: 10),
          ],
        ),
      ),
    );
  }
}

class _GroupFlyoutBody extends StatefulWidget {
  const _GroupFlyoutBody({
    required this.title,
    required this.items,
    required this.isActive,
    required this.onToggle,
    required this.onClearAll,
  });

  final String title;
  final List<_GroupItem> items;
  final bool Function(String id) isActive;
  final void Function(String id, bool enable) onToggle;
  final VoidCallback onClearAll;

  @override
  State<_GroupFlyoutBody> createState() => _GroupFlyoutBodyState();
}

class _GroupFlyoutBodyState extends State<_GroupFlyoutBody> {
  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    Widget chip(_GroupItem it) {
      final active = widget.isActive(it.id);
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(it.icon, size: 12),
          Gaps.w6,
          Text(it.label),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: active
            ? FilledButton(
          child: child,
          onPressed: () {
            widget.onToggle(it.id, false);
            setState(() {});
          },
        )
            : Button(
          child: child,
          onPressed: () {
            widget.onToggle(it.id, true);
            setState(() {});
          },
        ),
      );
    }

    final hasAnyActive = widget.items.any((it) => widget.isActive(it.id));

    return FocusTraversalGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (hasAnyActive)
                HyperlinkButton(
                  onPressed: () {
                    widget.onClearAll();
                    setState(() {});
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
          Gaps.h8,
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(children: [for (final it in widget.items) chip(it)]),
          ),
          Gaps.h6,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '복수 선택 가능',
              style: TextStyle(
                fontSize: 11,
                color: (t.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                    .withAlpha(120),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Info 요약 칩(좁은 화면)
// ─────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.total,
    required this.matched,
    required this.selected,
    required this.showMatched,
    required this.showSelected,
  });

  final int total;
  final int matched;
  final int selected;
  final bool showMatched;
  final bool showSelected;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final base = t.accentColor.normal;
    final bg = base.withAlpha(isDark ? 60 : 24);
    final border = base.withAlpha(isDark ? 130 : 160);

    final parts = <String>[];
    if (showSelected) parts.add('Sel $selected');
    if (showMatched) parts.add('Mat $matched');
    parts.add('/ $total');

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppShapes.pill,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        parts.join(' · '),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 필터 아이콘 매핑
// ─────────────────────────────────────────────────────────
IconData _iconForBaseFilter(String id) {
  switch (id) {
    case 'favorite':
      return FluentIcons.heart;
    case 'installed':
      return FluentIcons.completed_solid;
    case 'missing':
      return FluentIcons.blocked2;
    case 'enabled':
      return FluentIcons.power_button;
    default:
      return FluentIcons.checkbox_composite;
  }
}

class _ViewModeFlyoutButton extends StatefulWidget {
  const _ViewModeFlyoutButton({
    required this.density,
    required this.onSelectDensity,
    required this.showSidebarToggle,
    required this.sidebarSupported,
    required this.sidebarOn,
    required this.onToggleSidebar,
  });

  final UTTableDensity density;
  final ValueChanged<UTTableDensity> onSelectDensity;

  final bool showSidebarToggle;
  final bool sidebarSupported;
  final bool sidebarOn;
  final ValueChanged<bool>? onToggleSidebar;

  @override
  State<_ViewModeFlyoutButton> createState() => _ViewModeFlyoutButtonState();
}

class _ViewModeFlyoutButtonState extends State<_ViewModeFlyoutButton> {
  final FlyoutController _controller = FlyoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    IconData mainIcon;
    switch (widget.density) {
      case UTTableDensity.comfortable: mainIcon = FluentIcons.density_comfy;   break;
      case UTTableDensity.compact:     mainIcon = FluentIcons.density_default; break;
      case UTTableDensity.tile:        mainIcon = FluentIcons.side_panel;      break; // 필요 시 아이콘 교체
    }

    Widget densityItem({
      required IconData icon,
      required String label,
      required UTTableDensity value,
    }) {
      final selected = widget.density == value;
      final color = selected ? t.accentColor.normal : null;
      return Button(
        onPressed: () {
          widget.onSelectDensity(value);
          _controller.close();
        },
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            Gaps.w8,
            Expanded(child: Text(label)),
            if (selected) Icon(FluentIcons.check_mark, size: 12, color: color),
          ],
        ),
      );
    }

    final sidebarRow = (!widget.showSidebarToggle)
        ? const SizedBox.shrink()
        : Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(FluentIcons.side_panel, size: 14),
          Gaps.w8,
          const Expanded(child: Text('Left sidebar')),
          ToggleSwitch(
            checked: widget.sidebarOn,
            onChanged: (widget.onToggleSidebar != null && widget.sidebarSupported)
                ? (v) {
              widget.onToggleSidebar!(v);
              _controller.close();
            }
                : null,
          ),
        ],
      ),
    );

    return FlyoutTarget(
      controller: _controller,
      child: Button(
        style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.all(8))),
        onPressed: () {
          _controller.showFlyout(
            barrierColor: Colors.transparent,
            placementMode: FlyoutPlacementMode.bottomLeft,
            builder: (ctx) => FlyoutContent(
              color: t.scaffoldBackgroundColor,
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  densityItem(
                    icon: FluentIcons.density_default,
                    label: 'Compact',
                    value: UTTableDensity.compact,
                  ),
                  Gaps.h4,
                  densityItem(
                    icon: FluentIcons.density_comfy,
                    label: 'Comfortable',
                    value: UTTableDensity.comfortable,
                  ),
                  Gaps.h4,
                  densityItem(
                    icon: FluentIcons.side_panel, // 타일을 상징하는 아이콘 원하면 변경
                    label: 'Tile',
                    value: UTTableDensity.tile,
                  ),
                  if (widget.showSidebarToggle) const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(),
                  ),
                  sidebarRow,
                  if (widget.showSidebarToggle && !widget.sidebarSupported)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Sidebar not available at this width',
                        style: TextStyle(
                          fontSize: 11,
                          color: (t.brightness == Brightness.dark ? Colors.white : Colors.black)
                              .withAlpha(120),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: Icon(mainIcon, size: 14),
      ),
    );
  }
}
