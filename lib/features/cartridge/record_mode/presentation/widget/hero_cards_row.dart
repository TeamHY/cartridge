import 'package:cartridge/features/cartridge/record_mode/presentation/widget/record_game_item_card.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';

const double kHeroCardAspect = 148 / 125; // ≈ 1.184, 타겟 기준
const double kHeroCardTitleHeight = 48.0;
const double kHeroCardGap = 16.0;


class HeroCardsRow extends StatelessWidget {
  const HeroCardsRow({
    super.key,
    required this.characterName,
    required this.characterAsset,
    required this.targetName,
    required this.targetAsset,
    this.loading = false,
    this.error = false,
  });

  final String characterName;
  final String characterAsset;
  final String targetName;
  final String targetAsset;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: GameItemCard(
            title: characterName,
            imageAsset: characterAsset,
            badgeText: loc.record_badge_character,
            loading: loading,
            error: error,
          ),
        ),
        const SizedBox(width: kHeroCardGap),
        Expanded(
          child: GameItemCard(
            title: targetName,
            imageAsset: targetAsset,
            badgeText: loc.record_badge_target,
            loading: loading,
            error: error,
          ),
        ),
      ],
    );
  }
}