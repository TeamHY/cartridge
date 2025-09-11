
import 'dart:async';
import 'dart:io';
import 'package:cartridge/core/log.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/badge.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_view.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:cartridge/features/web_preview/application/web_preview_providers.dart';
import 'package:cartridge/features/web_preview/application/web_preview_cache.dart';
import 'package:cartridge/core/utils/workshop_util.dart';

typedef ExtraBadgesBuilder = List<BadgeSpec> Function(ModView row, FluentThemeData ft);
typedef OnTapTitle = Future<void> Function();

class ModTitleCell extends ConsumerStatefulWidget {
  final ModView row;
  final String displayName;
  final bool showVersionUnderTitle;

  /// 제목 클릭 동작(예: 워크샵 페이지 열기)
  final OnTapTitle? onTapTitle;

  /// 페이지별 추가 배지(예: Instance에서 Record Mode)
  final ExtraBadgesBuilder? extraBadges;

  /// 플레이스홀더 이니셜 기본값
  final String placeholderFallback;

  /// 로케일 기반 프리뷰 prewarm 수행
  final bool prewarmPreview;

  const ModTitleCell({
    super.key,
    required this.row,
    required this.displayName,
    required this.showVersionUnderTitle,
    this.onTapTitle,
    this.extraBadges,
    this.placeholderFallback = 'M',
    this.prewarmPreview = true,
  });

  @override
  ConsumerState<ModTitleCell> createState() => _ModTitleCellState();
}

class _ModTitleCellState extends ConsumerState<ModTitleCell> {
  String? _requestedKey;
  static final Set<String> _prewarmed = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePrewarmWithLocale(Localizations.localeOf(context));
  }

  @override
  void didUpdateWidget(covariant ModTitleCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.modId != widget.row.modId) {
      _requestedKey = null;
      _maybePrewarmWithLocale(Localizations.localeOf(context));
    }
  }

  void _maybePrewarmWithLocale(Locale locale) {
    if (!widget.prewarmPreview) return;

    final modId = widget.row.modId.isNotEmpty ? widget.row.modId : null;
    if (modId == null) return;

    final url = SteamUrls.workshopItem(modId);
    final langCode = locale.languageCode;
    final key = '$url|$langCode';

    if (_requestedKey == key || _prewarmed.contains(key)) return;

    final previewAsync = ref.read(webPreviewProvider(url));
    final preview = previewAsync.maybeWhen(data: (p) => p, orElse: () => null);
    final title = preview?.title;
    final imagePath = preview?.imagePath;
    final exists = (imagePath != null && imagePath.isNotEmpty) && File(imagePath).existsSync();

    final need = preview == null ||
        shouldRefetchForLocale(
          langCode: langCode,
          title: title,
          imagePath: imagePath,
          imageFileExists: exists,
        );

    _requestedKey = key;
    if (!need) return;

    _prewarmed.add(key);

    final cache = ref.read(webPreviewCacheProvider);
    unawaited(() async {
      try {
        await cache.getOrFetch(
          url,
          policy: const RefreshPolicy.ttl(Duration(hours: 72)),
          source: 'workshop_mod',
          sourceId: url,
          targetMaxWidth: 128,
          targetMaxHeight: 128,
        );
      } catch (e, st) {
        logE('WebPreviewCell', 'key=$key prewarm fail url=$url', e, st);
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final tTheme = UTTableTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);
    final density = tTheme.density;
    final bool showThumb = density != UTTableDensity.compact;
    final loc = AppLocalizations.of(context);

    final double thumbSize = switch (density) {
      UTTableDensity.compact => 0,
      UTTableDensity.comfortable => 40,
      UTTableDensity.tile => 56,
    };

    final fTheme = FluentTheme.of(context);
    final String? url = widget.row.modId.isNotEmpty ? SteamUrls.workshopItem(widget.row.modId) : null;

    final previewAsync = (url != null) ? ref.watch(webPreviewProvider(url)) : const AsyncValue.data(null);
    final preview = previewAsync.maybeWhen(data: (p) => p, orElse: () => null);
    final thumbPath = preview?.imagePath;

    // 기본 배지(Missing/LOCAL)
    final badges = <BadgeSpec>[];
    if (widget.row.isMissing) {
      badges.add(BadgeSpec(loc.mod_missing_short, sem.danger));
    } else if (widget.row.isLocalMod) {
      badges.add(BadgeSpec(loc.mod_local_short, sem.info));
    }
    if (widget.extraBadges != null) badges.addAll(widget.extraBadges!(widget.row, fTheme));

    Widget thumbPlaceholder(double size) {
      final bg = fTheme.accentColor.normal.withAlpha(28);
      final border = fTheme.accentColor.normal.withAlpha(90);
      final initial = extractInitialAny(widget.displayName, fallback: widget.placeholderFallback);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.46,
            fontWeight: FontWeight.w700,
            color: fTheme.accentColor.darker,
            height: 1,
          ),
        ),
      );
    }

    Widget? thumb;
    if (showThumb) {
      final exists = (thumbPath != null && thumbPath.isNotEmpty) && File(thumbPath).existsSync();
      thumb = Container(
        width: thumbSize,
        height: thumbSize,
        margin: const EdgeInsets.only(right: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: exists
            ? Image.file(File(thumbPath), key: ValueKey(thumbPath), fit: BoxFit.cover)
            : thumbPlaceholder(thumbSize),
      );
    }

    return LayoutBuilder(
      builder: (ctx, box) {
        final cellW = box.maxWidth;
        final hideBadges = cellW < 160;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (thumb != null) thumb,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!hideBadges && badges.isNotEmpty) ...[
                        Flexible(
                          fit: FlexFit.loose,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cellW * 0.45),
                            child: BadgeStrip(badges: badges),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        fit: FlexFit.tight,
                        child: ClipRect(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 0),
                            child: UTActionCell(
                              onTap: widget.onTapTitle,
                              child: Text(
                                widget.displayName,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                textWidthBasis: TextWidthBasis.parent,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.showVersionUnderTitle) ...[
                    const SizedBox(height: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 0),
                      child: Text(
                        'version: ${widget.row.version}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: fTheme.resources.textFillColorSecondary),
                        textWidthBasis: TextWidthBasis.parent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
