import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';

class ReorderGrid<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) idOf;

  /// 정렬 모드 여부
  final bool inReorder;

  /// Grid 레이아웃
  final int crossAxisCount;
  final double spacing;
  final double mainAxisExtent;

  /// 스크롤 (일반/정렬 모드)
  final ScrollController normalScrollController;
  final ScrollController editScrollController;

  /// 카드 빌더 (일반/정렬모드용)
  final Widget Function(T item) normalItemBuilder;
  final Widget Function(T item) reorderItemBuilder;

  /// 드래그 결과 콜백: 새 ID 순서
  final void Function(List<String> newOrderIds) onReorder;

  /// (선택) 마우스 hover 중에 호출해서 idle 타이머를 갱신
  final VoidCallback? onHoverDuringReorder;

  const ReorderGrid({
    super.key,
    required this.items,
    required this.idOf,
    required this.inReorder,
    required this.crossAxisCount,
    required this.spacing,
    required this.mainAxisExtent,
    required this.normalScrollController,
    required this.editScrollController,
    required this.normalItemBuilder,
    required this.reorderItemBuilder,
    required this.onReorder,
    this.onHoverDuringReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (inReorder) {
      final children = [
        for (final v in items)
          RepaintBoundary(
            key: ValueKey(idOf(v)),
            child: SizedBox(
              width: double.infinity,
              child: reorderItemBuilder(v),
            ),
          ),
      ];

      return ReorderableBuilder<_KeyWrap>(
        scrollController: editScrollController,
        enableLongPress: false,
        onReorder: (reorderFn) {
          final before = items.map((e) => _KeyWrap(id: idOf(e))).toList();
          final after = reorderFn(before).cast<_KeyWrap>().map((e) => e.id).toList();
          onReorder(after);
        },
        builder: (reorderedChildren) {
          return MouseRegion(
            onHover: (_) => onHoverDuringReorder?.call(),
            child: RepaintBoundary(
              child: GridView(
                controller: editScrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: mainAxisExtent,
                ),
                children: reorderedChildren,
              ),
            ),
          );
        },
        children: children,
      );
    }

    return GridView.builder(
      controller: normalScrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => normalItemBuilder(items[i]),
    );
  }
}

class _KeyWrap {
  final String id;
  _KeyWrap({required this.id});
}
