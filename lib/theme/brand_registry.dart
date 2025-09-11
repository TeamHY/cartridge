import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'semantic_colors.dart';

// 필요시 따로 선언해 두면 오타 방지에 좋아요.
class BrandKeys {
  static const repentogon = 'repentogon';
  static const cartridge = RecorderMod.brandKey;
}

// 1) 하나의 소스: 브랜드별 "seed color"만 등록
final brandSeedRegistryProvider = Provider<Map<String, Color>>((ref) => {
  BrandKeys.repentogon: const Color(0xFFFF0000),
  BrandKeys.cartridge: const Color(0xFFb2706e),
});

// 2) 파생 유틸
StatusColor _statusFromSeed(Color seed, Brightness b) => StatusColor(
  fg: seed,
  bg: seed.withAlpha(b == Brightness.dark ? 60 : 20),
  border: seed.withAlpha(b == Brightness.dark ? 130 : 160),
);

AccentColor _accentFromSeed(Color seed) => seed.toAccentColor(
  lightFactor:   0.08,
  lighterFactor: 0.16,
  darkFactor:    0.10,
  darkerFactor:  0.18,
);

// 3) 파생 팔레트(상태색/액센트 모두 제공)
class BrandPalette {
  final Color seed;
  final AccentColor accent;
  const BrandPalette({required this.seed, required this.accent});
  StatusColor status(Brightness b) => _statusFromSeed(seed, b);
}

// 4) 씨앗 → 팔레트 맵(전역)
final brandPaletteRegistryProvider = Provider<Map<String, BrandPalette>>((ref) {
  final seeds = ref.watch(brandSeedRegistryProvider);
  return seeds.map((key, seed) => MapEntry(
    key,
    BrandPalette(seed: seed, accent: _accentFromSeed(seed)),
  ));
});

// 5) 헬퍼: 어디서든 불러쓰기 좋게
StatusColor? brandStatusOf(BuildContext ctx, WidgetRef ref, String brandKey) {
  final b = FluentTheme.of(ctx).brightness;
  final pal = ref.read(brandPaletteRegistryProvider)[brandKey];
  return pal?.status(b);
}

StatusColor repentogonStatusOf(BuildContext context, WidgetRef ref) =>
    brandStatusOf(context, ref, BrandKeys.repentogon)!;
StatusColor cartridgeStatusOf(BuildContext context, WidgetRef ref) =>
    brandStatusOf(context, ref, BrandKeys.cartridge)!;

AccentColor? brandAccentOf(WidgetRef ref, String brandKey) {
  return ref.read(brandPaletteRegistryProvider)[brandKey]?.accent;
}
