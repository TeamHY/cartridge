import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 기록 페이지의 캐릭터/타깃 카드.
/// - theme.md 준수: FluentTheme 리소스만 사용(고정색 X)
/// - i18n: 배지/에러 문구는 AppLocalizations 사용
/// - 로딩/에러: 동일 레이아웃 유지(스켈레톤/단순 대체 UI)
class GameItemCard extends StatelessWidget {
  const GameItemCard({
    super.key,
    required this.title,
    required this.imageAsset,
    this.imageAspect = 148 / 125, // 기본 비율
    this.badgeText,
    this.loading = false,
    this.error = false,
  });

  /// 카드 하단의 제목
  final String title;

  /// 카드 상단 이미지(에셋 경로). 로딩/에러 시에도 비율 박스는 그대로 유지됨.
  final String? imageAsset;

  /// 이미지 비율(가로/세로)
  final double imageAspect;

  /// 이미지 우측 상단 배지(옵션). null이면 표시 안 함.
  final String? badgeText;

  /// true면 스켈레톤으로 표시(상호작용 없음)
  final bool loading;

  /// true면 동일 레이아웃 유지하며 단순 대체 표시
  final bool error;

  static const double _kTitleHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);

    // 공통 데코
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final cardBg = t.resources.cardBackgroundFillColorDefault;
    final imageBg = t.micaBackgroundColor.withAlpha(40);

    if (loading) {
      return _GameItemCardSkeleton(aspect: imageAspect, titleHeight: _kTitleHeight);
    }

    final loc = AppLocalizations.of(context);
    final titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    // 에러 상태: 동일 레이아웃 유지 + 담백한 메시지
    if (error) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppShapes.card,
          border: Border.all(color: stroke, width: .8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: imageAspect,
              child: Container(
                color: imageBg,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.info),
                      const SizedBox(width: 8),
                      Text(loc.record_card_unavailable),
                    ],
                  ),
                ),
              ),
            ),
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

    // 정상 상태
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppShapes.card,
        border: Border.all(color: stroke, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: imageAspect,
            child: Container(
              color: imageBg,
              padding: EdgeInsets.all(AppSpacing.md),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 내부 패딩(스켈레톤과 구조 일치)
                  const Padding(padding: EdgeInsets.all(8), child: SizedBox()),
                  if (imageAsset != null && imageAsset!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(imageAsset!, fit: BoxFit.contain),
                    ),
                  // 배지
                  if (badgeText != null && badgeText!.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _BadgeChip(text: badgeText!),
                    ),
                ],
              ),
            ),
          ),
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
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    // 텍스트 컬러도 theme 리소스 사용
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

class _GameItemCardSkeleton extends StatelessWidget {
  const _GameItemCardSkeleton({
    required this.aspect,
    required this.titleHeight,
  });

  final double aspect;
  final double titleHeight;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final cardBg = t.resources.cardBackgroundFillColorDefault;
    final imageBg = t.micaBackgroundColor.withAlpha(40);
    final barBg  = t.resources.cardBackgroundFillColorSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(aspectRatio: aspect, child: Container(color: imageBg)),
          Container(
            height: titleHeight,
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
