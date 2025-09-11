import 'dart:io';
import 'dart:ui' show PointerDeviceKind;
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'package:cartridge/features/steam_news/steam_news.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/app/presentation/widgets/home/home_card.dart';
import 'package:cartridge/theme/theme.dart';

const _newsViewportHeight = 200.0;
const _newsCardWidth = 240.0;
const _newsThumbHeight = 115.0;

class SteamNewsSection extends ConsumerWidget {
  const SteamNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final newsAsync = ref.watch(steamNewsCardsProvider);

    return HomeCard(
      title: loc.news_section_title,
      trailing: HyperlinkButton(
        child: Text(loc.news_see_more),
        onPressed: () => ul.launchUrl(
          Uri.parse('https://store.steampowered.com/news/app/250900'),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SizedBox(
        height: _newsViewportHeight,
        child: newsAsync.when(
          loading: () => _NewsStrip.fixed(
            children: const [
              _NewsSkeletonCard(),
              _NewsSkeletonCard(),
              _NewsSkeletonCard(),
            ],
          ),
          // 에러: 심플 메시지 + 새로고침
          error: (_, __) => _NewsStrip.fixed(
            children: [
              _NewsMessageCard.icon(
                icon: FluentIcons.sync_error,
                title: loc.news_error_title,
                actionLabel: loc.common_refresh,
                onPressed: () => ref.invalidate(steamNewsCardsProvider),
              ),
            ],
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return _NewsStrip.fixed(
                children: [
                  _NewsMessageCard.icon(
                    icon: FluentIcons.news,
                    title: loc.news_empty_title,
                    actionLabel: loc.common_refresh,
                    onPressed: () => ref.invalidate(steamNewsCardsProvider),
                  ),
                ],
              );
            }
            return _NewsStrip.builder(
              itemCount: cards.length,
              itemBuilder: (context, i) => _NewsCard(item: cards[i]),
            );
          },
        ),
      ),
    );
  }
}

/// 공통: 가로 스트립(에지 페이드 + 스크롤바 + 동일 padding/spacing)
class _NewsStrip extends StatefulWidget {
  final List<Widget>? fixedChildren;
  final int? itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;

  const _NewsStrip._({this.fixedChildren, this.itemCount, this.itemBuilder});

  factory _NewsStrip.fixed({required List<Widget> children}) =>
      _NewsStrip._(fixedChildren: children);

  factory _NewsStrip.builder({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) => _NewsStrip._(itemCount: itemCount, itemBuilder: itemBuilder);

  @override
  State<_NewsStrip> createState() => _NewsStripState();
}

class _NewsStripState extends State<_NewsStrip> {
  late final ScrollController _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = (widget.fixedChildren != null)
        ? ListView.separated(
      key: const PageStorageKey('steam_news_list'),
      primary: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 4),
      itemCount: widget.fixedChildren!.length,
      separatorBuilder: (_, __) => Gaps.w12,
      itemBuilder: (_, i) => widget.fixedChildren![i],
    )
        : ListView.separated(
      primary: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 4),
      itemCount: widget.itemCount!,
      separatorBuilder: (_, __) => Gaps.w12,
      itemBuilder: widget.itemBuilder!,
    );

    return _EdgeFadedHScroll(
      controller: _ctrl,
      fadeWidth: 16,
      child: ScrollConfiguration(
        behavior: const _MouseDragScrollBehavior(),
        child: PrimaryScrollController(
          controller: _ctrl,
          child: Scrollbar(
            interactive: true,
            child: list,
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends ConsumerWidget {
  final SteamNewsCardVM item;
  const _NewsCard({required this.item});

  String _dateLabel(DateTime? d) {
    if (d == null) return '';
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y.$m.$day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);

    final previewAsync = ref.watch(webPreviewProvider(item.item.url));
    final preview = previewAsync.maybeWhen(data: (p) => p, orElse: () => null);

    final liveThumbPath = preview?.imagePath ?? item.thumbPath;
    final liveTitle = (preview?.title.isNotEmpty ?? false)
        ? preview!.title
        : item.item.title;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 썸네일
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            width: _newsCardWidth,
            height: _newsThumbHeight,
            child: (liveThumbPath ?? '').isNotEmpty
                ? Image.file(
              File(liveThumbPath!),
              key: ValueKey(liveThumbPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: fTheme.scaffoldBackgroundColor),
            )
                : _placeholderThumb(context),
          ),
        ),
        // 본문
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                liveTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong,
              ),
              Gaps.h4,
              // 날짜
              if (item.item.date != null)
                Text(
                  _dateLabel(item.item.date),
                  style: AppTypography.caption,
                ),
            ],
          ),
        ),
      ],
    );

    return HoverButton(
      onPressed: () => ul.launchUrl(Uri.parse(item.item.url)),
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
          width: _newsCardWidth,
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
          child: body,
        );
      },
    );
  }

  Widget _placeholderThumb(BuildContext ctx) {
    final theme = FluentTheme.of(ctx);
    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Icon(FluentIcons.news, size: 28, color: theme.inactiveColor),
    );
  }
}

/// 스켈레톤 카드(로딩)
class _NewsSkeletonCard extends StatelessWidget {
  const _NewsSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final stroke = theme.resources.controlStrokeColorDefault;

    Widget block({double h = 14, double w = 120}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );

    return Container(
      width: _newsCardWidth,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 썸네일 영역 스켈레톤
          Container(
            width: _newsCardWidth,
            height: _newsThumbHeight,
            color: theme.resources.subtleFillColorTertiary,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(h: 16, w: _newsCardWidth - 48),
                Gaps.h6,
                block(h: 14, w: _newsCardWidth * 0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 메시지/에러 카드(빈/에러 공용)
class _NewsMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  const _NewsMessageCard.icon({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final stroke = theme.resources.controlStrokeColorDefault;

    return Container(
      width: _newsCardWidth,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: stroke),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: theme.inactiveColor),
              Gaps.h8,
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.typography.bodyStrong?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.h12,
              Button(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

// === 아래 유틸 그대로 사용 ===

class _EdgeFadedHScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double fadeWidth;

  const _EdgeFadedHScroll({
    required this.child,
    required this.controller,
    this.fadeWidth = 16,
  });

  @override
  State<_EdgeFadedHScroll> createState() => _EdgeFadedHScrollState();
}

class _EdgeFadedHScrollState extends State<_EdgeFadedHScroll> {
  bool _showLeft = false;
  bool _showRight = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recalc);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
  }

  @override
  void didUpdateWidget(covariant _EdgeFadedHScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_recalc);
      widget.controller.addListener(_recalc);
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recalc);
    super.dispose();
  }

  void _recalc() {
    if (!mounted || !widget.controller.hasClients) return;
    final p = widget.controller.position;
    final eps = 0.5;
    final left = p.pixels > (p.minScrollExtent + eps);
    final right = p.pixels < (p.maxScrollExtent - eps);
    if (left != _showLeft || right != _showRight) {
      setState(() {
        _showLeft = left;
        _showRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final bg = theme.cardColor;

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _recalc();
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showLeft ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: widget.fadeWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [bg, bg.withAlpha(0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showRight ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: widget.fadeWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [bg, bg.withAlpha(0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MouseDragScrollBehavior extends ScrollBehavior {
  const _MouseDragScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
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