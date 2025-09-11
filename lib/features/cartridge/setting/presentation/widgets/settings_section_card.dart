import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';

/// 설정 화면의 공통 섹션 카드 위젯
///
/// - [title]: 카드 상단에 표시되는 제목
/// - [description]: 선택적 설명 텍스트
/// - [child]: 카드 내부의 메인 콘텐츠
/// - [leftAligned]: 콘텐츠를 왼쪽 정렬할지 여부
/// - [maxWidth]: 카드 콘텐츠의 최대 너비
class SettingsSectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final bool leftAligned;
  final double maxWidth;

  const SettingsSectionCard({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.leftAligned = false,
    this.maxWidth = AppBreakpoints.lg + 1,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: leftAligned ? Alignment.centerLeft : Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment:
              leftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(title, style: fTheme.typography.subtitle),
                if (description != null) ...[
                  Gaps.h4,
                  Text(
                    description!,
                    style: fTheme.typography.body,
                  ),
                ],
                Gaps.h12,
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
