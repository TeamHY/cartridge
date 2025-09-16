// lib/app/presentation/widgets/app_markdown.dart
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'accent_a_tag_md.dart';
import 'asset_image_md.dart';

/// 앱 공용 마크다운 렌더러.
///
/// 업스트림(gpt_markdown)의 A 태그 색상 적용 이슈로 인해, 링크 색상을
/// Fluent accent로 강제하기 위한 **임시 워크어라운드**가 들어가 있다.
/// (ATagMd가 테마의 linkColor를 정상 반영하지 않는 문제)
///
/// Styles on links #78
/// https://github.com/Infinitix-LLC/gpt_markdown/issues/78
/// ─────────────────────────────────────────────────────────────────────────────
/// ⚠️ 유지보수 메모 (업스트림 수정되면 제거하세요)
/// 1) gpt_markdown에서 ATag(링크)가 theme.linkColor / linkHoverColor를
///    정상 반영하도록 수정되면:
///    - 아래 inlineComponents 교체 로직(ATagMd → AccentATagMd)을 삭제
///    - accent_a_tag_md.dart 파일도 삭제
/// 2) 코드 블록은 AppCodeBlock을 통해 폰트만 커스텀하므로 계속 유지해도 무방.
/// ─────────────────────────────────────────────────────────────────────────────
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
    final f = FluentTheme.of(context);

    final gptTheme = GptMarkdownThemeData(
      brightness: f.brightness,
      highlightColor: f.accentColor,
      h1: f.typography.title,
      h2: f.typography.subtitle,
      h3: f.typography.bodyLarge,
      h4: f.typography.bodyStrong,
      h5: f.typography.body,
      h6: f.typography.caption,
      hrLineThickness: 1.0,
      hrLineColor: f.dividerColor,
      linkColor: f.accentColor.lighter,   // (패키지 이슈로 실제 반영 안될 수 있음)
      linkHoverColor: f.accentColor.darker,
    );

    // ── 링크 색상 이슈(#78) 워크어라운드: ATag만 교체 ───────────────────────────────────────────────────────────
    final inline = List<MarkdownComponent>.from(MarkdownComponent.inlineComponents);
    final idx = inline.indexWhere((c) => c is ATagMd);
    if (idx >= 0) inline[idx] = AccentATagMd();

    final idxImg = inline.indexWhere((c) => c is ImageMd);
    if (idxImg >= 0) inline[idxImg] = AssetOrNetworkImageMd();

    return material.Material(
      color: Colors.transparent,
      child: GptMarkdownTheme(
        gptThemeData: gptTheme,
        child: Padding(
          padding: padding,
          child: GptMarkdown(
            data,
            followLinkColor: true,
            onLinkTap: (url, _) async {
              if (url.isEmpty) return;
              await launchUrlString(url, mode: LaunchMode.externalApplication);
            },
            inlineComponents: inline,

            codeBuilder: (ctx, name, code, closed) {
              return material.Material(
                color: f.micaBackgroundColor.withAlpha(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    code,
                    style: AppTypography.code.copyWith(
                      fontFamily: AppTypography.fontMono,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },

            highlightBuilder: (ctx, text, base) {
              final bg = f.resources.cardBackgroundFillColorSecondary;
              final stroke = f.resources.controlStrokeColorSecondary.withAlpha(32);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: stroke, width: .8),
                ),
                child: Text(
                  text,
                  style: (base).copyWith(
                    fontFamily: AppTypography.fontMono,
                    fontSize: (base.fontSize ?? 14) * 0.95,
                    height: base.height ?? 1.35,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
