import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

class ResolvedFluentTheme {
  final ThemeMode mode;
  final FluentThemeData light;
  final FluentThemeData dark;
  const ResolvedFluentTheme({required this.mode, required this.light, required this.dark});
}

class AppTheme {
  static const String _font = AppTypography.fontSans;

  // ------ 단일 ThemeData 팩토리들 ------
  static FluentThemeData _light() => FluentThemeData(
    brightness: Brightness.light,
    fontFamily: _font,
    scaffoldBackgroundColor: AppColors.lightBackground,
    micaBackgroundColor: AppColors.lightMicaBackgroundColor,
    acrylicBackgroundColor: AppColors.lightAcrylicBackgroundColor,
    cardColor: AppColors.lightSurface,
    accentColor: AppColors.lightAccent,
    buttonTheme: _buildButtonTheme(AppColors.lightAccent, isDark: false),
    dividerTheme: const DividerThemeData(decoration: BoxDecoration(color: AppColors.lightDivider)),
    visualDensity: VisualDensity.standard,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: AppColors.lightBackground,
      overlayBackgroundColor: AppColors.lightBackground,
      selectedIconColor:   WidgetStateProperty.all(AppColors.lightAccent.dark),
      unselectedIconColor: WidgetStateProperty.all(AppColors.lightAccent.normal),
    ),
    dialogTheme: ContentDialogThemeData(
      decoration: BoxDecoration(color: AppColors.lightBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
      actionsDecoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: const Border(top: BorderSide(color: AppColors.lightDivider)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(AppRadius.md)),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    ),
  );

  static FluentThemeData _dark() => FluentThemeData(
    brightness: Brightness.dark,
    fontFamily: _font,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    accentColor: AppColors.darkAccent,
    buttonTheme: _buildButtonTheme(AppColors.darkAccent, isDark: true),
    dividerTheme: const DividerThemeData(decoration: BoxDecoration(color: AppColors.darkDivider)),
    visualDensity: VisualDensity.standard,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: AppColors.darkBackground,
      overlayBackgroundColor: AppColors.darkBackground,
      selectedIconColor:   WidgetStateProperty.all(AppColors.darkAccent.dark),
      unselectedIconColor: WidgetStateProperty.all(AppColors.darkAccent.normal),
    ),
    dialogTheme: ContentDialogThemeData(
      decoration: BoxDecoration(color: AppColors.darkBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
      actionsDecoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: const Border(top: BorderSide(color: AppColors.darkDivider)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(AppRadius.md)),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    ),
  );

  static FluentThemeData _oled() => FluentThemeData(
    brightness: Brightness.dark,
    fontFamily: _font,
    scaffoldBackgroundColor: AppColors.oledBackground,
    cardColor: AppColors.oledSurface,
    accentColor: AppColors.darkAccent,
    buttonTheme: _buildButtonTheme(AppColors.darkAccent, isDark: true),
    dividerTheme: const DividerThemeData(decoration: BoxDecoration(color: AppColors.oledDivider)),
    visualDensity: VisualDensity.standard,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: AppColors.oledBackground,
      overlayBackgroundColor: AppColors.oledBackground,
      selectedIconColor:   WidgetStateProperty.all(Colors.white),
      unselectedIconColor: WidgetStateProperty.all(Colors.white),
    ),
    dialogTheme: ContentDialogThemeData(
      decoration: BoxDecoration(color: AppColors.oledBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
      actionsDecoration: BoxDecoration(
        color: AppColors.oledSurface,
        border: const Border(top: BorderSide(color: AppColors.oledDivider)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(AppRadius.md)),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    ),
  );

  static FluentThemeData _tangerine() => FluentThemeData(
    brightness: Brightness.dark,
    fontFamily: _font,
    scaffoldBackgroundColor: AppColors.tangerineBg,
    cardColor: AppColors.tangerineCard,
    accentColor: AppColors.tangerineAccent,
    buttonTheme: _buildButtonTheme(AppColors.tangerineAccent, isDark: true),
    dividerTheme: const DividerThemeData(decoration: BoxDecoration(color: AppColors.tangerineDivider)),
    visualDensity: VisualDensity.standard,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: AppColors.tangerineBg,
      overlayBackgroundColor: AppColors.tangerineBg,
      selectedIconColor:   WidgetStateProperty.all(AppColors.tangerineAccent.dark),
      unselectedIconColor: WidgetStateProperty.all(AppColors.tangerineAccent.normal),
    ),
    dialogTheme: ContentDialogThemeData(
      decoration: BoxDecoration(color: AppColors.tangerineBg, borderRadius: BorderRadius.circular(AppRadius.md)),
      actionsDecoration: BoxDecoration(
        color: AppColors.tangerineCard,
        border: const Border(top: BorderSide(color: AppColors.tangerineDivider)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppRadius.md), bottomRight: Radius.circular(AppRadius.md)),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    ),
  );

  static FluentThemeData _claude() => FluentThemeData(
    brightness: Brightness.light,
    fontFamily: _font,
    scaffoldBackgroundColor: AppColors.claudeBg,
    cardColor: AppColors.claudeCard,
    accentColor: AppColors.claudeAccent,
    buttonTheme: _buildButtonTheme(AppColors.claudeAccent, isDark: false),
    dividerTheme: const DividerThemeData(decoration: BoxDecoration(color: AppColors.claudeDivider)),
    visualDensity: VisualDensity.standard,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: AppColors.claudeBg,
      overlayBackgroundColor: AppColors.claudeBg,
      selectedIconColor:   WidgetStateProperty.all(AppColors.claudeAccent.dark),
      unselectedIconColor: WidgetStateProperty.all(AppColors.claudeAccent.normal),
    ),
    dialogTheme: ContentDialogThemeData(
      decoration: BoxDecoration(color: AppColors.claudeBg, borderRadius: BorderRadius.circular(AppRadius.md)),
      actionsDecoration: BoxDecoration(
        color: AppColors.claudeCard,
        border: const Border(top: BorderSide(color: AppColors.claudeDivider)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppRadius.md), bottomRight: Radius.circular(AppRadius.md)),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    ),
  );

  static final FluentThemeData light     = _light();
  static final FluentThemeData dark      = _dark();
  static final FluentThemeData oled      = _oled();
  static final FluentThemeData tangerine = _tangerine();
  static final FluentThemeData claude    = _claude();

  // ------ ThemeMode/Light/Dark 묶음 해석 ------
  static ResolvedFluentTheme resolve(AppThemeKey key) {
    switch (key) {
      case AppThemeKey.system:
        return ResolvedFluentTheme(mode: ThemeMode.system, light: light, dark: dark);
      case AppThemeKey.light:
        return ResolvedFluentTheme(mode: ThemeMode.light,  light: light,  dark: dark);
      case AppThemeKey.dark:
        return ResolvedFluentTheme(mode: ThemeMode.dark,   light: dark,   dark: dark);
      case AppThemeKey.oled:
        final t = _oled();
        return ResolvedFluentTheme(mode: ThemeMode.dark,   light: t, dark: t);
      case AppThemeKey.tangerine:
        final t = _tangerine();
        return ResolvedFluentTheme(mode: ThemeMode.dark,   light: t, dark: t);
      case AppThemeKey.claude:
        final t = _claude();
        return ResolvedFluentTheme(mode: ThemeMode.light,  light: t, dark: dark);
    }
  }

  // ------ ButtonTheme 유틸 ------
  static ButtonThemeData _buildButtonTheme(AccentColor accent, {required bool isDark}) {
    final rest = accent.normal, hover = accent.light, press = accent.dark;
    final disableBg = (isDark ? Colors.white : Colors.black).withAlpha(25);
    const fg = Colors.white;
    Color? resolveBg(Set<WidgetState> states) {
      if (states.isDisabled) return disableBg;
      if (states.isPressed)  return press;
      if (states.isHovered)  return hover;
      return rest;
    }
    return ButtonThemeData(
      filledButtonStyle: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(resolveBg),
        foregroundColor: WidgetStateProperty.all(fg),
      ),
    );
  }
}

/// Divider 색상 접근 보조
extension FluentThemeX on FluentThemeData {
  Color get dividerColor => (dividerTheme.decoration as BoxDecoration?)?.color ?? (resources.textFillColorSecondary).withAlpha(64);
}
