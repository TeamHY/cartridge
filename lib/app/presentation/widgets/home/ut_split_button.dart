import 'package:cartridge/theme/theme.dart'; // AppSpacing, AppRadius, Gaps 등
import 'package:fluent_ui/fluent_ui.dart';

class UtSplitButton extends StatefulWidget {
  const UtSplitButton({
    super.key,
    required this.mainButtonText,
    required this.buttonColor,
    required this.onMainButtonPressed,
    required this.dropdownMenuItems,
    this.secondaryText,
    this.enabled = true,
    this.hasDropdown = true,
    this.dropdownBuilder,
  });

  /// dropdown 없이 한 덩어리 버튼(같은 스킨 유지)
  const UtSplitButton.single({
    Key? key,
    required String mainButtonText,
    String? secondaryText,
    required Color buttonColor,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) : this(
    key: key,
    mainButtonText: mainButtonText,
    secondaryText: secondaryText,
    buttonColor: buttonColor,
    onMainButtonPressed: onPressed ?? _noop,
    dropdownMenuItems: const [],
    enabled: enabled,
    hasDropdown: false,
  );

  /// disabled 전용 팩토리 (스킨 유지)
  const UtSplitButton.disabled({
    Key? key,
    required String mainButtonText,
    String? secondaryText,
    required Color buttonColor,
  }) : this.single(
    key: key,
    mainButtonText: mainButtonText,
    secondaryText: secondaryText,
    buttonColor: buttonColor,
    onPressed: null,
    enabled: false,
  );

  final String mainButtonText;
  final String? secondaryText;
  final Color buttonColor;
  final VoidCallback onMainButtonPressed;
  final List<MenuFlyoutItem> dropdownMenuItems;

  final bool enabled;
  final bool hasDropdown;
  final WidgetBuilder? dropdownBuilder;

  @override
  State<UtSplitButton> createState() => _UtSplitButtonState();
}

void _noop() {}

class _UtSplitButtonState extends State<UtSplitButton> {
  bool _isMainButtonHovered = false;
  bool _isMainButtonPressed = false;
  bool _isDropdownButtonHovered = false;
  bool _isDropdownButtonPressed = false;

  final flyoutController = FlyoutController();

  // 🎯 테마 토큰
  static const double _buttonHeight = 60.0;
  static const double _chevronWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    // 📌 semantic tokens
    final Color strokeColor = theme.resources.controlStrokeColorDefault;
    final Color textOnAccent = theme.resources.textOnAccentFillColorSelectedText;
    final Color textDisabled = theme.inactiveColor;

    final primaryColor = widget.buttonColor;

    final hoveredMain  = _isMainButtonHovered   && widget.enabled;
    final pressedMain  = _isMainButtonPressed   && widget.enabled;
    final hoveredRight = _isDropdownButtonHovered && widget.enabled;
    final pressedRight = _isDropdownButtonPressed && widget.enabled;

    final mainBg = widget.enabled
        ? _resolveBg(
      base: primaryColor,
      hovered: hoveredMain,
      pressed: pressedMain,
      brightness: theme.brightness,
    )
        : _disabledFill(primaryColor, theme.brightness);

    final rightBg = widget.hasDropdown
        ? (widget.enabled
        ? _resolveBg(
      base: primaryColor,
      hovered: hoveredRight,
      pressed: pressedRight,
      brightness: theme.brightness,
    )
        : _disabledFill(primaryColor, theme.brightness))
        : mainBg;

    final textColor = widget.enabled ? textOnAccent : textDisabled;

    final BorderRadius leftRadius = widget.hasDropdown
        ? const BorderRadius.only(
      topLeft: Radius.circular(AppRadius.lg),
      bottomLeft: Radius.circular(AppRadius.lg),
    )
        : BorderRadius.circular(AppRadius.lg);

    final BorderRadius rightRadius = const BorderRadius.only(
      topRight: Radius.circular(AppRadius.lg),
      bottomRight: Radius.circular(AppRadius.lg),
    );

    // 메인(좌/단독)
    final mainButton = FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (_) => setState(() {}),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isMainButtonHovered = true),
        onExit: (_) => setState(() => _isMainButtonHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isMainButtonPressed = true),
          onTapUp: (_) => setState(() => _isMainButtonPressed = false),
          onTapCancel: () => setState(() => _isMainButtonPressed = false),
          onTap: widget.enabled ? widget.onMainButtonPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: _buttonHeight,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: mainBg,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: strokeColor),
                borderRadius: leftRadius,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.play_solid, color: textColor),
                  Gaps.w8,
                  Expanded(
                    child: _TwoLineLabel(
                      primary: widget.mainButtonText,
                      secondary: widget.secondaryText,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 드롭다운(우)
    final dropdownButton = !widget.hasDropdown
        ? const SizedBox.shrink()
        : FlyoutTarget(
      controller: flyoutController,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (_) => setState(() {}),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isDropdownButtonHovered = true),
          onExit: (_) => setState(() => _isDropdownButtonHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isDropdownButtonPressed = true),
            onTapUp: (_) => setState(() => _isDropdownButtonPressed = false),
            onTapCancel: () => setState(() => _isDropdownButtonPressed = false),
            onTap: (widget.enabled &&
                (widget.dropdownBuilder != null ||
                    widget.dropdownMenuItems.isNotEmpty))
                ? () {
              flyoutController.showFlyout(
                barrierColor: Colors.transparent,
                placementMode: FlyoutPlacementMode.bottomRight,
                builder: (ctx) {
                  final custom = widget.dropdownBuilder?.call(ctx);
                  if (custom != null) return custom;

                  return MenuFlyout(
                    constraints: const BoxConstraints(maxWidth: 260),
                    items: widget.dropdownMenuItems,
                  );
                },
              );
            }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: _buttonHeight,
              width: _chevronWidth,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: rightBg,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: strokeColor),
                  borderRadius: rightRadius,
                ),
              ),
              child: Icon(
                FluentIcons.chevron_down,
                size: 14,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: mainButton),
        if (widget.hasDropdown) dropdownButton,
      ],
    );
  }
}

class _TwoLineLabel extends StatelessWidget {
  const _TwoLineLabel({
    required this.primary,
    required this.secondary,
    required this.color,
  });

  final String primary;
  final String? secondary;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typo = FluentTheme.of(context).typography;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typo.bodyStrong?.copyWith(
            color: color,
            fontSize: 14,
          ),
        ),
        if (secondary != null) ...[
          Gaps.h2,
          Text(
            secondary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.caption?.copyWith(
              color: color.withAlpha(220),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// === helpers ===

Color _disabledFill(Color base, Brightness b) =>
    base.withAlpha(b == Brightness.dark ? 50 : 28);

Color _resolveBg({
  required Color base,
  required bool hovered,
  required bool pressed,
  required Brightness brightness,
}) {
  // 테마 문서: hover/pressed는 overlay로 계산 (밝기별 알파 차등)
  final hoverOverlay   = (brightness == Brightness.dark)
      ? Colors.white.withAlpha(20)
      : Colors.black.withAlpha(15);
  final pressedOverlay = (brightness == Brightness.dark)
      ? Colors.white.withAlpha(40)
      : Colors.black.withAlpha(30);

  final overlay = pressed ? pressedOverlay : (hovered ? hoverOverlay : Colors.transparent);
  return Color.alphaBlend(overlay, base);
}
