import 'package:fluent_ui/fluent_ui.dart';

/// 테마 키(설정 화면에서도 이 enum을 직접 사용)
enum AppThemeKey { system, light, dark, oled, tangerine, claude }

/// 레거시 색 팔레트(의미는 기존과 동일)
class AppColors {
  // Light
  static const lightBackground = Color(0xfff5f5f5);
  static const lightSurface = Color(0xffffffff);
  static final lightAccent = AccentColor.swatch(const {
    'normal': Color(0xFF2563EB),
    'light':  Color(0xFF3B82F6),
    'dark':   Color(0xFF1D4ED8),
  });
  static const lightDivider = Color(0xFFe5e7eb);
  static const lightMicaBackgroundColor = Color(0xFFF5F7FA);
  static const lightAcrylicBackgroundColor = Color(0xC0F0F7FF);

  // Dark
  static const darkBackground = Color(0xFF1E1E1E);
  static const darkSurface    = Color(0xFF2E2E2E);
  static final darkAccent = AccentColor.swatch(const {
    'normal': Color(0xFF3B82F6),
    'light':  Color(0xFF60A5FA),
    'dark':   Color(0xFF2563EB),
  });
  static const darkDivider = Color(0xFF454545);

  // OLED
  static const oledBackground = Color(0xFF000000);
  static const oledSurface    = Color(0xFF0A0A0A);
  static const oledDivider    = Color(0xFFCACACA);

  // Tangerine (Dark)
  static final tangerineAccent = AccentColor.swatch(const {
    'normal': Color(0xFFF59E0B),
    'light':  Color(0xFFFBBF24),
    'dark':   Color(0xFFD97706),
  });
  static const tangerineBg      = Color(0xFF1C2433);
  static const tangerineCard    = Color(0xFF2A3040);
  static const tangerineDivider = Color(0xFF3D4354);

  // Claude (Light)
  static final claudeAccent = AccentColor.swatch(const {
    'normal': Color(0xFFC96442),
    'light':  Color(0xFFC98757),
    'dark':   Color(0xFFAC5032),
  });
  static const claudeBg      = Color(0xFFf5f4ee);
  static const claudeCard    = Color(0xFFfaf9f5);
  static const claudeDivider = Color(0xFFdad9d4);
}
