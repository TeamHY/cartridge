import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart' show kPrimaryMouseButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/theme/theme.dart';

class BadgeCardTile extends ConsumerStatefulWidget {
  const BadgeCardTile({
    super.key,
    required this.title,
    required this.onTap,
    required this.menuBuilder,
    this.badges = const [],
    this.inEditMode = false,
    this.onDelete,
  });

  final String title;
  final VoidCallback onTap;
  final Widget Function(BuildContext) menuBuilder;
  final List<BadgeSpec> badges;
  final bool inEditMode;
  final VoidCallback? onDelete;

  @override
  ConsumerState<BadgeCardTile> createState() => _BadgeCardTileState();
}

class _BadgeCardTileState extends ConsumerState<BadgeCardTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  static const _pressScale = 0.975;
  Offset? rcPos;

  final _contextFlyout = FlyoutController();
  final _moreFlyout = FlyoutController();
  late final AnimationController _jiggleCtrl;

  @override
  void initState() {
    super.initState();
    _jiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    if (widget.inEditMode) _jiggleCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BadgeCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inEditMode != widget.inEditMode) {
      if (widget.inEditMode) {
        _jiggleCtrl.repeat(reverse: true);
      } else {
        _jiggleCtrl.stop();
        _jiggleCtrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _jiggleCtrl.dispose();
    _contextFlyout.dispose();
    _moreFlyout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final dividerColor = fTheme.dividerColor;
    final br = BorderRadius.circular(10);

    // 동적/정적 뱃지 합성
    Color cardBg() {
      if (widget.inEditMode) return fTheme.cardColor;
      if (_pressed) return fTheme.cardColor.withAlpha(220);
      if (_hovered) return fTheme.cardColor.withAlpha(240);
      return fTheme.cardColor;
    }
    Color cardBorder() {
      if (widget.inEditMode) return dividerColor;
      if (_pressed) return fTheme.accentColor.normal.withAlpha(160);
      if (_hovered) return dividerColor.withAlpha(180);
      return dividerColor;
    }
    List<BoxShadow> cardShadow() {
      if (widget.inEditMode) return const [];
      if (_pressed) {
        return [
          BoxShadow(
            color: fTheme.accentColor.normal.withAlpha(36),
            blurRadius: 8, spreadRadius: 0.5, offset: const Offset(0, 1),
          ),
        ];
      }
      if (_hovered) {
        return [
          BoxShadow(
            color: fTheme.accentColor.normal.withAlpha(60),
            blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 2),
          ),
        ];
      }
      return const [];
    }

    return FlyoutTarget(
      controller: _contextFlyout,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 투명 영역도 히트
        onSecondaryTapDown: (details) {
          rcPos = details.globalPosition; // 위치만 기억
        },
        onSecondaryTapUp: (_) {
          if (widget.inEditMode) return;
          final pos = rcPos;
          rcPos = null;
          if (pos != null) {
            _contextFlyout.showFlyout(
              position: pos,
              builder: (ctx) => widget.menuBuilder(ctx),
            );
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) { if (!mounted) return; setState(() => _hovered = true); },
          onExit:  (_) { if (!mounted) return; setState(() => _hovered = false); },
          child: Listener(
            onPointerDown: (e) {
              if (e.buttons == kPrimaryMouseButton && !widget.inEditMode) {
                if (!mounted) return;
                setState(() => _pressed = true);
              }
            },
            onPointerUp:     (_) { if (!mounted || widget.inEditMode) return; setState(() => _pressed = false); },
            onPointerCancel: (_) { if (!mounted || widget.inEditMode) return; setState(() => _pressed = false); },

            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.inEditMode ? () {} : widget.onTap,
              child: AnimatedBuilder(
                animation: _jiggleCtrl,
                builder: (_, child) {
                  final angle = widget.inEditMode ? 0.03 * (_jiggleCtrl.value - 0.5) : 0.0;
                  return RepaintBoundary(
                    child: Transform.rotate(
                      angle: angle,
                      child: child,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: widget.inEditMode
                      ? Duration.zero
                      : Duration(milliseconds: _pressed ? 90 : 140),
                  curve: _pressed ? Curves.easeOutCubic : Curves.easeOut,
                  transformAlignment: Alignment.center,
                  transform: (!widget.inEditMode && _pressed)
                      ? (Matrix4.identity()..scaleByDouble(_pressScale, _pressScale, 1.0, 1.0))
                      : Matrix4.identity(),
                  decoration: BoxDecoration(
                    color: cardBg(),
                    borderRadius: br,
                    border: Border.all(color: cardBorder()),
                    boxShadow: cardShadow(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  constraints: const BoxConstraints(minHeight: 120),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: widget.title,
                              style: const TooltipThemeData(
                                  waitDuration: Duration.zero),
                              child: Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                            ),
                          ),
                          Gaps.w2,
                          if (!widget.inEditMode)
                            FlyoutTarget(
                              controller: _moreFlyout,
                              child: IconButton(
                                icon: const Icon(
                                    FluentIcons.more_vertical),
                                onPressed: () {
                                  _moreFlyout.showFlyout(builder: (ctx) =>
                                      widget.menuBuilder(ctx));
                                },
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all(
                                      const EdgeInsets.all(6)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Gaps.h2,
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: BadgeStrip(
                            badges: widget.badges, height: 22),
                      ),
                    ],
                  ),
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}
