import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

/// 테마 선택 카드 (부모의 고정 크기 200×140 박스에 맞춰 확장)
class ThemeOptionCard extends StatelessWidget {
  final AppThemeKey keyValue;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  // 미리보기 색상들
  final Color bg;       // 상단 미리보기 영역 배경
  final Color surface;  // 작은 컴포넌트 사각형 배경(보조)
  final Color text1;    // 텍스트 라인 1
  final Color text2;    // 텍스트 라인 2
  final Color? accent;  // 선택 시 테두리/하이라이트

  const ThemeOptionCard({
    super.key,
    required this.keyValue,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.bg,
    required this.surface,
    required this.text1,
    required this.text2,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final borderColor = selected
        ? (accent ?? fTheme.accentColor)
        : fTheme.dividerColor.withAlpha(140);

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // 부모가 200×140로 감싸주므로 expand
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: fTheme.resources.cardBackgroundFillColorDefault,
            borderRadius: AppShapes.card,
            border: Border.all(
              width: selected ? 2 : 1,
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 2),
                color: fTheme.shadowColor.withAlpha(24),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 미리보기
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: fTheme.dividerColor.withAlpha(80)),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      // 좌측 작은 패널(액센트 강조)
                      Container(
                        width: 46,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (accent ?? fTheme.accentColor),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: fTheme.dividerColor.withAlpha(40),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 텍스트 라인 2개(가로 바)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _line(width: 96, height: 8, color: text1),
                            const SizedBox(height: AppSpacing.xs),
                            _line(width: 64, height: 8, color: text2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 하단 라디오 + 라벨
              Row(
                children: [
                  RadioButton(
                    checked: selected,
                    onChanged: (_) => onTap(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.navigationPane,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line({required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
