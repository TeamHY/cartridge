import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';


class RecordModeLeftPanel extends ConsumerWidget {
  const RecordModeLeftPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui     = ref.watch(recordModeUiControllerProvider);
    final uiCtrl = ref.read(recordModeUiControllerProvider.notifier);
    final loc    = AppLocalizations.of(context);
    final snap   = ui.goal;

    final challengeTypeText = () {
      final id = ui.gameId;
      if (id != null) {
        return RecordId.formatWeeklyRange(id) ?? RecordId.formatGameLabel(id);
      }
      return (snap?.challengeType ?? ui.challengeType) == ChallengeType.daily ? '오늘' : '이번 주';
    }();

    final temporal = RecordId.temporalOf(ui.gameId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gaps.h8,

        TopInfoRow(
          challengeType: ui.challengeType,
          onChallengeTypeChanged: (p) => uiCtrl.setChallengeType(p),
          challengeTypeText: challengeTypeText,
          seedText: snap?.seed,
          // ⬇ 목표 없으면 시드 칩 감춤
          showSeed: snap != null,
        ),

        Gaps.h12,

        // 히어로 카드 / 없음 표시
        LazySwitcher(
          loading: ui.loadingGoal,
          skeleton: const HeroCardsSkeleton(),
          empty: GoalEmpty(
            type: ui.challengeType,
            rangeText: challengeTypeText,
          ),
          child: () {
            final g = ui.goal;
            if (g == null) {
              return const SizedBox.shrink();
            }
            return HeroCardsRow(
              characterName: g.character.localizedName(loc),
              characterAsset: g.character.imageAsset,
              targetName: g.goal.localizedTitle(loc),
              targetAsset: g.goal.imageAsset,
            );
          }(),
        ),

        Gaps.h12,

        // ⬇ 타이머는 “현재 기간”이면서 “목표가 있을 때”만 노출
        if (temporal == ContestTemporal.current && ui.goal != null)
          sectionCard(
            context,
            child: Timer64(session: ref.watch(recordModeSessionProvider)),
          )
        else
          const YoutubeBanner(),
      ],
    );
  }
}
