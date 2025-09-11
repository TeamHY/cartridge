import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/app/presentation/widgets/badge/badge.dart';

class BadgeBuildCtx {
  final BuildContext context;
  final WidgetRef ref;
  final AppLocalizations loc;
  final AppSemanticColors sem;
  const BadgeBuildCtx(this.context, this.ref, this.loc, this.sem);
}

typedef BadgeSpecMaker<T> = BadgeSpec Function(T item, BadgeBuildCtx ctx);

class BadgeRule<T> {
  final String id;
  final String? exclusiveGroup; // 같은 그룹에서 하나 매칭되면 이후 규칙 skip
  final bool Function(T) when;
  final BadgeSpecMaker<T> spec;
  final int priority; // 낮을수록 먼저
  const BadgeRule({
    required this.id,
    required this.when,
    required this.spec,
    this.exclusiveGroup,
    this.priority = 100,
  });
}

class BadgeEngine<T> {
  final List<BadgeRule<T>> rules;
  const BadgeEngine(this.rules);

  List<BadgeSpec> build(T item, BadgeBuildCtx ctx, {List<BadgeSpec> seed = const []}) {
    final out = <BadgeSpec>[...seed];
    final matchedGroups = <String>{};
    final sorted = [...rules]..sort((a, b) => a.priority.compareTo(b.priority));

    for (final r in sorted) {
      if (r.exclusiveGroup != null && matchedGroups.contains(r.exclusiveGroup)) continue;
      if (r.when(item)) {
        out.add(r.spec(item, ctx));
        if (r.exclusiveGroup != null) matchedGroups.add(r.exclusiveGroup!);
      }
    }
    return out;
  }
}
