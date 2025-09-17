import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';

typedef NameOf<T> = String Function(T item);

class ModBadgePolicy {
  static BadgeEngine<T> engine<T>({
    required NameOf<T> nameOf,
  }) {
    return BadgeEngine<T>([
      // 1) Missing (install 그룹)
      BadgeRule<T>(
        id: 'missing',
        exclusiveGroup: 'install',
        priority: 10,
        when: (m) => (m as dynamic).isMissing == true,
        spec: (m, c) => BadgeSpec(c.loc.mod_missing_short, c.sem.danger, icon: FluentIcons.cancel),
      ),

      // 2) CartridgeRecorder: local을 대체하는 전용 뱃지 (install 그룹, local보다 우선)
      BadgeRule<T>(
        id: 'cartridge',
        exclusiveGroup: 'install',
        priority: 15, // local(20)보다 먼저
        when: (m) {
          final mm = m as dynamic;
          final n = nameOf(m);
          return (mm.isLocalMod == true) && RecorderMod.isRecorder(n); // local일 때만 대체
        },
        spec: (m, c) {
          final brand = brandStatusOf(c.context, c.ref, RecorderMod.brandKey);
          final sc = brand ?? c.sem.info;
          return BadgeSpec(c.loc.badge_cartridge_recorder, sc, icon: FluentIcons.starburst_solid);
        },
      ),

      // 3) Local (install 그룹)
      BadgeRule<T>(
        id: 'local',
        exclusiveGroup: 'install',
        priority: 20,
        when: (m) => (m as dynamic).isLocalMod == true,
        spec: (m, c) => BadgeSpec(c.loc.mod_local_short, c.sem.info, icon: FluentIcons.contact),
      ),

      // (필요 시 추가 규칙들…)
    ]);
  }

  static List<BadgeSpec> build<T>({
    required BuildContext context,
    required WidgetRef ref,
    required T row,
    required NameOf<T> nameOf,
    List<BadgeRule<T>> extra = const [],
    List<BadgeSpec> seed = const [],
  }) {
    final loc = AppLocalizations.of(context);
    final sem = ref.watch(themeSemanticsProvider);
    final engine = ModBadgePolicy.engine<T>(nameOf: nameOf);
    final ctx = BadgeBuildCtx(context, ref, loc, sem);
    return BadgeEngine<T>([...engine.rules, ...extra]).build(row, ctx, seed: seed);
  }
}
