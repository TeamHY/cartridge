import 'package:cartridge/theme/tokens/spacing.dart';
import 'package:cartridge/theme/tokens/typography.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// 홈 화면 전용 카드 컨테이너.
/// - SettingsSection 의 시각 디자인(배경/테두리/헤더)을 카드 자체로 가져옴.
/// - title/trailing 있으면 헤더 + Divider 를 자동 출력.
class HomeCard extends StatelessWidget {
  final String? title;
  final Widget? trailing; // 헤더 우측 액션 버튼 등
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HomeCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: fTheme.resources.cardBackgroundFillColorDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fTheme.resources.controlStrokeColorSecondary.withAlpha(32),
        ),
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || trailing != null) ...[
            Row(
              children: [
                if (title != null)
                  Expanded(child: Text(title!, style: AppTypography.sectionTitle)),
                if (trailing != null) trailing!,
              ],
            ),
            Gaps.h8,
            Divider(
              style: DividerThemeData(
                horizontalMargin: EdgeInsets.zero,
                thickness: 1,
              ),
            ),
            Gaps.h8,
          ],
          child,
        ],
      ),
    );
  }
}

