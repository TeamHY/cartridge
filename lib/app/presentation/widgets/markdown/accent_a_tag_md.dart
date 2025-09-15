import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:gpt_markdown/custom_widgets/link_button.dart';

/// ATag만 색상을 Fluent accent에 맞추는 커스텀 컴포넌트.
/// 나머지 파싱 로직은 gpt_markdown의 ATagMd와 동일하게 유지.
class AccentATagMd extends ATagMd {
  @override
  InlineSpan span(
      BuildContext context,
      String text,
      final GptMarkdownConfig config,
      ) {
    // ── 기본 ATagMd의 괄호/대괄호 밸런스 파싱 그대로 ───────────────────────────────────────────────────────────
    var bracketCount = 0;
    var start = 1;
    var end = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '[') {
        bracketCount++;
      } else if (text[i] == ']') {
        bracketCount--;
        if (bracketCount == 0) {
          end = i;
          break;
        }
      }
    }
    if (text.length <= end + 1 || text[end + 1] != '(') {
      return const TextSpan();
    }
    final linkText = text.substring(start, end);
    final urlStart = end + 2;

    int parenCount = 0;
    int urlEnd = urlStart;
    for (int i = urlStart; i < text.length; i++) {
      final char = text[i];
      if (char == '(') {
        parenCount++;
      } else if (char == ')') {
        if (parenCount == 0) {
          urlEnd = i;
          break;
        } else {
          parenCount--;
        }
      }
    }
    if (urlEnd == urlStart) return const TextSpan();

    final url = text.substring(urlStart, urlEnd).trim();
    final ending = text.substring(urlEnd + 1);
    final endingSpans = MarkdownComponent.generate(
      context, ending, config, false,
    );

    // ── 여기서만 색상/호버색을 Fluent accent로 강제 ───────────────────────────────────────────────────────────
    final accent = FluentTheme.of(context).accentColor;
    final baseColor  = accent.normal;
    final hoverColor = accent.darker;

    final linkTextSpan = TextSpan(
      // 원래처럼 내부 인라인 컴포넌트(볼드 등)는 유지
      children: MarkdownComponent.generate(context, linkText, config, false),
      // 색상만 우리 테마로 교체
      style: (config.style ?? const TextStyle()).copyWith(
        color: baseColor,
        decorationColor: baseColor,
      ),
    );

    // linkBuilder를 사용하면 그걸 우선 사용 (기존 동작 유지)
    final builder = config.linkBuilder;
    WidgetSpan child;
    if (builder != null) {
      child = WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => config.onLinkTap?.call(url, linkText),
          child: builder(
            context,
            linkTextSpan,
            url,
            config.style ?? const TextStyle(),
          ),
        ),
      );
    } else {
      // 기본 렌더링: LinkButton + onLinkTap
      child = WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: LinkButton(
          color: baseColor,
          hoverColor: hoverColor,
          onPressed: () => config.onLinkTap?.call(url, linkText),
          text: linkText,
          config: config,
          child: config.getRich(linkTextSpan),
        ),
      );
    }

    return TextSpan(children: [child, ...endingSpans]);
  }
}
