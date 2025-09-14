// lib/features/cartridge/record_mode/presentation/widget/layout/section_card.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

/// 한 섹션(카드)의 '행(span)'을 단일 소스로 관리.
/// - rows: 이 카드(콘텐츠)의 행 수
/// - gapBelowRows: 카드 아래 여백(=다음 카드와의 간격)을 '행' 단위로 추가
/// - rowUnit: 행 1칸 높이(토큰)
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.rows,
    required this.child,
    this.gapBelowRows = 0,
    this.rowUnit = kPanelRowUnit,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
  });

  final int rows;
  final int gapBelowRows;       // ⟵ 이제 카드 "외부" 간격으로 적용
  final double rowUnit;
  final EdgeInsetsGeometry padding;   // ⟵ 내부 패딩
  final EdgeInsetsGeometry? margin;   // ⟵ 호출측이 준 margin + gapBelowRows 가산
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    // gapBelowRows(행 단위)를 바깥 margin.bottom에 더해 외부 간격으로 처리
    final EdgeInsetsGeometry bottomGap =
    gapBelowRows > 0 ? EdgeInsets.only(bottom: gapBelowRows * rowUnit) : EdgeInsets.zero;
    final EdgeInsetsGeometry effectiveMargin = (margin == null)
        ? bottomGap
        : margin!.add(bottomGap); // EdgeInsetsGeometry.add 로 합성

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: t.resources.cardBackgroundFillColorDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: t.resources.controlStrokeColorSecondary.withAlpha(32),
          width: .8,
        ),
      ),
      // 행 높이(rows * rowUnit)는 "내부 패딩 포함" 보장
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: rows * rowUnit),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 행 높이 단위(한 곳에서만 조정하면 전체 반영)
const double kPanelRowUnit = 12;
