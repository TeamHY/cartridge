import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:gpt_markdown/gpt_markdown.dart';

/// 앱 공용 마크다운 렌더러.
/// - 렌더러 교체가 필요하면 이 위젯만 수정하면 됨.
class AppMarkdown extends StatelessWidget {
  final String data;
  final EdgeInsetsGeometry padding;

  const AppMarkdown({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final dividerColor = fTheme.dividerColor;
    final gptTheme = GptMarkdownThemeData(
      brightness: fTheme.brightness,
      highlightColor: fTheme.accentColor,
      h1: fTheme.typography.title,
      h2: fTheme.typography.subtitle,
      h3: fTheme.typography.bodyLarge,
      h4: fTheme.typography.bodyStrong,
      h5: fTheme.typography.body,
      h6: fTheme.typography.caption,
      hrLineThickness: 1.0,
      hrLineColor: dividerColor,
      linkColor: fTheme.accentColor.lighter,
      linkHoverColor: fTheme.accentColor.darker,
    );

    // gpt_markdown 기본 위젯 사용.
    // NOTE: 패키지 API가 다르면 이 안만 조정하면 됨.
    return material.Material(
      color: Colors.transparent,
      child: GptMarkdownTheme(
        gptThemeData: gptTheme,
        child: Padding(
          padding: padding,
          child: GptMarkdown(
            data,
          ),
        ),
      ),
    );
  }
}
