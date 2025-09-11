import 'package:cartridge/app/presentation/widgets/badge.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart' show kPrimaryMouseButton;

import 'package:cartridge/features/cartridge/instances/domain/models/instance_image.dart';
import 'package:cartridge/features/cartridge/instances/presentation/controllers/instances_page_controller.dart';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/instance_image_thumb.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class InstanceBadgeCardTile extends ConsumerStatefulWidget {
  const InstanceBadgeCardTile({
    super.key,
    required this.title,
    required this.onTap,
    required this.onPlayInstance,
    required this.menuBuilder,
    this.badges = const [],
    this.optionPresetId,
    this.autoRepentogonBadge = false,
    this.repentogonBadgeLabel,
    this.image,
    this.inEditMode = false,
    this.onDeleteInstance,
  });

  final String title;
  final VoidCallback onTap;
  final VoidCallback onPlayInstance;
  final Widget Function(BuildContext) menuBuilder;
  final List<BadgeSpec> badges;
  final String? optionPresetId;
  final bool autoRepentogonBadge;
  final String? repentogonBadgeLabel;
  final InstanceImage? image;
  final bool inEditMode;
  final VoidCallback? onDeleteInstance;

  @override
  ConsumerState<InstanceBadgeCardTile> createState() => _InstanceBadgeCardTileState();
}

class _InstanceBadgeCardTileState extends ConsumerState<InstanceBadgeCardTile>
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
  void didUpdateWidget(covariant InstanceBadgeCardTile oldWidget) {
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
    final loc = AppLocalizations.of(context);
    final dividerColor = fTheme.dividerColor;
    final sem = ref.watch(themeSemanticsProvider);
    final br = BorderRadius.circular(10);

    // 동적/정적 뱃지 합성
    final List<BadgeSpec> computedBadges = List<BadgeSpec>.of(widget.badges);
    if (widget.autoRepentogonBadge) {
      final useRep = ref.watch(useRepentogonByPresetIdProvider(widget.optionPresetId));
      if (useRep) {
        computedBadges.add(
          BadgeSpec(widget.repentogonBadgeLabel ?? loc.option_use_repentogon_label, sem.danger),
        );
      }
    }

    // ★ 편집 모드에서는 카드 색/테두리/그림자 효과 고정(hover/press 영향 제거)
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

    // 드래그 중 우클릭 메뉴는 비활성(충돌 방지)
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
              // ★ 편집 모드에서는 press 스케일 애니메이션 막음(시작 플래시 방지)
              if (e.buttons == kPrimaryMouseButton && !widget.inEditMode) {
                if (!mounted) return;
                setState(() => _pressed = true);
              }
            },
            onPointerUp:     (_) { if (!mounted || widget.inEditMode) return; setState(() => _pressed = false); },
            onPointerCancel: (_) { if (!mounted || widget.inEditMode) return; setState(() => _pressed = false); },

            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.inEditMode ? () {} : widget.onTap, // 편집 중 탭 무시
              child: AnimatedBuilder(
                animation: _jiggleCtrl,
                builder: (_, child) {
                  final angle = widget.inEditMode ? 0.03 * (_jiggleCtrl.value - 0.5) : 0.0;
                  // ★ 전체 타일을 RepaintBoundary로 감싸 레이어 고정(드래그 프록시 생성 시 깜박임 완화)
                  return RepaintBoundary(
                    child: Transform.rotate(
                      angle: angle,
                      child: child,
                    ),
                  );
                },
                child: AnimatedContainer(
                  // ★ 편집 모드에서는 컨테이너 애니메이션도 즉시 적용(종료 플래시 방지)
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

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== 썸네일 + 플레이/삭제 오버레이 =====
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: RepaintBoundary( // ★ 썸네일까지 경계 분리
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InstanceImageThumb(
                                image: widget.image,
                                fallbackSeed: widget.title,
                                size: 80,
                                borderRadius: br,
                              ),
                              // Hover 시 나타나는 오버레이
                              AnimatedOpacity(
                                // ★ 편집 모드에서는 페이드도 즉시 반영(레이어 전환 플래시 방지)
                                duration: widget.inEditMode
                                    ? Duration.zero
                                    : const Duration(milliseconds: 120),
                                opacity: _hovered ? 1.0 : 0.0,
                                child: IgnorePointer(
                                  ignoring: !_hovered,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints.tightFor(width: 80, height: 80),
                                    child: widget.inEditMode
                                        ? Tooltip(
                                      useMousePosition: false,
                                      message: loc.common_delete,
                                      style: const TooltipThemeData(
                                        verticalOffset: 40,
                                        waitDuration: Duration.zero,
                                        textStyle: AppTypography.sectionTitle,
                                      ),
                                      child: IconButton(
                                        onPressed: widget.onDeleteInstance,
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                            final base = fTheme.accentColor;
                                            final normal = base.normal
                                                .lerpWith(fTheme.scaffoldBackgroundColor, 0.15)
                                                .withAlpha(210);
                                            final hover  = base.light
                                                .lerpWith(fTheme.scaffoldBackgroundColor, 0.08)
                                                .withAlpha(210);
                                            if (states.isHovered) return hover;
                                            return normal;
                                          }),
                                          shape: WidgetStateProperty.all(
                                            const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                          ),
                                          padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                                        ),
                                        icon: const Icon(
                                          FluentIcons.delete,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                        : Tooltip(
                                      useMousePosition: false,
                                      message: loc.common_play,
                                      style: const TooltipThemeData(
                                        verticalOffset: 40,
                                        waitDuration: Duration.zero,
                                        textStyle: AppTypography.sectionTitle,
                                      ),
                                      child: IconButton(
                                        onPressed: widget.onPlayInstance,
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                            final base = fTheme.accentColor;
                                            final normal = base.normal
                                                .lerpWith(fTheme.scaffoldBackgroundColor, 0.15)
                                                .withAlpha(210);
                                            final hover  = base.light
                                                .lerpWith(fTheme.scaffoldBackgroundColor, 0.08)
                                                .withAlpha(210);
                                            if (states.isHovered) return hover;
                                            return normal;
                                          }),
                                          shape: WidgetStateProperty.all(
                                            const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                          ),
                                          padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                                        ),
                                        icon: const Icon(
                                          FluentIcons.play_solid,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      // ===== 텍스트/메뉴/뱃지 =====
                      Expanded(
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
                                    useMousePosition: false,
                                    style: const TooltipThemeData(
                                      maxWidth: 440,
                                      preferBelow: true,
                                      waitDuration: Duration(),
                                    ),
                                    child: Text(
                                      widget.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                // 편집 모드에서는 … 메뉴 숨김 (드래그 충돌/중복 방지)
                                if (!widget.inEditMode)
                                  FlyoutTarget(
                                    controller: _moreFlyout,
                                    child: IconButton(
                                      icon: const Icon(FluentIcons.more_vertical),
                                      onPressed: () {
                                        _moreFlyout.showFlyout(builder: (ctx) => widget.menuBuilder(ctx));
                                      },
                                      style: ButtonStyle(
                                        padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (computedBadges.isNotEmpty)
                              BadgeStrip(badges: computedBadges, height: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

