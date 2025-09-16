import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// ![200x140 alt](assets/xxx.png)
/// ![200x140 alt](/assets/xxx.png)
/// ![200x140 alt](asset:assets/xxx.png)
/// ![alt](https://example.com/xxx.png)
class AssetOrNetworkImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r"!\[[^\[\]]*\]\(\S*\)");

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    // 1) ![alt]( ... ) 파싱
    final basicMatch = RegExp(r'!\[([^\[\]]*)\]\(').firstMatch(text.trim());
    if (basicMatch == null) return const TextSpan();

    final altText = basicMatch.group(1) ?? '';
    final urlStart = basicMatch.end;

    // 괄호 균형 맞춰서 진짜 URL 끝 찾기
    int parenCount = 0;
    int urlEnd = urlStart;
    for (int i = urlStart; i < text.length; i++) {
      final ch = text[i];
      if (ch == '(') {
        parenCount++;
      } else if (ch == ')') {
        if (parenCount == 0) { urlEnd = i; break; }
        parenCount--;
      }
    }
    if (urlEnd == urlStart) return const TextSpan();

    final rawUrl = text.substring(urlStart, urlEnd).trim();

    // 2) alt의 "200x140 ..." 사이즈 파싱 (선택적)
    double? width, height;
    if (altText.isNotEmpty) {
      final m = RegExp(r'^([0-9]+)?x?([0-9]+)?').firstMatch(altText.trim());
      width  = double.tryParse(m?[1] ?? '');
      height = double.tryParse(m?[2] ?? '');
    }

    // 3) 자산/네트워크 분기
    final Widget child = _buildImage(rawUrl, width: width, height: height);

    return WidgetSpan(
      alignment: PlaceholderAlignment.bottom,
      child: child,
    );
  }

  Widget _buildImage(String rawUrl, {double? width, double? height}) {
    SizedBox box(Widget img) => SizedBox(width: width, height: height, child: img);

    // asset: 스킴
    if (rawUrl.startsWith('asset:')) {
      final path = rawUrl.substring('asset:'.length).replaceFirst(RegExp(r'^/'), '');
      return box(Image.asset(path, fit: BoxFit.contain));
    }

    // 스킴 없는 상대경로 → assets/… 로 간주
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*:').hasMatch(rawUrl);
    if (!hasScheme) {
      // /assets/... 또는 assets/...
      final path = rawUrl.replaceFirst(RegExp(r'^/'), '');
      if (path.startsWith('assets/')) {
        return box(Image.asset(path, fit: BoxFit.contain));
      }
    }

    // data: URI (옵션)
    if (rawUrl.startsWith('data:image')) {
      try {
        final data = Uri.parse(rawUrl).data;
        if (data != null) {
          final bytes = data.contentAsBytes();
          return box(Image.memory(bytes, fit: BoxFit.contain));
        }
      } catch (_) {/*네트워크로 폴백*/}
    }

    // 기본: 네트워크
    return box(Image.network(
      rawUrl,
      fit: BoxFit.contain,
      // 로딩/에러 표시 간단 처리 (원한다면 앱 스타일로 교체)
      loadingBuilder: (ctx, child, ev) {
        if (ev == null) return child;
        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
      },
      errorBuilder: (ctx, err, st) => const SizedBox(
        child: Center(child: Icon(FluentIcons.photo_error)),
      ),
    ));
  }
}
