import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

class SidebarTile extends StatelessWidget {
  const SidebarTile({
    super.key,
    this.icon,
    this.leading,               // Checkbox 등 사용자 정의 leading
    required this.label,
    this.count,
    this.selected = false,
    this.disabled = false,
    this.onTap,
    this.tooltip,
  }) : assert(icon == null || leading == null, 'icon과 leading은 동시에 사용할 수 없습니다.');

  final IconData? icon;         // 상단 모드용
  final Widget? leading;        // 프리셋용(Checkbox)
  final String label;
  final int? count;             // 우측 정렬 카운트 (모드/프리셋 공용)
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final bg = selected ? fTheme.accentColor.withAlpha(32) : fTheme.cardColor;
    final fg = selected ? fTheme.accentColor : fTheme.resources.textFillColorPrimary;
    final border = fTheme.dividerColor;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: disabled ? fTheme.resources.controlFillColorSecondary : bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            Gaps.w8,
          ] else if (icon != null) ...[
            Icon(icon, size: 16, color: disabled ? fTheme.inactiveColor : fg),
            Gaps.w8,
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: disabled ? fTheme.inactiveColor : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (count != null)
            Text(
              '$count',
              style: TextStyle(color: fTheme.inactiveColor),
            ),
        ],
      ),
    );

    final child = tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: disabled ? null : onTap,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: child,
      ),
    );
  }
}
