import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

class AllowedModsSkeleton extends StatelessWidget {
  const AllowedModsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final fill = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    Widget bar(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stroke, width: .8),
      ),
    );

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          bar(32),
          Gaps.h8,
          bar(24),
          Gaps.h8,
          bar(24),
          Gaps.h12,
          bar(12),
          const Spacer(),
        ],
      ),
    );
  }
}
