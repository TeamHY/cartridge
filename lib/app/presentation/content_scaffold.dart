import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:cartridge/theme/theme.dart';

/// 통일된 컨텐츠 레이아웃 규격
class ContentLayout {
  // 페이지 가로 폭 한계(본문 최대 폭)
  static const double maxWidth = 1120;

  // 페이지 바깥 여백(네비 오른쪽 메인 영역 기준)
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(32, 16, 32, 24);

  // 헤더 내부 여백(본문과 일치)
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 12);

  // 헤더 높이(타입 2/3 기본)
  static const double headerHeight = 64;

  // 뒤로가기 버튼이 들어갈 고정 폭 슬롯(“왼쪽 여백에 독립” 느낌)
  static const double backSlotWidth = 48;

  // 헤더 하단 구분선 이후 본문 상단 여백
  static const double bodyGap = 0;
}

/// 본문 여백/폭을 통일하는 쉘
class ContentShell extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final double maxWidth;

  const ContentShell({
    super.key,
    required this.child,
    this.scrollable = true,
    this.maxWidth = ContentLayout.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final shell = Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: ContentLayout.pagePadding,
          child: child,
        ),
      ),
    );

    return scrollable ? SingleChildScrollView(child: shell) : shell;
  }
}

enum ContentHeaderKind {
  none,             // 1. 헤더 없음
  text,             // 2. 텍스트 타이틀 + 액션
  backText,         // 3. 뒤로 + 텍스트 타이틀 + 액션
  backImageText,    // 4. 뒤로 + 이미지(80) + 텍스트 타이틀 + 액션
  backCustom,       // 5. 뒤로 + 이미지(80) + 수정 가능한 텍스트 타이틀 + 액션
  backImageCustom,  // 6. 뒤로 + 이미지(80) + 수정 가능한 텍스트 타이틀 + 액션
}

/// 헤더(구분선과 본문 상단 여백까지 포함)
class ContentHeaderBar extends StatelessWidget {
  final ContentHeaderKind kind;
  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Widget? leadingEditable;
  final double maxWidth;

  const ContentHeaderBar.text({
    super.key,
    required this.title,
    this.actions = const [],
    this.maxWidth = ContentLayout.maxWidth,
  })  : kind = ContentHeaderKind.text,
        onBack = null,
        leadingEditable = null,
        titleWidget = null;

  const ContentHeaderBar.backText({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.maxWidth = ContentLayout.maxWidth,
  })  : kind = ContentHeaderKind.backText,
        leadingEditable = null,
        titleWidget = null;

  const ContentHeaderBar.backImageText({
    super.key,
    required this.title,
    required this.leadingEditable,
    this.onBack,
    this.actions = const [],
    this.maxWidth = ContentLayout.maxWidth,
  }) : kind = ContentHeaderKind.backImageText,
        titleWidget = null;

  const ContentHeaderBar.none({super.key})
      : kind = ContentHeaderKind.none,
        title = null,
        actions = const [],
        onBack = null,
        leadingEditable = null,
        maxWidth = ContentLayout.maxWidth,
        titleWidget = null;

  const ContentHeaderBar.backCustom({
    super.key,
    required this.titleWidget,
    this.onBack,
    this.actions = const [],
    this.maxWidth = ContentLayout.maxWidth,
  })  : kind = ContentHeaderKind.backText,
        title = null,
        leadingEditable = null;

  const ContentHeaderBar.backImageCustom({
    super.key,
    required this.titleWidget,
    required this.leadingEditable,
    this.onBack,
    this.actions = const [],
    this.maxWidth = ContentLayout.maxWidth,
  }) : kind = ContentHeaderKind.backImageText,
        title = null;

  const ContentHeaderBar.textCustom({
    super.key,
    required this.titleWidget,
    this.actions = const [],
    this.maxWidth = ContentLayout.maxWidth,
  })  : kind = ContentHeaderKind.text,
        title = null,
        onBack = null,
        leadingEditable = null;

  @override
  Widget build(BuildContext context) {
    if (kind == ContentHeaderKind.none) {
      // 1) 헤더 없이 본문만: 아무것도 렌더하지 않음 (본문은 ContentShell가 처리)
      return const SizedBox.shrink();
    }

    final fTheme = FluentTheme.of(context);

    // 헤더 본체
    final headerRow = SizedBox(
      height: kind == ContentHeaderKind.backImageText ? 96 : ContentLayout.headerHeight,
      child: Stack(
        children: [
          // 뒤로가기 버튼: “왼쪽 외곽 여백 슬롯”에 독립적으로 고정
          if (kind == ContentHeaderKind.backText || kind == ContentHeaderKind.backImageText)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: ContentLayout.headerPadding.left - 6),
                  child: IconButton(
                    icon: const Icon(material.Icons.arrow_back, size: 24),
                    onPressed: onBack,
                  ),
                ),
              ),
            ),

          // 컨텐츠(제목/이미지/액션)는 본문과 같은 최대 폭/여백에 맞춤
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.only(
                  left: (kind == ContentHeaderKind.backText || kind == ContentHeaderKind.backImageText)
                      ? ContentLayout.headerPadding.left + ContentLayout.backSlotWidth
                      : ContentLayout.headerPadding.left,
                  right: ContentLayout.headerPadding.right,
                  top: ContentLayout.headerPadding.top,
                  bottom: ContentLayout.headerPadding.bottom,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (kind == ContentHeaderKind.backImageText) ...[
                      ClipRRect(
                        borderRadius: AppShapes.card,
                        child: SizedBox(width: 80, height: 80, child: leadingEditable),
                      ),
                      Gaps.w12,
                    ],
                    Expanded(
                      child: titleWidget ??
                          Text(
                            title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: AppTypography.appBarTitle,
                          ),
                    ),
                    Gaps.w12,
                    Row(children: actions),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final divider = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: ContentLayout.headerPadding.left),
          child: Divider(
            style: DividerThemeData(
              thickness: 1,
              horizontalMargin: EdgeInsets.zero,
              decoration: BoxDecoration(color: fTheme.resources.dividerStrokeColorDefault),
            ),
          ),
        ),
      ),
    );

    const gap = SizedBox(height: ContentLayout.bodyGap);
    return Column(children: [headerRow, divider, gap]);
  }
}
