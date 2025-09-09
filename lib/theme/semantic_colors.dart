import 'package:fluent_ui/fluent_ui.dart';
import 'tokens/colors.dart';

class StatusColor {
  final Color fg;     // 전경(텍스트/아이콘/배지 테두리)
  final Color bg;     // 배경(하이라이트)
  final Color border; // 경계선
  const StatusColor({required this.fg, required this.bg, required this.border});
}

class AppSemanticColors {
  final StatusColor info, success, warning, danger, neutral;
  const AppSemanticColors({required this.info, required this.success, required this.warning, required this.danger, required this.neutral});
}

StatusColor _make(Color base, {required bool dark}) =>
    StatusColor(fg: base, bg: base.withAlpha(dark ? 60 : 20), border: base.withAlpha(dark ? 130 : 160));

const _infoBase    = Color(0xFF3B82F6);
const _successBase = Color(0xFF16A34A);
const _warningBase = Color(0xFFF59E0B);
const _dangerBase  = Color(0xFFEF4444);
const _neutralBase = Color(0xFF64748B);

final _semLight = AppSemanticColors(
  info:    _make(_infoBase,    dark: false),
  success: _make(_successBase, dark: false),
  warning: _make(_warningBase, dark: false),
  danger:  _make(_dangerBase,  dark: false),
  neutral: _make(_neutralBase, dark: false),
);
final _semDark = AppSemanticColors(
  info:    _make(_infoBase,    dark: true),
  success: _make(_successBase, dark: true),
  warning: _make(_warningBase, dark: true),
  danger:  _make(_dangerBase,  dark: true),
  neutral: _make(_neutralBase, dark: true),
);
final _semTangerine = AppSemanticColors(
  info:    _make(_infoBase,    dark: true),
  success: _make(_successBase, dark: true),
  warning: _make(const Color(0xFFF59E0B), dark: true),
  danger:  _make(_dangerBase,  dark: true),
  neutral: _make(_neutralBase, dark: true),
);
final _semClaude = AppSemanticColors(
  info:    _make(_infoBase,    dark: false),
  success: _make(_successBase, dark: false),
  warning: _make(const Color(0xFFE3A008), dark: false),
  danger:  _make(_dangerBase,  dark: false),
  neutral: _make(_neutralBase, dark: false),
);

/// 선택된 테마 키 기준으로 의미색 반환(OLED=dark 계열)
AppSemanticColors semanticsFor(AppThemeKey key) {
  switch (key) {
    case AppThemeKey.tangerine: return _semTangerine;
    case AppThemeKey.claude:    return _semClaude;
    case AppThemeKey.dark:
    case AppThemeKey.oled:      return _semDark;
    case AppThemeKey.system:
    case AppThemeKey.light:     return _semLight;
  }
}
