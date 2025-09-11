import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';

/// 섹션 컨테이너: 왼쪽 정렬 + 최대폭 고정
class SettingsSection extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget child;
  final bool leftAligned;
  final double maxWidth;

  const SettingsSection({
    super.key,
    this.title,
    this.description,
    required this.child,
    this.leftAligned = false,
    this.maxWidth = AppBreakpoints.lg + 1,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    sectionCard(Widget content) => Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        top: (title != null || description != null) ? AppSpacing.lg : 0,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: fTheme.resources.cardBackgroundFillColorDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fTheme.resources.controlStrokeColorSecondary.withAlpha(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(title!, style: AppTypography.sectionTitle),
          if (description != null) ...[
            Gaps.h4,
            Text(description!, style: AppTypography.body),
          ],
          if (title != null || description != null) ...[
            Gaps.h12,
            Divider(
              style: DividerThemeData(
                thickness: 1,
                horizontalMargin: EdgeInsets.zero,
              ),
            ),
            Gaps.h12,
          ],
          content,
        ],
      ),
    );

    // 핵심: 부모 가용폭을 받아서 min(parentWidth, maxWidth)로 정확히 고정
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : maxWidth;
        final contentW =
        parentW < maxWidth ? parentW : maxWidth; // 작으면 꽉, 크면 1000/1100

        final card = SizedBox(width: contentW, child: sectionCard(child));

        // 왼쪽 정렬 / 중앙 정렬 선택
        return Align(
          alignment: leftAligned ? Alignment.centerLeft : Alignment.topCenter,
          child: card,
        );
      },
    );
  }
}

