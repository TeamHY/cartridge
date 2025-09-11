import 'package:cartridge/theme/theme.dart';
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

  static const double buttonHeight = 60.0;
  static const double buttonRadius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final primaryColor = widget.buttonColor;
    final Color dividerColor = theme.dividerColor;

    final hoveredMain   = _isMainButtonHovered   && widget.enabled;
    final pressedMain   = _isMainButtonPressed   && widget.enabled;
    final hoveredRight  = _isDropdownButtonHovered && widget.enabled;
    final pressedRight  = _isDropdownButtonPressed && widget.enabled;

    final mainBg = widget.enabled
        ? _resolveBg(
      base: primaryColor,
      hovered: hoveredMain,
      pressed: pressedMain,
      brightness: theme.brightness,
    )
        : primaryColor.withAlpha(theme.brightness == Brightness.dark ? 50 : 28);

    final rightBg = widget.hasDropdown
        ? (widget.enabled
        ? _resolveBg(
      base: primaryColor,                // 같은 베이스
      // 살짝 약하게 보이길 원하면 overlay만 줄이지 말고 아래처럼 알파 한번 더 낮춰도 됨:
      // base: primaryColor.withOpacity(0.95),
      hovered: hoveredRight,
      pressed: pressedRight,
      brightness: theme.brightness,
    )
        : primaryColor.withAlpha(theme.brightness == Brightness.dark ? 50 : 28))
        : mainBg;

    final textColor = widget.enabled
        ? theme.resources.textOnAccentFillColorSelectedText
        : theme.inactiveColor;

    // 메인 버튼(좌측 또는 단일)
    final mainButton = MouseRegion(
      onEnter: (_) => setState(() => _isMainButtonHovered = true),
      onExit: (_) => setState(() => _isMainButtonHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isMainButtonPressed = true),
        onTapUp: (_) => setState(() => _isMainButtonPressed = false),
        onTapCancel: () => setState(() => _isMainButtonPressed = false),
        onTap: widget.enabled ? widget.onMainButtonPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: buttonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: widget.hasDropdown
                ? Border(
              left: BorderSide(color: dividerColor),
              top: BorderSide(color: dividerColor),
              bottom: BorderSide(color: dividerColor),
            )
                : Border.all(color: dividerColor),
            color: mainBg,
            borderRadius: widget.hasDropdown
                ? const BorderRadius.only(
              topLeft: Radius.circular(buttonRadius),
              bottomLeft: Radius.circular(buttonRadius),
            )
                : BorderRadius.circular(buttonRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.play_solid, color: textColor),
                Gaps.w8,
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.mainButtonText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.secondaryText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.secondaryText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.enabled ? textColor.withAlpha(220) : textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 드롭다운 버튼(우측) — 필요 없으면 렌더링 생략
    final dropdownButton = !widget.hasDropdown
        ? const SizedBox.shrink()
        : FlyoutTarget( // ★ 버튼 자체를 앵커로
      controller: flyoutController,
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
                  constraints: const BoxConstraints(maxWidth: 280),
                  color: primaryColor.withAlpha(100),
                  items: widget.dropdownMenuItems,
                );
              },
            );
          }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: buttonHeight,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: dividerColor),
                right: BorderSide(color: dividerColor),
                bottom: BorderSide(color: dividerColor),
              ),
              color: rightBg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(buttonRadius),
                bottomRight: Radius.circular(buttonRadius),
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

Color _resolveBg({
  required Color base,
  required bool hovered,
  required bool pressed,
  required Brightness brightness,
}) {
  // Fluent 권장 톤: hover < pressed (light: 어둡게, dark: 밝게)
  final hoverOverlay   = (brightness == Brightness.dark)
      ? Colors.white.withAlpha(20)
      : Colors.black.withAlpha(15);
  final pressedOverlay = (brightness == Brightness.dark)
      ? Colors.white.withAlpha(40)
      : Colors.black.withAlpha(30);

  final overlay = pressed ? pressedOverlay : (hovered ? hoverOverlay : Colors.transparent);
  return Color.alphaBlend(overlay, base);
}
