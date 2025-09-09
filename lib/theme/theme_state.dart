import 'package:cartridge/providers/setting_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'tokens/colors.dart';
import 'semantic_colors.dart';


final selectedThemeKeyProvider = Provider<AppThemeKey>((ref) {
  return ref.watch(settingProvider).themeKey;
});

final themeSemanticsProvider = Provider<AppSemanticColors>((ref) {
  final key = ref.watch(selectedThemeKeyProvider);
  return semanticsFor(key);
});

final resolvedThemeProvider = Provider<ResolvedFluentTheme>((ref) {
  final key = ref.watch(selectedThemeKeyProvider);
  return AppTheme.resolve(key);
});