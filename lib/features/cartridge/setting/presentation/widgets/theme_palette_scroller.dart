import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';

/// 고정 크기 테마 카드(200x140) 가로 스크롤러
/// - 화면(컨테이너) 폭이 md 이상이면 2줄, 아니면 1줄
/// - 항상 보이는 스크롤바
/// - 클릭 드래그로 좌우 스크롤 가능
class ThemePaletteScroller extends StatefulWidget {
  static const double cardW = 200.0;
  static const double cardH = 140.0;

  final AppThemeKey selectedKey;
  final ValueChanged<AppThemeKey> onSelect;

  const ThemePaletteScroller({
    super.key,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  State<ThemePaletteScroller> createState() => _ThemePaletteScrollerState();
}

class _ThemePaletteScrollerState extends State<ThemePaletteScroller> {
  final _controller = ScrollController();

  // 드래그 스크롤
  void _onDragUpdate(DragUpdateDetails d) {
    if (!_controller.hasClients) return;
    final next = (_controller.offset - d.delta.dx)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.jumpTo(next);
  }

  @override
  void dispose() {
    _controller
        .dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const w = ThemePaletteScroller.cardW;
    const h = ThemePaletteScroller.cardH;
    const gap = AppSpacing.lg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;

        // 컨테이너 폭 기준 반응형: md 이상이면 2줄
        final sizeClass = sizeClassFor(maxW);
        final rows = (sizeClass == SizeClass.md ||
            sizeClass == SizeClass.lg ||
            sizeClass == SizeClass.xl) ? 2 : 1;

        // 카드 높이 + 행 간격(행-1개) + 여유
        final containerHeight = rows * h + (rows - 1) * gap + gap;

        return SizedBox(
          height: containerHeight,
          child: ScrollConfiguration(
            // 데스크톱에서 트랙패드/휠/드래그 모두 자연스럽게
            behavior: const material.ScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
              scrollbars: false,
            ),
            child: Scrollbar(
              controller: _controller,
              thumbVisibility: true, // 항상 보이게
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate, // 아무 곳이나 드래그로 좌우 스크롤
                child: GridView.builder(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rows,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap / 2,
                    // 셀 비율(카드 높이 + 간격 여유 / 카드 폭)
                    childAspectRatio: (h + gap) / w,
                  ),
                  itemCount: kThemeOrder.length,
                  itemBuilder: (_, i) {
                    final key = kThemeOrder[i];
                    final p = kThemePreviews[key]!;
                    final loc = AppLocalizations.of(context);
                    final title = localizedThemeName(loc, key);

                    // 셀 안 실제 카드는 정확히 200×140 고정
                    return Center(
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: ThemeOptionCard(
                          keyValue: key,
                          title: title,
                          selected: (widget.selectedKey == key),
                          onTap: () => widget.onSelect(key),
                          bg: p.bg,
                          surface: p.surface,
                          text1: p.text1,
                          text2: p.text2,
                          accent: p.accent,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
