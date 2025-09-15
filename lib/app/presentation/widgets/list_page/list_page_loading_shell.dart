import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/theme/theme.dart';

/// 툴바 영역은 그대로 두고, 본문에 중앙 로더를 배치하는 공용 위젯.
/// - 레이아웃 변형 없이 loading 상태만 교체할 때 사용.
/// - 프로젝트 테마 토큰만 사용(고정 색상 없음).
class ListPageLoadingShell extends StatelessWidget {
  /// 상단 툴바(검색바/액션바 등). 보통 SearchToolbar 또는 그 래퍼 위젯.
  final Widget topBar;

  /// 로더 아래에 작게 보조 문구를 노출하고 싶을 때.
  final String? message;

  /// ProgressRing을 커스터마이즈 하고 싶을 때(기본값 제공).
  final Widget? spinner;

  /// 툴바 아래 간격(기본: Gaps.h12).
  final double toolbarGap;

  const ListPageLoadingShell({
    super.key,
    required this.topBar,
    this.message,
    this.spinner,
    this.toolbarGap = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    return Column(
      children: [
        topBar,
        SizedBox(height: toolbarGap),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 기본 스피너: 테마 포용(액센트 컬러)
                spinner ?? ProgressRing(activeColor: fTheme.accentColor),
                if (message != null) ...[
                  Gaps.h8,
                  Text(
                    message!,
                    style: fTheme.typography.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
