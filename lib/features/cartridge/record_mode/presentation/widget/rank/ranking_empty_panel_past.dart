import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class RankingEmptyPanelPast extends StatelessWidget {
  const RankingEmptyPanelPast({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final fill = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    return SizedBox.expand( // ⟵ 카드 내부 가용 높이 채움
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stroke, width: .8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: t.micaBackgroundColor.withAlpha(60),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Icon(FluentIcons.info)),
            ),
            Gaps.w12,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.ranking_empty_title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(loc.ranking_empty_suggestion, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}