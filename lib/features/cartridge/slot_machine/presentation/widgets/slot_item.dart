import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/theme/theme.dart';

class SlotItem extends ConsumerWidget {
  const SlotItem({
    super.key,
    required this.width,
    required this.height,
    required this.text,
  });

  final double width;
  final double height;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fTheme.cardColor,
        borderRadius: AppShapes.card,
        border: Border.all(
          color: sem.neutral.border,
          width: 2,
        ),
        // radius 없음 (theme 규칙)
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.clip,
          style: AppTypography.slotItem,
        ),
      ),
    );
  }
}
