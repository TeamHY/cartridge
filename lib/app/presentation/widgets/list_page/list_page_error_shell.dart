import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

/// 리스트/그리드 페이지용 에러 셸.
/// - 툴바는 그대로 유지하고, 본문 중앙에 에러 카드를 배치합니다.
/// - 에러 코드는 노출하지 않고 간단한 문구 + 액션만 제공합니다.
/// - 프로젝트 테마 토큰만 사용
class ListPageErrorShell extends StatelessWidget {
  /// 상단 툴바(검색바/액션바 등). 보통 SearchToolbar 또는 그 래퍼 위젯.
  final Widget topBar;

  /// 에러 제목(짧고 핵심적으로).
  final String title;

  /// 에러 설명(선택).
  final String? description;

  /// 기본 액션 라벨(예: “다시 시도”). onPrimary가 null이면 버튼 미표시.
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  /// 보조 액션 라벨(예: “닫기”). onSecondary가 null이면 버튼 미표시.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// 아이콘을 커스터마이즈하고 싶을 때. (미지정 시 기본 에러 아이콘)
  final Widget? icon;

  /// 툴바 아래 간격(기본: Gaps.h12와 동일).
  final double toolbarGap;

  /// 카드의 최대 폭(기본: 440).
  final double maxCardWidth;

  const ListPageErrorShell({
    super.key,
    required this.topBar,
    required this.title,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon,
    this.toolbarGap = AppSpacing.md,
    this.maxCardWidth = 440,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final stroke = fTheme.resources.controlStrokeColorDefault;
    final shadow = fTheme.shadowColor.withAlpha(28);

    return Column(
      children: [
        topBar,
        SizedBox(height: toolbarGap),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardWidth),
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
                          color: fTheme.resources.textFillColorSecondary,
                        ),
                    Gaps.h8,
                    // 제목
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: fTheme.typography.bodyStrong?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                            Button(
                              onPressed: onSecondary,
                              child: Text(secondaryLabel!),
                            ),
                            Gaps.w8,
                          ],
                          if (primaryLabel != null && onPrimary != null)
                            FilledButton(
                              onPressed: onPrimary,
                              child: Text(primaryLabel!),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
