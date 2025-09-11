import 'dart:io';
import 'dart:ui' show PointerDeviceKind;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'package:cartridge/features/steam_news/steam_news.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/app/presentation/widgets/home/home_card.dart';
import 'package:cartridge/theme/theme.dart';


const _cardRadius = 12.0;
const _newsViewportHeight = 200.0;
const _newsCardWidth = 240.0;
const _newsThumbHeight = 115.0;

class SteamNewsSection extends ConsumerWidget {
  const SteamNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(steamNewsCardsProvider);

    return HomeCard(
      title: 'Steam Isaac News',
      trailing: HyperlinkButton(
        child: const Text('뉴스 더보기'),
        onPressed: () => ul.launchUrl(
          Uri.parse('https://store.steampowered.com/news/app/250900'),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.md),
      child: newsAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Text('Failed to load news: $e'),
        data: (cards) {
          if (cards.isEmpty) {
            return _NewsEmptyStrip(
              onRefresh: () => ref.invalidate(steamNewsCardsProvider),
            );
          }
          final ctrl = ScrollController();
          return SizedBox(
            height: _newsViewportHeight,
            child: _EdgeFadedHScroll(
              controller: ctrl,
              fadeWidth: 16,
              child: ScrollConfiguration(
                behavior: const _MouseDragScrollBehavior(),
                child: Scrollbar(
                  controller: ctrl,
                  interactive: true,
                  child: ListView.separated(
                    controller: ctrl,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 4),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => Gaps.w12,
                    itemBuilder: (context, i) => _NewsCard(item: cards[i]),
                  ),
                ),
              ),
            ),
          );
        },
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

  String _host(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final dividerColor = theme.dividerColor;

    final previewAsync = ref.watch(webPreviewProvider(item.item.url));
    final preview = previewAsync.maybeWhen(data: (p) => p, orElse: () => null);

    final liveThumbPath = preview?.imagePath ?? item.thumbPath;
    final liveTitle     = (preview?.title.isNotEmpty ?? false)
        ? preview!.title
        : item.item.title;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 썸네일
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_cardRadius),
            topRight: Radius.circular(_cardRadius),
          ),
          child: SizedBox(
            width: _newsCardWidth,
            height: _newsThumbHeight,
            child: (liveThumbPath ?? '').isNotEmpty
                ? Image.file(
              File(liveThumbPath!),
              key: ValueKey(liveThumbPath),       // 경로 바뀌면 강제 리빌드
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: theme.scaffoldBackgroundColor),
            )
                : _placeholderThumb(context),
          ),
        ),
        // 본문
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                liveTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Gaps.h4,
              // 날짜 + 호스트
              if (item.item.date != null)
                Text(_dateLabel(item.item.date),
                    style: TextStyle(color: theme.inactiveColor, fontSize: 12)),
            ],
          ),
        ),
      ],
    );

    return HoverButton(
      onPressed: () => ul.launchUrl(Uri.parse(item.item.url)),
      builder: (context, states) {
        final hovered = states.isHovered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: _newsCardWidth,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: dividerColor),
            boxShadow: hovered
                ? [
              BoxShadow(
                color: theme.shadowColor.withAlpha(28),
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

  String finalHost(String url) => _host(url);

  Widget _placeholderThumb(BuildContext ctx) {
    final theme = FluentTheme.of(ctx);
    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Icon(FluentIcons.news, size: 28, color: theme.inactiveColor),
    );
  }
}

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

class _NewsEmptyStrip extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _NewsEmptyStrip({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      height: _newsViewportHeight,
      child: Row(
        children: [
          Container(
            width: _newsCardWidth,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.news, size: 28, color: theme.inactiveColor),
                  Gaps.h8,
                  const Text('최근 뉴스가 없습니다', style: TextStyle(fontWeight: FontWeight.w600)),
                  Gaps.h12,
                  Button(onPressed: onRefresh, child: const Text('새로고침')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
