import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';

class ContentDetailPage extends StatelessWidget {
  final String id;
  final String titleText;
  final String description;
  final String? imageAsset;
  final VoidCallback? onClose;
  const ContentDetailPage({super.key, required this.id, required this.titleText, required this.description, required this.imageAsset, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(titleText),
        commandBar: Row(
          children: [
            Tooltip(
              message: '뒤로가기',
              child: IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => (onClose ?? () => Navigator.of(context).maybePop())(),
              ),
            ),
          ],
        ),
      ),
      children: [
        LayoutBuilder(
          builder: (ctx, c) {
            final isNarrow = c.maxWidth < 900; // stack for small widths
            final imageWidget = ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImageFallback(),
                      )
                    : const _ImageFallback(),
              ),
            );

            final rightPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title already in header via Hero; keep description here
                Text(description),
                Gaps.h16,

                // Reserved empty content area (placeholder for future detail content)
                Container(
                  constraints: const BoxConstraints(minHeight: 280),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.resources.cardStrokeColorDefault, width: 0.8),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '컨텐츠 영역 (비어 있음)',
                      style: TextStyle(color: theme.resources.textFillColorSecondary),
                    ),
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageWidget,
                  Gaps.h16,
                  rightPanel,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: image, fixed max width
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: imageWidget,
                ),
                Gaps.w16,

                // Right: info + reserved area expands
                Expanded(child: rightPanel),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      color: theme.micaBackgroundColor.withAlpha(160),
      child: const Center(child: Icon(FluentIcons.picture, size: 28)),
    );
  }
}
