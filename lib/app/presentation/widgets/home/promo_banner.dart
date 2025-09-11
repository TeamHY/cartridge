import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'package:cartridge/app/presentation/widgets/home/home_card.dart';
import 'package:cartridge/core/constants/urls.dart';
import 'package:cartridge/theme/theme.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <SpanItem>[
      // intro = 3 cols
      SpanItem(span: 3, child: const _PromoIntro()),
      // buttons = 1 col
      ..._getLinkTiles().map((w) => SpanItem(span: 1, child: w)),
    ];

    return HomeCard(
      child: ResponsiveSpanGrid(
        items: items,
        // 원하는 느낌으로 조정 (예: 넓을 때 6, 조금 좁을 때 4)
        minCols: 2,
        maxCols: 6,
        minCellWidth: 120, // 1칸 최소 너비, 상황에 맞게 조정
        gutter: 12,
        rowSpacing: 12,
        tileHeight: 120, // 버튼/인트로 높이 통일
      ),
    );
  }

  List<Widget> _getLinkTiles() {
    return [
      _LinkTile(
        label: 'YouTube',
        urlGetter: () => AppUrls.youtube,
        imagePath: 'assets/images/promo/youtube.png',
      ),
      _LinkTile(
        label: 'Chzzk',
        urlGetter: () => AppUrls.chzzk,
        imagePath: 'assets/images/promo/chzzk.png',
      ),
      _LinkTile(
        label: 'Soop',
        urlGetter: () => AppUrls.afreeca,
        imagePath: 'assets/images/promo/soop.png',
      ),
      _LinkTile(
        label: 'Twitch',
        urlGetter: () => AppUrls.twitch,
        imagePath: 'assets/images/promo/twitch.png',
      ),
      _LinkTile(
        label: 'Discord',
        urlGetter: () => AppUrls.discord,
        imagePath: 'assets/images/promo/discord.png',
      ),
      _LinkTile(
        label: 'Kakao OpenChat',
        urlGetter: () => AppUrls.openChat,
        imagePath: 'assets/images/promo/kakaoTalk.png',
      ),
      _LinkTile(
        label: 'Naver Cafe',
        urlGetter: () => AppUrls.naverCafeHome,
        imagePath: 'assets/images/promo/naver.png',
      ),
      _LinkTile(
        label: 'Donate (Playsquad)',
        urlGetter: () => AppUrls.donationPlaysquad,
        imagePath: 'assets/images/promo/playsquad.png',
      ),
      _LinkTile(
        label: 'Donate (Toonation)',
        urlGetter: () => AppUrls.donation,
        imagePath: 'assets/images/promo/toonation.png',
      ),
    ];
  }
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
    // 한 칸 최소 너비 + gutter를 기준으로 대략적인 cols 산출
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
    final accent = theme.accentColor.normal;

    return Container(
      width: double.infinity,
      height: double.infinity, // 부모(SizedBox)가 높이 관리
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (theme.dividerTheme.decoration as BoxDecoration?)?.color ?? const Color(0x14000000),
        ),
      ),
      child: Row(
        children: [
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
                errorBuilder: (_, __, ___) => const Text(
                  'OH',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ),
          ),
          Gaps.w16,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '아이작 오헌영 • 커뮤니티 & 후원',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Gaps.h6,
                Text('아이작 플레이어들과 함께 만드는 공간! 방송, 커뮤니티, 공략, 그리고 다양한 이벤트 소식들을 만나보세요.'),
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

  const _LinkTile({
    required this.label,
    required this.urlGetter,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final dividerColor =
        (fTheme.dividerTheme.decoration as BoxDecoration?)?.color ?? const Color(0x14000000);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: HoverButton(
        onPressed: () => _openUrl(urlGetter()),
        builder: (context, states) {
          final hovered = states.isHovered;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity, // 폭은 부모(SizedBox)가 결정
            height: double.infinity, // 부모(SizedBox)가 높이 결정(=tileHeight)
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
              boxShadow: hovered
                  ? [
                BoxShadow(
                  color: fTheme.shadowColor.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePath,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      cacheWidth: (64 * View.of(context).devicePixelRatio).round(),
                      cacheHeight: (64 * View.of(context).devicePixelRatio).round(),
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
    ul.launchUrl(Uri.parse(url));
  }
}
