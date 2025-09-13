import 'dart:math' as math;
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:cartridge/theme/theme.dart';

import 'ut_table.dart';

class UTTableFrame<T> extends StatefulWidget {
  const UTTableFrame({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowHeight,
    required this.cellBuilder,

    // Selection
    this.selectionEnabled = true,
    this.headerTriState,
    this.onToggleAllInView,
    this.rowSelected,
    this.onRowCheckboxChanged,

    // Sorting
    this.initialSortColumnId,
    this.initialAscending = true,
    this.comparators = const {},
    this.onSortChanged,

    // UI
    this.headerBackgroundColor,
    this.reserveLeading = true,
    this.reserveTrailing = false,
    this.rowTrailing,
    this.headerTrailing,
    this.rowBaseBackground,

    // Resize notify (optional)
    this.onToggleRow,

    // 검색 / 필터
    this.showSearch = true,
    this.initialQuery,
    this.searchHintText,
    this.stringify,
    this.searchMatcher,
    this.quickFilters = const [],
    this.quickFiltersAreAnd = true,
    this.alwaysShowLeftSidebar = false,

    // 외부 컨트롤러(선택)
    this.controller,

    // zebra on/off
    this.zebra = false,

    // (옵션) 플레이스홀더 커스터마이즈
    this.emptyPlaceholder,
    this.noResultsPlaceholder,

    this.compactRowHeight = 32.0,
    this.tileRowHeight = 56.0,
    this.initiallyCompact = false,

    this.showFloatingSelectionBar = true,
    this.canEnable,
    this.canDisable,
    this.canFavoriteOn,
    this.canFavoriteOff,
    this.onEnableSelected,
    this.onDisableSelected,
    this.onFavoriteOnSelected,
    this.onFavoriteOffSelected,
    this.onSharePlainSelected,
    this.onShareMarkdownSelected,
    this.onShareRichSelected,

    this.leftSidebar,
    this.leftSidebarWidth = 280,
    this.initialDensity = UTTableDensity.comfortable,
    this.onDensityChanged,
    this.isPresetFilterId,
    this.initialSidebarOn = false,
  });

  final List<UTColumnSpec> columns;
  final List<T> rows;
  final double rowHeight;
  final List<Widget> Function(BuildContext context, T row) cellBuilder;

  // Selection
  final bool selectionEnabled;
  final bool? headerTriState;
  final void Function(bool selectAll, List<T> view)? onToggleAllInView;
  final bool Function(T row)? rowSelected;
  final void Function(T row, bool value)? onRowCheckboxChanged;

  // Sorting
  final String? initialSortColumnId;
  final bool initialAscending;
  final Map<String, int Function(T a, T b)>? comparators;
  final void Function(String? columnId, bool ascending)? onSortChanged;

  // UI
  final bool reserveTrailing;
  final Widget? Function(BuildContext context, T row)? rowTrailing;
  final Widget? headerTrailing;
  final Color? headerBackgroundColor;
  final bool reserveLeading;
  final Color? Function(BuildContext context, T row)? rowBaseBackground;

  final void Function(T row, bool checked)? onToggleRow;

  // 검색 / 필터
  final bool showSearch;
  final String? initialQuery;
  final String? searchHintText;
  final String Function(T row)? stringify;
  final bool Function(T row, String query)? searchMatcher;
  final List<UTQuickFilter<T>> quickFilters;
  final bool quickFiltersAreAnd;
  final bool alwaysShowLeftSidebar;

  // 컨트롤러
  final UTTableController<T>? controller;

  // zebra
  final bool zebra;

  // 플레이스홀더
  final Widget? emptyPlaceholder;
  final Widget? noResultsPlaceholder;

  final double compactRowHeight;
  final double tileRowHeight;
  final bool initiallyCompact;

  final bool showFloatingSelectionBar;
  final bool Function(T row)? canEnable;
  final bool Function(T row)? canDisable;
  final bool Function(T row)? canFavoriteOn;
  final bool Function(T row)? canFavoriteOff;
  final void Function(List<T> rows)? onEnableSelected;
  final void Function(List<T> rows)? onDisableSelected;
  final void Function(List<T> rows)? onFavoriteOnSelected;
  final void Function(List<T> rows)? onFavoriteOffSelected;
  final void Function(List<T> rows)? onSharePlainSelected;
  final void Function(List<T> rows)? onShareMarkdownSelected;
  final void Function(List<T> rows)? onShareRichSelected;

  final Widget? leftSidebar;
  final double leftSidebarWidth;
  final UTTableDensity initialDensity;
  final ValueChanged<UTTableDensity>? onDensityChanged;
  final bool Function(String filterId)? isPresetFilterId;
  final bool initialSidebarOn;

  @override
  State<UTTableFrame<T>> createState() => _UTTableFrameState<T>();
}

class _UTTableFrameState<T> extends State<UTTableFrame<T>>
    with SingleTickerProviderStateMixin {
  static const double _kMinRightPaneForInstance = 520.0;
  // Focus for floating selection bar to ensure immediate gesture handling on show
  final FocusNode _barFocusNode = FocusNode(debugLabel: 'UTFloatingBar');
  late List<T> _working;

  // 드래그 선택
  bool _dragSelecting = false;
  bool _dragTarget = false;

  // Focus / Scroll
  final FocusNode _focusNode = FocusNode(debugLabel: 'UTTableFrame');
  final ScrollController _listScroll = ScrollController();

  // 검색
  late final TextEditingController _searchCtrl =
  TextEditingController(text: widget.initialQuery ?? '');
  final FocusNode _searchFocus = FocusNode(debugLabel: 'UTSearch');

  // 컨트롤러: 외부 주입 or 내부 생성
  UTTableController<T>? _ownCtrl;
  UTTableController<T> get _ctrl => widget.controller ?? _ownCtrl!;

  late bool _instanceView = false;
  bool _autoDisabledByWidth = false;
  late UTTableDensity _density;

  // 현재 적용되는 행 높이
  double get _rowH {
    switch (_density) {
      case UTTableDensity.compact:
        return widget.compactRowHeight;
      case UTTableDensity.comfortable:
        return widget.rowHeight;
      case UTTableDensity.tile:
        return widget.tileRowHeight;
    }
  }

  // Floating bar 애니메이션
  late final AnimationController _barCtrl;
  late final Animation<Offset> _barSlide;
  late final Animation<double> _barFade;
  bool _barWantVisible = false;
  final UTTableToolbarController _toolbarCtrl = UTTableToolbarController();

  @override
  void initState() {
    super.initState();
    _working = List<T>.from(widget.rows);

    if (widget.controller == null) {
      _ownCtrl = UTTableController<T>(
        sortColumnId: widget.initialSortColumnId,
        ascending: widget.initialAscending,
        initialQuery: widget.initialQuery,
      );
    } else {
      widget.controller!.sortColumnId ??= widget.initialSortColumnId;
      if (widget.initialQuery != null && widget.controller!.query.isEmpty) {
        widget.controller!.query = widget.initialQuery!;
      }
    }

    _searchCtrl.text = _ctrl.query;
    _density = widget.initialDensity;
    _instanceView = widget.alwaysShowLeftSidebar || widget.initialSidebarOn;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _barSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _barCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _barFade = CurvedAnimation(
      parent: _barCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _barCtrl.value = 0.0;
  }

  @override
  void didUpdateWidget(covariant UTTableFrame<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 부모가 새로운 rows를 내려주면 내부 작업 리스트를 갱신
    if (!identical(oldWidget.rows, widget.rows) || oldWidget.rows.length != widget.rows.length) {
      _working = List<T>.from(widget.rows);

      // 포커스 인덱스 안전 범위로 보정
      if (_ctrl.focusIndex >= _working.length) {
        _ctrl.setFocusIndex(_working.isEmpty ? 0 : _working.length - 1);
      }
      setState(() {}); // 화면 갱신
    }
  }

  @override
  void dispose() {
    _listScroll.dispose();
    _focusNode.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _ownCtrl?.dispose();
    _barCtrl.dispose();
    _barFocusNode.dispose();
    super.dispose();
  }

  // ---------- Selection ----------
  List<T> _selectedRows(Iterable<T> all) {
    final out = <T>[];
    for (final r in all) {
      if (_isRowSelected(r)) out.add(r);
    }
    return out;
  }

  bool _isRowSelected(T row) {
    if (widget.rowSelected != null) return widget.rowSelected!(row);
    return _ctrl.selected.contains(row);
  }

  int _countSelected(Iterable<T> all) {
    if (!widget.selectionEnabled) return 0;
    var n = 0;
    for (final r in all) {
      if (_isRowSelected(r)) n++;
    }
    return n;
  }

  void _toggleRow(T row, bool checked) {
    if (widget.onRowCheckboxChanged != null) {
      widget.onRowCheckboxChanged!(row, checked);
      setState(() {});
      return;
    }
    if (widget.onToggleRow != null) {
      widget.onToggleRow!(row, checked);
      setState(() {});
      return;
    }
    _ctrl.setSelected(row, checked); // 내부 선택
  }

  // 드래그 세션
  void _beginDragSelect(bool target, T row) {
    setState(() {
      _dragSelecting = true;
      _dragTarget = target;
    });
    _toggleRow(row, _dragTarget);
  }

  void _endDragSelect() {
    if (!_dragSelecting) return;
    setState(() => _dragSelecting = false);
  }

  void _maybeApplyDragTo(T row) {
    if (!_dragSelecting) return;
    _toggleRow(row, _dragTarget);
  }

  void _toggleAll(bool selectAll, List<T> view) {
    if (widget.onToggleAllInView != null) {
      widget.onToggleAllInView!(selectAll, view);
    } else {
      for (final r in view) {
        _ctrl.setSelected(r, selectAll);
      }
    }
    setState(() {});
  }

  bool? _triState(List<T> view) {
    if (widget.headerTriState != null) return widget.headerTriState;
    if (view.isEmpty) return false;
    int selected = 0;
    for (final r in view) {
      if (_isRowSelected(r)) selected++;
    }
    if (selected == 0) return false;
    if (selected == view.length) return true;
    return null;
  }

  // ---------- Sorting ----------
  List<T> _sorted(List<T> src) {
    final columnId = _ctrl.sortColumnId;
    if (columnId == null) return src;
    final cmp = widget.comparators?[columnId];
    if (cmp == null) return src;
    final list = List<T>.of(src);
    list.sort((a, b) {
      final r = cmp(a, b);
      return _ctrl.ascending ? r : -r;
    });
    return list;
  }

  // 정렬 3단계(오름 → 내림 → 해제)
  void _onTapSort(String columnId) {
    if (_ctrl.sortColumnId != columnId) {
      _ctrl.setSort(columnId, true);
    } else if (_ctrl.ascending) {
      _ctrl.setSort(columnId, false);
    } else {
      _ctrl.setSort(null, true);
    }
    widget.onSortChanged?.call(_ctrl.sortColumnId, _ctrl.ascending);
  }

  // ---------- Resize ----------
  void _onResizeColumn(String id, double newWidth) {
    final spec = widget.columns.firstWhere((c) => c.id == id);
    final min = spec.minPx ?? 40;
    final max = spec.maxPx ?? double.infinity;
    final clamped = newWidth.clamp(min, max).toDouble();
    _ctrl.setPxOverride(id, clamped);
  }

  void _onClearResize(String id) {
    _ctrl.clearPxOverride(id);
  }

  // ---------- Responsive: 숨김 ----------
  List<UTColumnSpec> _visibleColumnsForWidth(double availColsWidth) {
    final vis = <UTColumnSpec>[
      for (final c in widget.columns)
        if (c.hideBelowPx == null || availColsWidth >= c.hideBelowPx!) c
    ];
    return vis.isEmpty ? [widget.columns.first] : vis;
  }

  List<Widget> _pickCellsByVisibleColumns(
      List<Widget> allCells,
      List<UTColumnSpec> visible,
      ) {
    final indexById = <String, int>{
      for (int i = 0; i < widget.columns.length; i++) widget.columns[i].id: i
    };
    return [for (final c in visible) allCells[indexById[c.id]!]];
  }

// ---------- Search & Filters ----------
  bool _defaultIsPresetId(String id) => id.startsWith('mp_');

  List<T> _applyQuickFilters(List<T> src) {
    final active = _ctrl.activeFilterIds;
    if (widget.quickFilters.isEmpty || active.isEmpty) return src;

    // id -> filter 매핑
    final byId = { for (final f in widget.quickFilters) f.id: f };
    final isPreset = widget.isPresetFilterId ?? _defaultIsPresetId;

    // 기본 / 프리셋 그룹 분리
    final base = <UTQuickFilter<T>>[];
    final preset = <UTQuickFilter<T>>[];

    for (final id in active) {
      final f = byId[id];
      if (f == null) continue;
      (isPreset(id) ? preset : base).add(f);
    }

    bool matchBase(T r) {
      if (base.isEmpty) return true;
      return widget.quickFiltersAreAnd
          ? base.every((f) => f.test(r))   // 교집합(AND)
          : base.any((f) => f.test(r));    // 합집합(OR)
    }

    bool matchPreset(T r) {
      if (preset.isEmpty) return true;
      return preset.any((f) => f.test(r)); // 항상 합집합(OR)
    }

    return [for (final r in src) if (matchBase(r) && matchPreset(r)) r];
  }

  bool _defaultSearchMatch(T row, String q) {
    if (q.isEmpty) return true;
    final s = widget.stringify?.call(row);
    if (s == null || s.isEmpty) return false;
    final hay = s.toLowerCase();
    final tokens =
    q.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    for (final t in tokens) {
      if (!hay.contains(t)) return false;
    }
    return true;
  }

  List<T> _applySearch(List<T> src) {
    final q = _ctrl.query.trim();
    if (q.isEmpty) return src;
    final matcher = widget.searchMatcher ?? _defaultSearchMatch;
    return [for (final r in src) if (matcher(r, q)) r];
  }

  // ---------- Focus utils ----------
  void _requestTableFocus() {
    _searchFocus.unfocus();
    FocusScope.of(context).requestFocus(_focusNode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasPrimaryFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  double get _rowExtent => _rowH + 1; // 현재 행 높이 기반

  int _rowsPerPage() {
    if (!_listScroll.hasClients) return 10;
    final viewport = _listScroll.position.viewportDimension;
    final n = (viewport / _rowExtent).floor();
    return n > 0 ? n : 1;
  }

  void _moveFocus(int delta, int maxLen) {
    if (maxLen == 0) return;
    _ctrl.setFocusIndex((_ctrl.focusIndex + delta).clamp(0, maxLen - 1));
    _ensureFocusVisible();
  }

  void _focusTo(int index, int maxLen) {
    if (maxLen == 0) return;
    _ctrl.setFocusIndex(index.clamp(0, maxLen - 1));
    _ensureFocusVisible();
  }

  void _ensureFocusVisible() {
    if (!_listScroll.hasClients) return;
    final targetTop = _ctrl.focusIndex * _rowExtent;
    final targetBottom = targetTop + _rowExtent;
    final viewTop = _listScroll.offset;
    final viewBottom = viewTop + _listScroll.position.viewportDimension;

    double newOffset = _listScroll.offset;
    if (targetTop < viewTop) {
      newOffset = targetTop;
    } else if (targetBottom > viewBottom) {
      newOffset = targetBottom - _listScroll.position.viewportDimension;
    }
    newOffset = newOffset.clamp(0.0, _listScroll.position.maxScrollExtent);
    _listScroll.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  // ---------- Keyboard ----------
  KeyEventResult _handleKey(FocusNode node, KeyEvent event, List<T> view) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Ctrl+F → 검색창 포커스
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    if (isCtrl &&
        event.logicalKey == LogicalKeyboardKey.keyF &&
        widget.showSearch) {
      _toolbarCtrl.openSearch();
      return KeyEventResult.handled;
    }

    if (!_focusNode.hasPrimaryFocus) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Ctrl+A / Ctrl+Shift+A : 보이는 행만 모두 선택 / 모두 해제
    if (isCtrl && key == LogicalKeyboardKey.keyA) {
      final shift = HardwareKeyboard.instance.isShiftPressed;
      _toggleAll(!shift, view);
      return KeyEventResult.handled;
    }

    // ↑ / ↓ : 포커스 이동
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1, view.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1, view.length);
      return KeyEventResult.handled;
    }

    // Home / End : 처음 / 끝
    if (key == LogicalKeyboardKey.home) {
      _focusTo(0, view.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _focusTo(view.length - 1, view.length);
      return KeyEventResult.handled;
    }

    // PageUp / PageDown : 한 화면 이동
    if (key == LogicalKeyboardKey.pageDown) {
      _moveFocus(_rowsPerPage(), view.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _moveFocus(-_rowsPerPage(), view.length);
      return KeyEventResult.handled;
    }

    // Space : 현재 행 선택 토글
    if (key == LogicalKeyboardKey.space && widget.selectionEnabled) {
      if (view.isNotEmpty) {
        final row = view[_ctrl.focusIndex];
        final cur = _isRowSelected(row);
        _toggleRow(row, !cur);
        setState(() {}); // 선택 칩/바 즉시 반영
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {

            final bool hasFiniteHeight =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            // 화면 폭이 좁으면 Instance View(사이드바) 금지
            const kDividerPadding = AppSpacing.sm;
            final needDividerSpace = (kDividerPadding * 2 + 1);
            final canUseInstance =
                (widget.leftSidebar != null) &&
                    (constraints.maxWidth >= widget.leftSidebarWidth + needDividerSpace + _kMinRightPaneForInstance);

            // 폭이 부족해지면 자동 OFF + 플래그 ON
            if (_instanceView && !canUseInstance && !widget.alwaysShowLeftSidebar) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _instanceView = false;
                  _autoDisabledByWidth = true;
                });
              });
            }

            // 다시 넓어졌고, 폭 때문에 껐던 경우면 자동 ON
            if (!_instanceView && canUseInstance && _autoDisabledByWidth) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _instanceView = true;
                  _autoDisabledByWidth = false;
                });
              });
            }

            final bool withSidebar = (widget.leftSidebar != null) &&
                (widget.alwaysShowLeftSidebar || (_instanceView && canUseInstance));

            final double contentHostWidth = withSidebar
                ? math.max(0.0, constraints.maxWidth - widget.leftSidebarWidth - (kDividerPadding * 2 + 1)) // divider padding 18px
                : constraints.maxWidth;

            final leading =
            (widget.reserveLeading && widget.selectionEnabled)
                ? kUTLeadingColWidth
                : 0.0;

            final trailing =
            (widget.reserveTrailing || widget.headerTrailing != null)
                ? kUTTrailingColWidth
                : 0.0;

            final double availColsWidth =
            (contentHostWidth - leading - trailing).clamp(0, double.infinity);

            final visibleColumns = _visibleColumnsForWidth(availColsWidth);

            final minColsWidth = UTWidthResolver.minRequiredWidth(
              visibleColumns,
              pxOverrides: _ctrl.pxOverrides,
              minPx: 40,
            );

            final double contentColsWidth = math.max(availColsWidth, minColsWidth);

            final widths = UTWidthResolver.resolve(
              visibleColumns,
              contentColsWidth,
              pxOverrides: _ctrl.pxOverrides,
              minPx: 40,
            );

            var view = List<T>.of(_working);
            view = _applyQuickFilters(view);
            final filteredThen = view.length;
            view = _applySearch(view);
            view = _sorted(view);

            final tri = widget.selectionEnabled ? _triState(view) : null;

            final safeFocusIndex =
            view.isEmpty ? 0 : _ctrl.focusIndex.clamp(0, view.length - 1);

            if (safeFocusIndex != _ctrl.focusIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final int clamped =
                view.isEmpty ? 0 : _ctrl.focusIndex.clamp(0, view.length - 1);
                if (clamped != _ctrl.focusIndex) {
                  _ctrl.setFocusIndex(clamped);
                }
              });
            }

            final totalCount = _working.length;
            final matchedCount = view.length;
            final selectedCount = _countSelected(_working);

            final bool showMatched = _ctrl.query.trim().isNotEmpty
                || _ctrl.activeFilterIds.isNotEmpty;

            final bool showSelected = selectedCount > 0;

            // 상단 툴바
            final toolbar = UTTableToolbarChips<T>(
              showSearch: widget.showSearch,
              searchController: _searchCtrl,
              searchFocusNode: _searchFocus,
              searchHintText: widget.searchHintText ?? loc.table_search_hint,
              controller: _toolbarCtrl,
              onQueryChanged: (v) {
                _ctrl.setQuery(v);
                setState(() {});
              },
              onSubmit: _requestTableFocus,
              onClearSearch: () {
                _ctrl.setQuery('');
                _searchCtrl.clear();
                setState(() {});
              },
              quickFilters: widget.quickFilters,
              activeFilterIds: _ctrl.activeFilterIds,
              onToggleFilter: (id, enable) {
                _ctrl.toggleFilter(id, enable: enable);
                setState(() {});
              },
              onClearAllFilters: () {
                for (final id in List.of(_ctrl.activeFilterIds)) {
                  _ctrl.toggleFilter(id, enable: false);
                }
                setState(() {});
              },

              density: _density,
              onSelectDensity: (d) {
                setState(() {
                  _density = d;
                });
                widget.onDensityChanged?.call(d);
                _ensureFocusVisible();
              },
              showSidebarToggle: (widget.leftSidebar != null) && !widget.alwaysShowLeftSidebar,
              sidebarSupported: canUseInstance,
              sidebarOn: withSidebar,
              onToggleSidebar: widget.alwaysShowLeftSidebar
                  ? null
                  : (v) => setState(() {
                _instanceView = v && canUseInstance;
                _autoDisabledByWidth = false;
              }),

              totalCount: totalCount,
              matchedCount: matchedCount,
              selectedCount: selectedCount,
              showMatched: showMatched,
              showSelected: showSelected,
            );

            final double headerH = switch (_density) {
              UTTableDensity.compact     => kHeaderHCompact,
              UTTableDensity.comfortable => kHeaderHComfortable,
              UTTableDensity.tile        => kHeaderHComfortable,
            };

            final headerRow = UTHeaderRow(
              height: headerH,
              triState: tri,
              selectionEnabled: widget.selectionEnabled,
              columns: visibleColumns,
              resolvedWidths: widths,
              leadingWidth: leading,
              reserveTrailing: widget.reserveTrailing,
              trailingWidth: trailing,
              backgroundColor: widget.headerBackgroundColor,
              sortColumnId: _ctrl.sortColumnId,
              ascending: _ctrl.ascending,
              onTapSort: _onTapSort,
              onToggleAll: (want) => _toggleAll(want, view),
              onResizeColumn: _onResizeColumn,
              onClearColumnResize: _onClearResize,
              trailing: widget.headerTrailing,
            );

            Widget buildBody() {
              if (view.isEmpty) {
                final empty = widget.emptyPlaceholder ??
                    Center(child: Text(loc.table_empty));
                final noResults = widget.noResultsPlaceholder ??
                    Center(child: Text(loc.table_no_results));
                return hasFiniteHeight
                    ? Expanded(child: (filteredThen == 0 ? empty : noResults))
                    : (filteredThen == 0 ? empty : noResults);
            }
            // Body
              final list = ListView.separated(
                controller: hasFiniteHeight ? _listScroll : null,
                primary: false,
                shrinkWrap: !hasFiniteHeight,
                physics: hasFiniteHeight
                    ? null
                    : const NeverScrollableScrollPhysics(),
                itemCount: view.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final row = view[i];
                  final allCells = widget.cellBuilder(ctx, row);
                  final cells =
                  _pickCellsByVisibleColumns(allCells, visibleColumns);
                  final trailingWidget = widget.rowTrailing?.call(ctx, row);

                  return UTDataRow(
                    height: _rowH,
                    columnWidths: widths,
                    selected: _isRowSelected(row),
                    selectionEnabled: widget.selectionEnabled,
                    baseBackground: widget.rowBaseBackground?.call(ctx, row),
                    reserveLeading: widget.selectionEnabled,
                    onChanged: (v) {
                      widget.onRowCheckboxChanged?.call(row, v);
                      _toggleRow(row, v);
                      setState(() {});
                    },
                    reserveTrailing: widget.reserveTrailing,
                    trailing: trailingWidget,
                    cells: cells,
                    focused: i == safeFocusIndex,
                    rowIndex: i,
                    onTapRow: () {
                      _ctrl.setFocusIndex(i);
                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                    },
                    isDragSelecting: _dragSelecting,
                    onBeginDragSelect: (target) =>
                        _beginDragSelect(target, row),
                    onEndDragSelect: _endDragSelect,
                    onDragEnterLeading: () => _maybeApplyDragTo(row),
                  );
                },
              );

              return hasFiniteHeight ? Expanded(child: list) : list;
            }

            final coreColumn = Column(
              children: [
                toolbar,
                headerRow,
                Gaps.h4,
                buildBody(),
              ],
            );

            final selectedRows = _selectedRows(_working);
            final hasSelection = selectedRows.isNotEmpty;
            final wantFloating =
                widget.showFloatingSelectionBar && hasSelection;

            if (wantFloating != _barWantVisible) {
              _barWantVisible = wantFloating;
              if (wantFloating && hasFiniteHeight) {
                _barCtrl.forward();
              } else {
                _barCtrl.reverse();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                });
              }
            }

            final visIds = {for (final c in visibleColumns) c.id};

            final double contentWidth = leading + contentColsWidth + trailing;

            final rightPane = Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (node, event) => _handleKey(node, event, view),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: hasFiniteHeight
                        ? SizedBox(
                      width: contentWidth,
                      height: constraints.maxHeight, // 유한 높이만 지정
                      child: coreColumn,
                    )
                        : SizedBox(
                      width: contentWidth,
                      child: coreColumn, // 높이 미지정(자연 크기)
                    ),
                  ),

                  if (wantFloating && hasFiniteHeight)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        minimum: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Focus(
                            focusNode: _barFocusNode,
                            canRequestFocus: false,
                            skipTraversal: true,
                            child: FadeTransition(
                              opacity: _barFade,
                              child: SlideTransition(
                                position: _barSlide,
                                child: UTFloatingSelectionBar<T>(
                                  selected: selectedRows,
                                  canEnable: widget.canEnable,
                                  canDisable: widget.canDisable,
                                  canFavoriteOn: widget.canFavoriteOn,
                                  canFavoriteOff: widget.canFavoriteOff,
                                  onEnableSelected: widget.onEnableSelected,
                                  onDisableSelected: widget.onDisableSelected,
                                  onFavoriteOnSelected: widget.onFavoriteOnSelected,
                                  onFavoriteOffSelected: widget.onFavoriteOffSelected,
                                  onSharePlainSelected: widget.onSharePlainSelected,
                                  onShareMarkdownSelected: widget.onShareMarkdownSelected,
                                  onShareRichSelected: widget.onShareRichSelected,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );


            return UTColumnVisibility(
              visibleIds: visIds,
              child: UTTableTheme(
                data: UTTableThemeData.fromFluent(
                  FluentTheme.of(context),
                  headerBg: widget.headerBackgroundColor,
                  density: _density,
                  zebra: widget.zebra,
                ),
                child: withSidebar
                    ? Row(
                  children: [
                    SizedBox(
                      width: widget.leftSidebarWidth,
                      child: widget.leftSidebar!,
                    ),
                    Gaps.w16,
                    Expanded(child: rightPane),
                  ],
                )
                    : rightPane,
              ),
            );
          },
        );
      },
    );
  }
}

class UTColumnVisibility extends InheritedWidget {
  final Set<String> visibleIds;
  const UTColumnVisibility({
    super.key,
    required this.visibleIds,
    required super.child,
  });

  static UTColumnVisibility? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UTColumnVisibility>();

  bool isVisible(String id) => visibleIds.contains(id);

  @override
  bool updateShouldNotify(covariant UTColumnVisibility oldWidget) =>
      !setEquals(visibleIds, oldWidget.visibleIds);
}