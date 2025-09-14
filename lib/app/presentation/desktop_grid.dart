import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

/// 한 칸짜리 일반 아이템 또는 행 전체를 차지하는 아이템
class GridItem {
  final Widget child;
  final bool fullRow;
  const GridItem({required this.child, this.fullRow = false});
  const GridItem.full({required this.child}) : fullRow = true;
}

/// 데스크톱 그리드:
/// - 좌측 정렬, 일정한 카드 폭
/// - 토큰 기반(Spacing/Breakpoints), full-row 지원
/// - 브레이크포인트 기준: 컨테이너 폭(기본) 또는 뷰포트 폭(옵션)
class DesktopGrid extends StatelessWidget {
  /// full-row를 포함할 수 있는 아이템 목록
  final List<GridItem> items;

  /// 최대 콘텐츠 폭(컨테이너 클램프). 기본은 XL 브레이크포인트.
  final double maxContentWidth;

  /// 반응형 컬럼 수: xl/lg/md/sm/xs
  final int colsLg;
  final int colsMd;
  final int colsSm;
  final int colsXs;

  /// 아이템 간 가로/세로 간격(AppSpacing 토큰 사용 권장)
  final double gapX;
  final double gapY;

  /// true면 화면 폭(context.sizeClass)으로, false면 컨테이너 폭으로 컬럼 계산
  final bool useViewportForBreakpoints;

  /// 각 행의 crossAxis 정렬
  final CrossAxisAlignment rowCrossAxisAlignment;

  const DesktopGrid({
    super.key,
    required this.items,
    this.maxContentWidth = AppBreakpoints.xl,
    this.colsLg = 3,
    this.colsMd = 2,
    this.colsSm = 1,
    this.colsXs = 1,
    this.gapX = AppSpacing.lg,
    this.gapY = AppSpacing.md,
    this.useViewportForBreakpoints = false,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 가용 폭: 컨테이너 폭을 XL 토큰으로 클램프
        final available = constraints.maxWidth.clamp(0.0, maxContentWidth);

        // 브레이크포인트 기준 선택
        final SizeClass bpClass = useViewportForBreakpoints
            ? context.sizeClass
            : sizeClassFor(available);

        // 의미 기반 컬럼 매핑 (xs 포함)
        final int cols = switch (bpClass) {
          SizeClass.xl || SizeClass.lg  => colsLg,
          SizeClass.md                  => colsMd,
          SizeClass.sm                  => colsSm,
          SizeClass.xs || SizeClass.xxs => colsXs,
        };

        final usable = available - gapX * (cols - 1);
        final perItem = (cols <= 1) ? available : (usable / cols);

        final rows = _packRows(items, cols);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: available),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                _GridRow(
                  row: rows[r],
                  available: available,
                  perItem: perItem,
                  gapX: gapX,
                  crossAxisAlignment: rowCrossAxisAlignment,
                ),
                if (r != rows.length - 1) SizedBox(height: gapY),
              ],
            ],
          ),
        );
      },
    );
  }

  /// first-fit 패킹: full-row는 단독 행, 일반 아이템은 최대 cols개까지 한 행에 배치
  List<List<GridItem>> _packRows(List<GridItem> items, int cols) {
    final out = <List<GridItem>>[];
    var row = <GridItem>[];
    var used = 0;

    for (final it in items) {
      if (it.fullRow) {
        if (row.isNotEmpty) out.add(row);
        out.add([it]); // 단독 행
        row = <GridItem>[];
        used = 0;
        continue;
      }
      row.add(it);
      used += 1;
      if (used >= cols) {
        out.add(row);
        row = <GridItem>[];
        used = 0;
      }
    }
    if (row.isNotEmpty) out.add(row);
    return out;
  }
}

class _GridRow extends StatelessWidget {
  final List<GridItem> row;
  final double available;
  final double perItem;
  final double gapX;
  final CrossAxisAlignment crossAxisAlignment;

  const _GridRow({
    required this.row,
    required this.available,
    required this.perItem,
    required this.gapX,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    // full-row 단독 아이템: 가용 폭 전체 사용
    if (row.length == 1 && row.first.fullRow) {
      return SizedBox(
        key: const ValueKey('dg.fullRow'),
        width: available,
        child: row.first.child,
      );
    }

    // 일반 행: 아이템 폭 고정(perItem), 좌측 정렬, 아이템 간 gapX
    return Row(
      key: const ValueKey('dg.row'),
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < row.length; i++) ...[
          SizedBox(width: perItem, child: row[i].child),
          if (i != row.length - 1) SizedBox(width: gapX),
        ],
      ],
    );
  }
}
