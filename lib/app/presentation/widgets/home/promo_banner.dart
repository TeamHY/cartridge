import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'package:cartridge/app/presentation/widgets/home/home_card.dart';
import 'package:cartridge/core/constants/urls.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final items = <SpanItem>[
      // intro = 3 cols
      SpanItem(span: 3, child: const _PromoIntro()),
      // buttons = 1 col
      ..._linkTiles(loc).map((w) => SpanItem(span: 1, child: w)),
    ];

    return HomeCard(
      child: ResponsiveSpanGrid(
        items: items,
        minCols: 2,
        maxCols: 6,
        minCellWidth: 120,
        gutter: AppSpacing.sm,
        rowSpacing: AppSpacing.sm,
        tileHeight: 120,
      ),
    );
  }

  List<Widget> _linkTiles(AppLocalizations loc) => [
    _LinkTile(
      label: loc.promo_link_youtube,
      urlGetter: () => AppUrls.youtube,
      imagePath: 'assets/images/promo/youtube.png',
    ),
    _LinkTile(
      label: loc.promo_link_chzzk,
      urlGetter: () => AppUrls.chzzk,
      imagePath: 'assets/images/promo/chzzk.png',
    ),
    _LinkTile(
      label: loc.promo_link_soop,
      urlGetter: () => AppUrls.afreeca,
      imagePath: 'assets/images/promo/soop.png',
    ),
    _LinkTile(
      label: loc.promo_link_twitch,
      urlGetter: () => AppUrls.twitch,
      imagePath: 'assets/images/promo/twitch.png',
    ),
    _LinkTile(
      label: loc.promo_link_discord,
      urlGetter: () => AppUrls.discord,
      imagePath: 'assets/images/promo/discord.png',
    ),
    _LinkTile(
      label: loc.promo_link_kakao_openchat,
      urlGetter: () => AppUrls.openChat,
      imagePath: 'assets/images/promo/kakaoTalk.png',
    ),
    _LinkTile(
      label: loc.promo_link_naver_cafe,
      urlGetter: () => AppUrls.naverCafeHome,
      imagePath: 'assets/images/promo/naver.png',
    ),
    _LinkTile(
      label: loc.promo_link_donate_playsquad,
      urlGetter: () => AppUrls.donationPlaysquad,
      imagePath: 'assets/images/promo/playsquad.png',
    ),
    _LinkTile(
      label: loc.promo_link_donate_toonation,
      urlGetter: () => AppUrls.donation,
      imagePath: 'assets/images/promo/toonation.png',
    ),
  ];
}

/// 스팬 그리드 아이템
class SpanItem {
  final int span;
  final Widget child;
  const SpanItem({required this.span, required this.child});
}

/// 부트스트랩 span 레이아웃
class ResponsiveSpanGrid extends StatelessWidget {
  final List<SpanItem> items;
  final int minCols;
  final int maxCols;
  final double minCellWidth;
  final double gutter;
  final double rowSpacing;
  final double tileHeight;

  const ResponsiveSpanGrid({
    super.key,
    required this.items,
    required this.minCols,
    required this.maxCols,
    required this.minCellWidth,
    required this.gutter,
    required this.rowSpacing,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = _calcCols(constraints.maxWidth);
        final cellWidth = _cellWidth(constraints.maxWidth, cols);
        final rows = _pack(items, cols);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              _RowLine(
                row: rows[r],
                cols: cols,
                gutter: gutter,
                cellWidth: cellWidth,
                tileHeight: tileHeight,
              ),
              if (r != rows.length - 1) SizedBox(height: rowSpacing),
            ]
          ],
        );
      },
    );
  }

  int _calcCols(double maxWidth) {
    final approx = ((maxWidth + gutter) / (minCellWidth + gutter)).floor();
    return approx.clamp(minCols, maxCols);
  }

  double _cellWidth(double maxWidth, int cols) {
    final totalGutter = gutter * (cols - 1);
    return (maxWidth - totalGutter) / cols;
  }

  // first-fit 줄 포장
  List<List<SpanItem>> _pack(List<SpanItem> items, int cols) {
    final rows = <List<SpanItem>>[];
    var current = <SpanItem>[];
    var used = 0;

    for (final it in items) {
      final span = it.span.clamp(1, cols);
      if (used + span > cols) {
        if (current.isNotEmpty) rows.add(current);
        current = <SpanItem>[SpanItem(span: span, child: it.child)];
        used = span;
      } else {
        current.add(SpanItem(span: span, child: it.child));
        used += span;
      }
    }
    if (current.isNotEmpty) rows.add(current);
    return rows;
  }
}

class _RowLine extends StatelessWidget {
  final List<SpanItem> row;
  final int cols;
  final double gutter;
  final double cellWidth;
  final double tileHeight;

  const _RowLine({
    required this.row,
    required this.cols,
    required this.gutter,
    required this.cellWidth,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < row.length; i++) {
      final it = row[i];
      final width = cellWidth * it.span + gutter * (it.span - 1);
      children.add(SizedBox(
        width: width,
        height: tileHeight,
        child: it.child,
      ));
      if (i != row.length - 1) {
        children.add(SizedBox(width: gutter));
      }
    }
    return Row(children: children);
  }
}

class _PromoIntro extends StatelessWidget {
  const _PromoIntro();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final accent = theme.accentColor.normal;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // 브랜드 아이콘(loadin/에러에도 고정 크기)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withAlpha(theme.brightness == Brightness.dark ? 48 : 28),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: Image.asset(
                'assets/images/오헌영_아이콘.gif',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                cacheWidth: (64 * View.of(context).devicePixelRatio).round(),
                cacheHeight: (64 * View.of(context).devicePixelRatio).round(),
                errorBuilder: (_, __, ___) => Text(
                  loc.promo_intro_fallback_initials,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ),
          ),
          Gaps.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.promo_intro_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Gaps.h6,
                Text(
                  loc.promo_intro_desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 정사각형 링크 타일(아이콘 + 라벨)
class _LinkTile extends StatelessWidget {
  final String label;
  final String Function() urlGetter;
  final String imagePath;
  final double _imageSize = 64.0;

  const _LinkTile({
    required this.label,
    required this.urlGetter,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: HoverButton(
        onPressed: () => _openUrl(urlGetter()),
        builder: (context, states) {
          final hovered = states.isHovered;
          final pressed = states.isPressed;

          // 기본 배경
          final base = fTheme.cardColor;
          final overlay = _tileOverlay(
            brightness: fTheme.brightness,
            hovered: hovered,
            pressed: pressed,
          );
          final bg = Color.alphaBlend(overlay, base);

          // hover 시 테두리도 살짝 강조
          final borderColor = hovered
              ? fTheme.resources.controlStrokeColorSecondary
              : fTheme.resources.controlStrokeColorDefault;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor),
              boxShadow: hovered
                  ? [
                BoxShadow(
                  color: fTheme.shadowColor.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘(이미지 실패해도 고정 크기)
                SizedBox(
                  width: _imageSize,
                  height: _imageSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.asset(
                      imagePath,
                      width: _imageSize,
                      height: _imageSize,
                      fit: BoxFit.contain,
                      cacheWidth: (_imageSize * View.of(context).devicePixelRatio).round(),
                      cacheHeight: (_imageSize * View.of(context).devicePixelRatio).round(),
                      errorBuilder: (_, __, ___) => Container(
                        color: fTheme.resources.subtleFillColorSecondary,
                        alignment: Alignment.center,
                        child: Icon(FluentIcons.link, color: fTheme.inactiveColor, size: 20),
                      ),
                    ),
                  ),
                ),
                Gaps.h4,
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.navigationPane,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openUrl(String url) {
    // 레이아웃 유지 목적: 실패해도 UI 변화 없음(토스트 등은 별도)
    ul.launchUrl(Uri.parse(url));
  }
}
Color _tileOverlay({
  required Brightness brightness,
  required bool hovered,
  required bool pressed,
}) {
  if (pressed) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(48)   // 다크: 더 밝게
        : Colors.black.withAlpha(36);  // 라이트: 더 어둡게
  }
  if (hovered) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(28)
        : Colors.black.withAlpha(18);
  }
  return Colors.transparent;
}