import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class GameItemCard extends StatelessWidget {
  const GameItemCard({
    super.key,
    required this.title,
    required this.imageAsset,
    this.badgeText,
    this.loading = false,
    this.error = false,
  });

  final String title;
  final String? imageAsset;
  final String? badgeText;
  final bool loading;
  final bool error;

  static const double _kTitleHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final cardBg = t.resources.cardBackgroundFillColorDefault;
    final imageBg = t.micaBackgroundColor.withAlpha(40);
    final titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    if (loading) return _buildSkeleton(context);

    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppShapes.panel,
        border: Border.all(color: stroke, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 상단 이미지 영역: 남는 높이를 모두 차지
          Expanded(
            child: Container(
              color: imageBg,
              padding: EdgeInsets.all(AppSpacing.md),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (error)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FluentIcons.info),
                          const SizedBox(width: 8),
                          Text(loc.record_card_unavailable),
                        ],
                      ),
                    )
                  else if (imageAsset != null && imageAsset!.isNotEmpty)
                  // 오버플로우 방지: 컨테이너 안에서 contain
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: Image.asset(imageAsset!),
                      ),
                    ),
                  if (badgeText != null && badgeText!.isNotEmpty)
                    Positioned(top: 0, right: 0, child: _BadgeChip(text: badgeText!)),
                ],
              ),
            ),
          ),

          // 하단 타이틀 바
          Container(
            height: _kTitleHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final cardBg = t.resources.cardBackgroundFillColorDefault;
    final imageBg = t.micaBackgroundColor.withAlpha(40);
    final barBg  = t.resources.cardBackgroundFillColorSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppShapes.panel,
        border: Border.all(color: stroke, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: Container(color: imageBg)),
          Container(
            height: _kTitleHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final onAccent = t.resources.textOnAccentFillColorPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.accentColor,
        borderRadius: AppShapes.pill,
        border: Border.all(color: t.accentColor.dark, width: .5),
      ),
      child: Text(
        text,
        style: t.typography.caption?.copyWith(
          color: onAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
