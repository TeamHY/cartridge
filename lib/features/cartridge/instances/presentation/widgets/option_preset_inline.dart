import 'package:cartridge/app/presentation/app_navigation.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class OptionPresetInlineControl extends ConsumerWidget {
  const OptionPresetInlineControl({
    super.key,
    required this.optionsAsync,
    required this.selectedId,
    required this.onChanged,
    this.onGoToOptionPresets,
  });

  final AsyncValue<List<OptionPresetView>> optionsAsync;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onGoToOptionPresets;

  static const double _kMinHeight = 28;
  static const int kOptionPresetsNavIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kMinHeight),
      child: optionsAsync.when(
        loading: () => const _InlinePlaceholder(),
        error: (_, __) => const _InlinePlaceholder(),
        data: (list) {
          // 선택지 없음 → 옵션 프리셋 탭으로 이동 Chip
          if (list.isEmpty) {
            return SizedBox(
              height: _kMinHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (onGoToOptionPresets != null) {
                    onGoToOptionPresets!();
                  } else {
                    ref.read(appNavigationIndexProvider.notifier).state = kOptionPresetsNavIndex;
                  }
                },
                child: _ChipLikeHoverable(
                  icon: FluentIcons.add,
                  label: loc.instance_option_preset_add_label,
                  tooltip: loc.navigation_option_preset,
                ),
              ),
            );
          }

          // 현재 선택
          OptionPresetView? selected;
          if (selectedId != null) {
            final i = list.indexWhere((o) => o.id == selectedId);
            if (i >= 0) selected = list[i];
          }

          final controller = FlyoutController();

          return SizedBox(
            height: _kMinHeight,
            child: FlyoutTarget(
              controller: controller,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.showFlyout(
                    placementMode: FlyoutPlacementMode.bottomLeft,
                    barrierColor: Colors.transparent,
                    builder: (ctx) {
                      String query = '';
                      return StatefulBuilder(
                        builder: (ctx, setState) {
                          final filtered = query.isEmpty
                              ? list
                              : list.where((o) => o.name.toLowerCase().contains(query.toLowerCase())).toList();

                          return _OptionPresetFlyoutPanel(
                            options: filtered,
                            selectedId: selectedId,
                            onPick: (id) {
                              onChanged(id);
                              Flyout.of(ctx).close();
                            },
                            onClear: () {
                              onChanged(null);
                              Flyout.of(ctx).close();
                            },
                            onManage: () {
                              Flyout.of(ctx).close();
                              if (onGoToOptionPresets != null) {
                                onGoToOptionPresets!();
                              } else {
                                ref.read(appNavigationIndexProvider.notifier).state = kOptionPresetsNavIndex;
                              }
                            },
                            searchBox: TextBox(
                              placeholder: loc.common_search_placeholder,
                              autofocus: true,
                              onChanged: (v) => setState(() => query = v),
                            ),
                            headerLabel: '${loc.instance_option_preset_label} (${list.length})',
                          );
                        },
                      );
                    },
                  );
                },
                child: _ChipLikeHoverable(
                  icon: FluentIcons.toolbox,
                  label: _inlineSummary(loc, selected),
                  tooltip: _tooltipSummary(loc, selected),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Flyout Panel ───────────────────────────────────────────────────────────
class _OptionPresetFlyoutPanel extends StatefulWidget {
  const _OptionPresetFlyoutPanel({
    required this.options,
    required this.selectedId,
    required this.onPick,
    required this.onClear,
    required this.onManage,
    required this.searchBox,
    required this.headerLabel,
  });

  final List<OptionPresetView> options;
  final String? selectedId;
  final ValueChanged<String?> onPick;
  final VoidCallback onClear;
  final VoidCallback onManage;
  final Widget searchBox;
  final String headerLabel;

  @override
  State<_OptionPresetFlyoutPanel> createState() => _OptionPresetFlyoutPanelState();
}

class _OptionPresetFlyoutPanelState extends State<_OptionPresetFlyoutPanel> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 320),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: fTheme.shadowColor.withAlpha(30),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: fTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(FluentIcons.toolbox, size: 14, color: fTheme.accentColor),
              Gaps.w6,
              Expanded(
                child: Text(
                  widget.headerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Gaps.w6,
              HyperlinkButton(
                onPressed: widget.onManage,
                child: Text(loc.common_edit),
              ),
            ],
          ),
          Gaps.h8,

          // 검색
          widget.searchBox,
          Gaps.h8,

          // 목록
          Expanded(
            child: Scrollbar(
              controller: _scrollCtrl,
              interactive: true,
              child: ListView.separated(
                controller: _scrollCtrl,
                primary: false,
                itemCount: widget.options.length,
                separatorBuilder: (_, __) => Gaps.h6,
                itemBuilder: (ctx, i) {
                  final o = widget.options[i];
                  final selected = (o.id == widget.selectedId);
                  return _OptionPresetTile(
                    option: o,
                    selected: selected,
                    onTap: () => widget.onPick(o.id),
                  );
                },
              ),
            ),
          ),

          Gaps.h8,
          const Divider(
            style: DividerThemeData(
              horizontalMargin: EdgeInsets.zero,
            ),
          ),
          Gaps.h8,
          // 푸터
          Row(
            children: [
              Button(
                onPressed: widget.onClear,
                child: Text(loc.common_clear_selection),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionPresetTile extends StatelessWidget {
  const _OptionPresetTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OptionPresetView option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final subtitle = _subtitle(loc, option);

    return HoverButton(
      onPressed: onTap,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hovered ? fTheme.resources.controlFillColorDefault : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? fTheme.accentColor : (fTheme.dividerColor).withAlpha(100),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? FluentIcons.radio_btn_on : FluentIcons.radio_btn_off,
                size: 14,
                color: selected ? fTheme.accentColor : fTheme.inactiveColor,
              ),
              Gaps.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Gaps.h2,
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: fTheme.resources.textFillColorSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (option.useRepentogon == true) ...[
                Gaps.w8,
                Icon(FluentIcons.game, size: 12, color: fTheme.accentColor),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── 요약/툴팁/서브타이틀 ───────────────────────────────────────────────────────────
String _truncate(String s, {required int keep}) =>
    (s.length <= keep) ? s : '${s.substring(0, keep)}…';

String _inlineSummary(AppLocalizations loc, OptionPresetView? o) {
  if (o == null) return  loc.instance_option_preset_add_label;
  final parts = <String>[];
  parts.add(_truncate(o.name, keep: 17));
  if (o.fullscreen == true) {
    parts.add(loc.option_fullscreen_label);
  } else if (o.windowWidth != null && o.windowHeight != null) {
    parts.add('${o.windowWidth}×${o.windowHeight}');
  }
  if (o.windowPosX != null && o.windowPosY != null) {
    parts.add('${o.windowPosX}×${o.windowPosY}');
  }
  if (o.useRepentogon == true) {
    parts.add(loc.option_repentogon_label);
  }
  return parts.join(' | ');
}

String _tooltipSummary(AppLocalizations loc, OptionPresetView? o) {
  if (o == null) return '${loc.instance_option_preset_label}: ${loc.instance_option_preset_add_label}';
  final lines = <String>[o.name];
  if (o.fullscreen == true) {
    lines.add(loc.option_fullscreen_label);
  } else if (o.windowWidth != null && o.windowHeight != null) {
    lines.add('${loc.option_window_label}: ${o.windowWidth}×${o.windowHeight}');
  }
  if (o.windowPosX != null && o.windowPosY != null) {
    lines.add('${loc.option_position_label}: ${o.windowPosX}×${o.windowPosY}');
  }
  if (o.useRepentogon == true) {
    lines.add(loc.option_repentogon_label);
  }
  return lines.join('\n');
}

String _subtitle(AppLocalizations loc, OptionPresetView o) {
  final parts = <String>[];
  if (o.fullscreen == true) {
    parts.add(loc.option_fullscreen_label);
  } else if (o.windowWidth != null && o.windowHeight != null) {
    parts.add('${o.windowWidth}×${o.windowHeight}');
  }
  if (o.windowPosX != null && o.windowPosY != null) {
    parts.add('${o.windowPosX}×${o.windowPosY}');
  }
  if (o.useRepentogon == true) {
    parts.add(loc.option_repentogon_label);
  }
  return parts.join(' · ');
}

// ── Chip-like 버튼(호버 기어 + 툴팁) ───────────────────────────────────────────────────────────
class _ChipLikeHoverable extends StatefulWidget {
  const _ChipLikeHoverable({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final String tooltip;

  @override
  State<_ChipLikeHoverable> createState() => _ChipLikeHoverableState();
}

class _ChipLikeHoverableState extends State<_ChipLikeHoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final normalTextColor = fTheme.resources.textFillColorSecondary;
    final hoverTextColor  = fTheme.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        style: const TooltipThemeData(maxWidth: 440, preferBelow: true),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: _hovered ? hoverTextColor : fTheme.inactiveColor),
                Gaps.w6,
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _hovered ? hoverTextColor : normalTextColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Gaps.w8,
                SizedBox(
                  width: 10, height: 10,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: IgnorePointer(
                      ignoring: true,
                      child: Icon(FluentIcons.settings, size: 10, color: hoverTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 로딩/에러 ───────────────────────────────────────────────────────────
class _InlinePlaceholder extends StatelessWidget {
  const _InlinePlaceholder();

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final textColor = fTheme.resources.textFillColorSecondary;
    final iconColor = fTheme.inactiveColor;

    return SizedBox(
      height: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FluentIcons.toolbox, size: 14, color: iconColor),
            Gaps.w6,
            // ‘—’ 로 조용히 표시 (클릭 불가)
            const Text(
              '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: TextDecoration.none,
              ),
            ),
          ].map((w) {
            // 텍스트 색만 토큰으로 맞춰서 살짝 죽임
            if (w is Text) {
              return DefaultTextStyle(
                style: TextStyle(color: textColor),
                child: w,
              );
            }
            return w;
          }).toList(),
        ),
      ),
    );
  }
}