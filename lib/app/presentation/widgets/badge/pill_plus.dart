import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/theme/theme.dart';

/// (+n) 전용 알약
class PlusPill extends ConsumerWidget {
  const PlusPill(this.count, {super.key});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: sem.neutral.bg,
        border: Border.all(color: sem.neutral.border),
        borderRadius: AppShapes.pill,
      ),
      child: Text(
        '+${count.toString()}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: fTheme.typography.caption?.copyWith(
          color: sem.neutral.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
