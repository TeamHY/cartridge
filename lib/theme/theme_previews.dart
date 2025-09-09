import 'package:fluent_ui/fluent_ui.dart';

import 'app_theme.dart';
import 'tokens/colors.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class ThemePreview {
  final String title;
  final Color bg, surface, text1, text2, accent;
  const ThemePreview({required this.title, required this.bg, required this.surface, required this.text1, required this.text2, required this.accent});
}

final Map<AppThemeKey, ThemePreview> kThemePreviews = {
  AppThemeKey.system:    ThemePreview(title: 'System',  bg: AppTheme.light.scaffoldBackgroundColor, surface: AppTheme.light.cardColor, text1: const Color(0xFF222222), text2: const Color(0xFF667085), accent: AppColors.lightAccent.normal),
  AppThemeKey.light:     ThemePreview(title: 'Light',   bg: AppTheme.light.scaffoldBackgroundColor, surface: AppTheme.light.cardColor,  text1: const Color(0xFF2E3440), text2: const Color(0xFF667085), accent: AppColors.lightAccent.normal),
  AppThemeKey.dark:      ThemePreview(title: 'Dark',    bg: AppTheme.dark.scaffoldBackgroundColor,  surface: AppTheme.dark.cardColor,   text1: const Color(0xFFBFC3C8), text2: const Color(0xFF8C96A0), accent: AppColors.darkAccent.normal),
  AppThemeKey.oled:      ThemePreview(title: 'OLED',    bg: AppColors.oledBackground, surface: AppColors.oledSurface, text1: const Color(0xFFBFC3C8), text2: const Color(0xFF8C96A0), accent: AppColors.darkAccent.normal),
  AppThemeKey.tangerine: ThemePreview(title: 'Tangerine', bg: AppColors.tangerineBg, surface: AppColors.tangerineCard, text1: const Color(0xFFD7DBE7), text2: const Color(0xFFA8AEC1), accent: AppColors.tangerineAccent.normal),
  AppThemeKey.claude:    ThemePreview(title: 'Claude',  bg: AppColors.claudeBg, surface: AppColors.claudeCard, text1: const Color(0xFF3B3B32), text2: const Color(0xFF7A7A6D), accent: AppColors.claudeAccent.normal),
};

const List<AppThemeKey> kThemeOrder = [
  AppThemeKey.system, AppThemeKey.light, AppThemeKey.dark, AppThemeKey.oled, AppThemeKey.tangerine, AppThemeKey.claude,
];

String localizedThemeName(AppLocalizations loc, AppThemeKey key) {
  switch (key) {
    case AppThemeKey.system:    return loc.setting_theme_system;
    case AppThemeKey.light:     return loc.setting_theme_light;
    case AppThemeKey.dark:      return loc.setting_theme_dark;
    case AppThemeKey.oled:      return loc.setting_theme_oled;
    case AppThemeKey.tangerine: return loc.setting_theme_tangerine;
    case AppThemeKey.claude:    return loc.setting_theme_claude;
  }
}
