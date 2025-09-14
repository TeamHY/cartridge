// lib/features/cartridge/record_mode/presentation/layout/record_grid.dart
import 'package:fluent_ui/fluent_ui.dart';

/// 그리드 한 칸(row)의 기준 높이. 화면 폭에 따라 약간 줄여서 응답형으로.
double _rowUnitForWidth(double w) {
  if (w < 820) return 64;   // 좁은 화면
  if (w < 1040) return 68;  // 중간
  return 72;                // 넓은 화면 (기본)
}

/// 카드 스타일(테마 준수)
Widget gridCard(BuildContext context, {required Widget child}) {
  final t = FluentTheme.of(context);
  return Container(
    decoration: BoxDecoration(
      color: t.resources.cardBackgroundFillColorDefault,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: t.resources.controlStrokeColorSecondary.withAlpha(32),
        width: .8,
      ),
    ),
    child: child,
  );
}

/// row 단위 높이를 보장하는 섹션.
/// [rows] × rowUnit 만큼 높이를 확보해 내부 레이아웃이 흔들리지 않도록 한다.
class RowSection extends StatelessWidget {
  const RowSection({
    super.key,
    required this.rows,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final int rows; // 확보할 행 수
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final row = _rowUnitForWidth(c.maxWidth);
        return gridCard(
          context,
          child: SizedBox(
            height: row * rows,
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}
