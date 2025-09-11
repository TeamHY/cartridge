import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/theme/theme.dart';


/// 두 번째 액센트 팔레트(없으면 파생)
typedef _Accent2Overrides = ({AccentColor? light, AccentColor? dark});

/// (선택) 테마별 수동 오버라이드 등록처
final accent2OverridesProvider = Provider<_Accent2Overrides?>((ref) {
  final key = ref.watch(selectedThemeKeyProvider);
  switch (key) {
    case AppThemeKey.system:
      return (light: AppColors.lightAccent2, dark: AppColors.darkAccent2);
    case AppThemeKey.light:
      return (light: AppColors.lightAccent2, dark: null);
    case AppThemeKey.dark:
      return (light: null, dark: AppColors.darkAccent2);
    case AppThemeKey.oled:
      return (light: null, dark: AppColors.darkAccent2);
    case AppThemeKey.tangerine:
      return (light: null, dark: AppColors.tangerineAccent2);
    case AppThemeKey.claude:
      return (light: AppColors.claudeAccent2, dark: null);
  }
});

/// 파생 규칙: 1차 accent에서 Hue +S, Lightness 조절로 2차 accent 생성
AccentColor _deriveAccent2(AccentColor primary, Brightness b) {
  Color shift(Color c, {double dh = 18, double ds = -0.08, double dl = 0.06}) {
    final hsl = HSLColor.fromColor(c);
    final hue = (hsl.hue + dh) % 360.0;
    final sat = (hsl.saturation + ds).clamp(0.0, 1.0);
    final lig = (b == Brightness.dark)
        ? (hsl.lightness + dl).clamp(0.0, 1.0)
        : (hsl.lightness - dl).clamp(0.0, 1.0);
    return hsl.withHue(hue).withSaturation(sat).withLightness(lig).toColor();
  }

  return makeAccent2From(shift(primary.normal));
}

/// 컨텍스트의 밝기/현행 1차 accent를 받아 2차 accent를 돌려주는 Resolver
typedef Accent2Resolver = AccentColor Function(Brightness, AccentColor);

final accent2ResolverProvider = Provider<Accent2Resolver>((ref) {
  final overrides = ref.watch(accent2OverridesProvider);
  return (brightness, primary) {
    final manual = (brightness == Brightness.dark) ? overrides?.dark : overrides?.light;
    return manual ?? _deriveAccent2(primary, brightness);
  };
});

/// 사용성 보조: BuildContext + Ref 만으로 바로 2차 액센트 얻기
AccentColor accent2Of(BuildContext context, WidgetRef ref) {
  final theme = FluentTheme.of(context);
  final resolve = ref.watch(accent2ResolverProvider);
  return resolve(theme.brightness, theme.accentColor);
}

StatusColor _statusFromSeed(Color seed, Brightness b) => StatusColor(
  fg: seed,
  bg: seed.withAlpha(b == Brightness.dark ? 60 : 20),
  border: seed.withAlpha(b == Brightness.dark ? 130 : 160),
);

typedef Accent2StatusResolver = StatusColor Function(Brightness, AccentColor);

final accent2StatusResolverProvider = Provider<Accent2StatusResolver>((ref) {
  final resolveAccent2 = ref.watch(accent2ResolverProvider);
  return (brightness, primaryAccent) {
    final ac2 = resolveAccent2(brightness, primaryAccent);
    return _statusFromSeed(ac2.normal, brightness);
  };
});

StatusColor accent2StatusOf(BuildContext context, WidgetRef ref) {
  final theme = FluentTheme.of(context);
  final resolve = ref.watch(accent2StatusResolverProvider);
  return resolve(theme.brightness, theme.accentColor);
}