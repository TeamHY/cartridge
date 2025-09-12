import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

enum _ResponsiveMode { iconText, textOnly, iconOnly }

class UTFloatingSelectionBar<T> extends StatelessWidget {
  const UTFloatingSelectionBar({
    super.key,
    required this.selected,
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
  });

  final List<T> selected;

  // 대상 판별
  final bool Function(T row)? canEnable;
  final bool Function(T row)? canDisable;
  final bool Function(T row)? canFavoriteOn;
  final bool Function(T row)? canFavoriteOff;

  // 액션
  final void Function(List<T> rows)? onEnableSelected;
  final void Function(List<T> rows)? onDisableSelected;
  final void Function(List<T> rows)? onFavoriteOnSelected;
  final void Function(List<T> rows)? onFavoriteOffSelected;
  final void Function(List<T> rows)? onSharePlainSelected;
  final void Function(List<T> rows)? onShareMarkdownSelected;
  final void Function(List<T> rows)? onShareRichSelected;

  List<T> _filter(bool Function(T r)? pred) =>
      pred == null ? const [] : selected.where(pred).toList();

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final isDark = fTheme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    // 반응형 폭 계산
    final double screenW = MediaQuery.of(context).size.width;
    final double barW = math.min(1100.0, screenW - 32.0);

    const double bpIconText = 900;
    const double bpTextOnly = 560;
    final _ResponsiveMode mode = (barW >= bpIconText)
        ? _ResponsiveMode.iconText
        : (barW >= bpTextOnly)
        ? _ResponsiveMode.textOnly
        : _ResponsiveMode.iconOnly;

    final dividerColor = fTheme.dividerColor.withAlpha(isDark ? 60 : 40);
    final accent = fTheme.accentColor.normal;
    final accentHalo = accent.withAlpha(isDark ? 120 : 90);

    final box = BoxDecoration(
      color: fTheme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Color.lerp(dividerColor, accent, 0.35)!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color.fromARGB(90, 0, 0, 0).withAlpha(isDark ? 90 : 40),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accentHalo,
          blurRadius: 22,
          spreadRadius: 1.5,
          offset: const Offset(0, 0),
        ),
      ],
    );

    Widget btn(String label, IconData icon, VoidCallback? onPressed) {
      Widget child;
      switch (mode) {
        case _ResponsiveMode.iconText:
          child = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              Gaps.w8,
              Text(label),
            ],
          );
          break;
        case _ResponsiveMode.textOnly:
          child = Text(label);
          break;
        case _ResponsiveMode.iconOnly:
          child = Tooltip(
            message: label,
            style: const TooltipThemeData(waitDuration: Duration(milliseconds: 0)),
            child: Icon(icon, size: 16),
          );
          break;
      }
      return Button(onPressed: onPressed, child: child);
    }

    final favOnTargets = _filter(canFavoriteOn);
    final favOffTargets = _filter(canFavoriteOff);
    final enTargets = _filter(canEnable);
    final disTargets = _filter(canDisable);

    final List<MenuFlyoutItemBase> shareItems = [
      if (onSharePlainSelected != null)
        MenuFlyoutItem(
          text: Text(loc.selection_copy_plain),
          onPressed: () => onSharePlainSelected!(selected),
        ),
      if (onShareMarkdownSelected != null)
        MenuFlyoutItem(
          text: Text(loc.selection_copy_markdown),
          onPressed: () => onShareMarkdownSelected!(selected),
        ),
      if (onShareRichSelected != null)
        MenuFlyoutItem(
          text: Text(loc.selection_copy_html),
          onPressed: () => onShareRichSelected!(selected),
        ),
    ];

    final buttons = <Widget>[
      if (shareItems.isNotEmpty)
        DropDownButton(
          title: Row(
            children: [
              const Icon(FluentIcons.share),
              Gaps.w6,
              Text(loc.selection_share),
            ],
          ),
          items: shareItems,
        ),
      if (canFavoriteOn != null && favOnTargets.isNotEmpty)
        btn(loc.selection_favorite_on, FluentIcons.heart_fill,
            onFavoriteOnSelected == null ? null : () => onFavoriteOnSelected!(favOnTargets)),
      if (canFavoriteOff != null && favOffTargets.isNotEmpty)
        btn(loc.selection_favorite_off, FluentIcons.heart,
            onFavoriteOffSelected == null ? null : () => onFavoriteOffSelected!(favOffTargets)),
      if (canEnable != null && enTargets.isNotEmpty)
        btn(loc.selection_enable_mods, FluentIcons.power_button,
            onEnableSelected == null ? null : () => onEnableSelected!(enTargets)),
      if (canDisable != null && disTargets.isNotEmpty)
        btn(loc.selection_disable_mods, FluentIcons.blocked2,
            onDisableSelected == null ? null : () => onDisableSelected!(disTargets)),
    ];

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: box,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < buttons.length; i++) ...[
                  buttons[i],
                  if (i != buttons.length - 1) Gaps.w8,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
