import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'tokens/colors.dart';
import 'semantic_colors.dart';


final selectedThemeKeyProvider = Provider<AppThemeKey>((ref) {
  final s = ref.watch(appSettingControllerProvider);
  return s.maybeWhen(
    data: (st) => themeKeyFromName(st.themeName),
    orElse: () => AppThemeKey.system,
  );
});

final themeSemanticsProvider = Provider<AppSemanticColors>((ref) {
  final key = ref.watch(selectedThemeKeyProvider);
  return semanticsFor(key);
});

final resolvedThemeProvider = Provider<ResolvedFluentTheme>((ref) {
  final key = ref.watch(selectedThemeKeyProvider);
  return AppTheme.resolve(key);
});

AppThemeKey themeKeyFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'system':    return AppThemeKey.system;
    case 'light':     return AppThemeKey.light;
    case 'dark':      return AppThemeKey.dark;
    case 'oled':      return AppThemeKey.oled;
    case 'tangerine': return AppThemeKey.tangerine;
    case 'claude':    return AppThemeKey.claude;
    default:          return AppThemeKey.system;
  }
}