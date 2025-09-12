import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/theme/theme.dart';

class Pill extends StatelessWidget {
  const Pill(this.spec, {super.key});
  final BadgeSpec spec;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: spec.statusColor.bg,
        border: Border.all(color: spec.statusColor.border),
        borderRadius: AppShapes.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spec.icon != null) ...[
            Icon(spec.icon, size: 12, color: spec.statusColor.fg),
            Gaps.w4,
          ],
          Text(
            spec.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: fTheme.typography.caption?.copyWith(
              color: spec.statusColor.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}