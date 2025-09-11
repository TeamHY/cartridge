import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartridge/app/presentation/pages/content_detail_page.dart';
import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/features/cartridge/battle_mode/presentation/pages/battle_mode_detail_page.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/theme/theme.dart';


/// 카테고리 구분
enum ContentCategory { hyZone, info }

/// 컨텐츠 아이템 모델
class ContentItem {
  final String id;
  final String title;
  final String description;
  final ContentCategory category;
  final String? imageAsset;
  final Uri? externalUrl;

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageAsset,
    this.externalUrl,
  });
}

final _searchProvider = StateProvider<String>((_) => '');
final _categoryProvider = StateProvider<ContentCategory?>((_) => null);
final _selectedProvider = StateProvider<ContentItem?>((_) => null);

class ContentPage extends ConsumerWidget {
  const ContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchProvider);
    final selectedCategory = ref.watch(_categoryProvider);
    final selected = ref.watch(_selectedProvider);

    final items = _buildItems();

    // 상세 선택 시: 해당 페이지로 대체
    if (selected != null) {
      Widget detail;
      void onClose() => ref.read(_selectedProvider.notifier).state = null;

      if (selected.id == 'record') {
        detail = RecordModeDetailPage(onClose: onClose);
      } else if (selected.id == 'battle') {
        detail = BattleModeDetailPage(onClose: onClose);
      } else {
        detail = ContentDetailPage(
          id: selected.id,
          titleText: selected.title,
          description: selected.description,
          imageAsset: selected.imageAsset,
          onClose: onClose,
        );
      }
      return detail;
    }

    // 필터링
    final filtered = items.where((e) {
      final catOk = selectedCategory == null || e.category == selectedCategory;
      final q = query.trim().toLowerCase();
      final qOk = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList(growable: false);

    // 카테고리 그룹핑
    final groups = <ContentCategory, List<ContentItem>>{};
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
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(title: _categoryLabel(cat)),
                  const SizedBox(height: AppSpacing.sm),
                  _ResponsiveCards(
                    items: groups[cat]!,
                    onOpen: (it) async {
                      if (it.externalUrl != null) {
                        try {
                          final ok = await launchUrl(
                            it.externalUrl!,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!ok && context.mounted) {
                            UiFeedback.warn(
                              context,
                              '링크를 열 수 없어요',
                              '브라우저에서 "${it.title}" 페이지를 열지 못했습니다.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            UiFeedback.error(
                              context,
                              '열기 실패',
                              '외부 링크를 여는 중 오류가 발생했습니다: $e',
                            );
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

  List<ContentItem> _buildItems() {
    // 이미지 자산은 존재 보장이 어려우므로 errorBuilder로 대체 표시
    return [
      // Special modes (준비중 상세)
      const ContentItem(
        id: 'record',
        title: '시참대회',
        description: '오헌영의 아이작 기록 경쟁',
        category: ContentCategory.hyZone,
        imageAsset: 'assets/images/contents/시참대회.png',
      ),
      const ContentItem(
        id: 'battle',
        title: '대결모드',
        description: '오헌영과 아이작 대결해 보세요',
        category: ContentCategory.hyZone,
        imageAsset: 'assets/images/contents/대결모드.png',
      ),

      // Info
      ContentItem(
        id: 'info-isaacguru',
        title: 'Isaac Guru Laboratory',
        description: '아이작 아이템 정보를 빠르게 찾아보세요',
        category: ContentCategory.info,
        imageAsset: 'assets/images/contents/isaacguru_com.jpg',
        externalUrl: Uri.parse('https://isaacguru.com/'),
      ),
      ContentItem(
        id: 'info-repentogon',
        title: 'Repentogon',
        description: '아이작 모드의 새 지평을 열다.',
        category: ContentCategory.info,
        imageAsset: 'assets/images/contents/리펜토곤.png',
        externalUrl: Uri.parse('https://github.com/TeamREPENTOGON/REPENTOGON'),
      ),

      // Promo
      ContentItem(
        id: 'promo-cafe',
        title: '오헌영 네이버 카페',
        description: '공지/커뮤니티 소식 보러가기',
        category: ContentCategory.hyZone,
        imageAsset: 'assets/images/contents/네이버카페.png',
        externalUrl: Uri.parse('https://cafe.naver.com/iwt2hw'),
      ),
    ];
  }

  String _categoryLabel(ContentCategory c) {
    switch (c) {
      case ContentCategory.hyZone:
        return '헌영이와 아이작 같이 즐기기';
      case ContentCategory.info:
        return '정보';
    }
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.resources.textFillColorPrimary,
        ),
      ),
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  final List<ContentItem> items;
  final ValueChanged<ContentItem> onOpen;
  const _ResponsiveCards({required this.items, required this.onOpen});

  int _calcColumns(double w) {
    // 최소 2열 유지
    if (w < AppBreakpoints.md) return 2;
    if (w < AppBreakpoints.lg) return 3;
    if (w < AppBreakpoints.xl) return 4;
    return 5;
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
  final ContentItem item;
  final VoidCallback onOpen;
  const _ContentCard({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isExternal = item.externalUrl != null;

    void handleTap() => onOpen();

    return HoverButton(
      onPressed: handleTap,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.resources.cardStrokeColorDefault, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: hovered ? theme.accentColor.normal.withAlpha(40) : Colors.black.withAlpha(20),
                blurRadius: hovered ? 12 : 8,
                spreadRadius: hovered ? 1 : 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: item.imageAsset != null
                    ? Image.asset(
                  item.imageAsset!,
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
                          Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(item.description, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    // 외부 링크 배지 (optional)
                    if (isExternal) ...[
                      Gaps.w8,
                      Tooltip(
                        message: '외부 링크',
                        child: Icon(
                          material.Icons.open_in_new,
                          size: 16,
                          // 호버 시 약하게 강조
                          color: hovered
                              ? theme.accentColor
                              : theme.resources.textFillColorSecondary,
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