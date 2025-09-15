import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/features/cartridge/content/content.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';


final _searchProvider = StateProvider<String>((_) => '');
final _categoryProvider = StateProvider<ContentCategory?>((_) => null);
final _selectedProvider = StateProvider<ContentEntry?>((_) => null);

class ContentPage extends ConsumerWidget {
  const ContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final query = ref.watch(_searchProvider);
    final selectedCategory = ref.watch(_categoryProvider);
    final selected = ref.watch(_selectedProvider);
    final lang = Localizations.localeOf(context).languageCode;

    final indexAsync = ref.watch(_contentIndexProvider);
    final items = indexAsync.maybeWhen(
      data: (idx) => idx.entries,
      orElse: () => const <ContentEntry>[],
    );

    // 상세 선택 시: 해당 페이지로 대체
    if (selected != null) {
      Widget detail;
      void onClose() => ref.read(_selectedProvider.notifier).state = null;

      if (selected.id == 'record') {
        detail = RecordModeDetailPage(onClose: onClose);
      } else {
        detail = LocalizedMarkdownPage(
          onClose: onClose,
          title: selected.titleFor(lang),
          markdownAsset: selected.markdown!,
        );
      }
      if (selected.type == ContentType.custom) {
        switch (selected.id) {
          case 'record':
            detail = RecordModeDetailPage(onClose: onClose);
            break;
          default:
            // 안전망: 아직 미구현 커스텀은 안내
            UiFeedback.warn(
              context,
              title: loc.content_custom_unavailable_title,
              content: loc.content_custom_unavailable_desc,
            );
            return EmptyState.withDefault404(
              title: loc.doc_load_fail_desc,
            );
        }
      } else if (selected.type == ContentType.detail) {
        detail = LocalizedMarkdownPage(
          onClose: onClose,
          title: selected.titleFor(lang),
          markdownAsset: selected.markdown!,
        );
      }
      return detail;
    }
    // loading /에러 처리 (레이아웃 단순 유지)
    if (indexAsync.isLoading) {
      return const ScaffoldPage(header: ContentHeaderBar.none(), content: Center(child: ProgressRing()));
    }
    if (indexAsync.hasError) {
      return ScaffoldPage(
        header: const ContentHeaderBar.none(),
        content: Center(
          child: InfoBar(
            title: Text(loc.content_list_load_fail_title),
            content: Text(loc.content_list_load_fail_desc),
            severity: InfoBarSeverity.error,
          ),
        ),
      );
    }

    // 필터링(언어 반영)
    final filtered = ContentIndex(items).filter(
      category: selectedCategory,
      query: query,
      lang: lang,
    );

    // 카테고리 그룹핑
    final groups = <ContentCategory, List<ContentEntry>>{};
    for (final it in filtered) {
      groups.putIfAbsent(it.category, () => []).add(it);
    }

    return ScaffoldPage(
      header: const ContentHeaderBar.none(),
      content: ContentShell(
        child: SettingsSection(
          leftAligned: true,
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final cat in ContentCategory.values)
                if ((groups[cat] ?? const []).isNotEmpty) ...[
                  Gaps.h12,
                  _SectionHeader(title: _categoryLabel(context, cat)),
                  Gaps.h8,
                  _ResponsiveCards(
                    items: groups[cat]!,
                    onOpen: (it) async {
                      if (it.type == ContentType.link) {
                        try {
                          final urlStr = it.urlFor(lang) ?? it.urlFor('ko') ?? it.urlFor('en');
                          if (urlStr == null) {
                            UiFeedback.warn(context, content: loc.content_open_link_fail_desc);
                            return;
                          }
                          final ok = await launchUrl(
                            Uri.parse(urlStr),
                            mode: LaunchMode.externalApplication,
                          );
                          if (!ok && context.mounted) {
                            UiFeedback.warn(context, content: loc.content_open_link_fail_desc);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            UiFeedback.error(context, content: loc.content_open_link_error_desc);
                          }
                        }
                        return; // 외부 링크는 상세로 진입하지 않음
                      }
                      ref.read(_selectedProvider.notifier).state = it;
                    },
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  static final _contentIndexProvider = FutureProvider<ContentIndex>((ref) async {
    return await loadContentIndex();
  });

  String _categoryLabel(BuildContext context, ContentCategory c) {
    final loc = AppLocalizations.of(context);
    switch (c) {
      case ContentCategory.hyZone:
        return loc.content_category_hyzone;
      case ContentCategory.info:
        return loc.content_category_info;
    }
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(title, style: AppTypography.sectionTitle),
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  final List<ContentEntry> items;
  final ValueChanged<ContentEntry> onOpen;
  const _ResponsiveCards({required this.items, required this.onOpen});

  int _calcColumns(double w) {
    // 최소 2열 유지
    if (w < AppBreakpoints.sm) return 2;
    if (w < AppBreakpoints.md) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final columns = _calcColumns(c.maxWidth);
      final spacing = AppSpacing.lg.toDouble();
      final cardWidth = (c.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final item in items)
            SizedBox(width: cardWidth, child: _ContentCard(item: item, onOpen: () => onOpen(item))),
        ],
      );
    });
  }
}

class _ContentCard extends StatelessWidget {
  final ContentEntry item;
  final VoidCallback onOpen;
  const _ContentCard({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final isExternal = item.type == ContentType.link;
    final lang = Localizations.localeOf(context).languageCode;

    void handleTap() => onOpen();

    return HoverButton(
      onPressed: handleTap,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return Container(
          decoration: BoxDecoration(
            color: fTheme.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: fTheme.resources.cardStrokeColorDefault),
            boxShadow: [
              BoxShadow(
                color: hovered
                    ? fTheme.accentColor.normal.withAlpha(40)
                    : fTheme.resources.textFillColorSecondary.withAlpha(25),
                blurRadius: hovered ? 12 : 8,
                spreadRadius: hovered ? 1 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: item.image != null
                    ? Image.asset(
                  item.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ImageFallback(),
                )
                    : _ImageFallback(),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 텍스트 영역
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title[lang]!, style: AppTypography.bodyStrong),
                          Gaps.h6,
                          Text(item.description[lang]!, style:  AppTypography.caption),
                        ],
                      ),
                    ),
                    // 외부 링크 배지 (optional)
                    if (isExternal) ...[
                      Gaps.w8,
                      Tooltip(
                        message: AppLocalizations.of(context).content_external_link_tooltip,
                        child: Icon(
                          material.Icons.open_in_new,
                          size: 16,
                          // 호버 시 약하게 강조
                          color: hovered
                              ? fTheme.accentColor
                              : fTheme.resources.textFillColorSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      color: theme.micaBackgroundColor.withAlpha(160),
      child: const Center(child: Icon(FluentIcons.picture, size: 28)),
    );
  }
}