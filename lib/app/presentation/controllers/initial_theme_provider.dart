import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/theme/theme.dart';

final initialThemeProvider = Provider<ResolvedFluentTheme>((ref) {
  final b = PlatformDispatcher.instance.platformBrightness;
  final key = (b == Brightness.dark) ? AppThemeKey.dark : AppThemeKey.light;
  return AppTheme.resolve(key);
});