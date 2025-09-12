import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

/// 상태 안내 패널
/// - 테마 토큰만 사용(색상/간격/라운드)
/// - 제목 필수, 설명/아이콘/액션 선택
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.maxWidth,
  });

  final String title;
  final String? description;
  final Widget? icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final res = fTheme.resources;

    final stroke = res.textFillColorSecondary.withAlpha(20);
    final shadow = res.textFillColorSecondary.withAlpha(40);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? AppBreakpoints.md),
        child: Container(
          decoration: BoxDecoration(
            color: fTheme.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: stroke),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              icon ??
                  Icon(
                    FluentIcons.error,
                    size: 28,
                    color: res.textFillColorSecondary,
                  ),
              Gaps.h8,
              // 제목
              Text(
                title,
                textAlign: TextAlign.center,
                style: fTheme.typography.bodyStrong?.copyWith(fontWeight: FontWeight.w600),
              ),
              // 설명(선택)
              if (description != null) ...[
                Gaps.h8,
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: fTheme.typography.body,
                ),
              ],
              // 액션(선택)
              if ((primaryLabel != null && onPrimary != null) ||
                  (secondaryLabel != null && onSecondary != null)) ...[
                Gaps.h12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (secondaryLabel != null && onSecondary != null) ...[
                      Button(onPressed: onSecondary, child: Text(secondaryLabel!)),
                      Gaps.w8,
                    ],
                    if (primaryLabel != null && onPrimary != null)
                      FilledButton(onPressed: onPrimary, child: Text(primaryLabel!)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
