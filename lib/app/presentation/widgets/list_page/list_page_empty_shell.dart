import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:cartridge/theme/theme.dart';

/// 툴바 영역은 유지하고 본문에 빈 상태 뷰를 중앙 배치하는 공용 위젯.
/// - 레이아웃 변형 없이 "빈 목록" 상태만 교체할 때 사용.
/// - 기본은 404 스타일의 EmptyState 템플릿을 사용하되, 필요 시 child로 커스텀 가능.
class ListPageEmptyShell extends StatelessWidget {
  final Widget topBar;

  /// 툴바 아래 간격(기본: AppSpacing.md).
  final double toolbarGap;

  /// 중앙에 표출할 컨텐츠(커스텀). with404 팩토리 생성자를 쓰면 자동으로 404 템플릿이 들어갑니다.
  final Widget child;

  const ListPageEmptyShell({
    super.key,
    required this.topBar,
    required this.child,
    this.toolbarGap = AppSpacing.md,
  });

  /// 404 스타일 템플릿(타이틀 + 기본 CTA)로 간편 생성
  factory ListPageEmptyShell.with404({
    Key? key,
    required Widget topBar,
    double toolbarGap = AppSpacing.md,
    required String title,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    return ListPageEmptyShell(
      key: key,
      topBar: topBar,
      toolbarGap: toolbarGap,
      child: EmptyState.withDefault404(
        title: title,
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        topBar,
        SizedBox(height: toolbarGap),
        Expanded(
          child: Center(child: child),
        ),
      ],
    );
  }
}
