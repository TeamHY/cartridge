import 'package:cartridge/theme/tokens/typography.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// 풀-폭 라벨 블록 (팔레트/미리보기 등 큰 컨텐츠용)
class LabeledBlock extends StatelessWidget {
  final String label;
  final Widget child;
  final EdgeInsetsGeometry spacing;
  const LabeledBlock({
    super.key,
    required this.label,
    required this.child,
    this.spacing = const EdgeInsets.only(bottom: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: AppTypography.bodyStrong
          ),
        ),
        child,
      ],
    );
  }
}
