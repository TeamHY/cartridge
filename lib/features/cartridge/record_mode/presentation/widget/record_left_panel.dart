import 'package:cartridge/features/cartridge/record_mode/presentation/widget/record_timer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'layout/record_panels.dart';
import 'layout/section_card.dart';

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

    // (1) 상단 정보 블록 (rows=2)
    final topInfo = SectionCard(
      rows: 9,
      gapBelowRows: 1,
      child: TopInfoRow(
        challengeType: ui.challengeType,
        onChallengeTypeChanged: (p) => uiCtrl.setChallengeType(p),
        challengeTypeText: challengeTypeText,
        seedText: snap?.seed,
        showSeed: snap != null,
        loading: ui.loadingGoal,
        error: false,
      ),
    );

    // (2) 히어로 카드 (rows=3) — 카드 높이는 고정, 내부 콘텐츠만 스켈레톤/본문 전환
    final heroes = SectionCard(
      rows: 21,
      gapBelowRows: 1,
      child: LazySwitcher(
        loading: ui.loadingGoal,
        skeleton: const HeroCardsSkeleton(),
        empty: GoalEmpty(type: ui.challengeType, rangeText: challengeTypeText),
        child: () {
          final g = ui.goal;
          if (g == null) return const SizedBox.shrink();
          return HeroCardsRow(
            characterName: g.character.localizedName(loc),
            characterAsset: g.character.imageAsset,
            targetName: g.goal.localizedTitle(loc),
            targetAsset: g.goal.imageAsset,
          );
        }(),
      ),
    );


{

    }

    // (3) 하단 타이머/배너 (rows=1)
    final bottom = (temporal == ContestTemporal.current && ui.goal != null)
        ? SectionCard(
      rows: 8,
      child: RecordTimer(session: ref.read(recordModeSessionProvider)),
    )
        : SectionCard(
      rows: 8,
      padding: EdgeInsets.zero,
      child: const YoutubeBanner(height: 8 * kPanelRowUnit),
    );

    return RecordLeftPanelGrid(
      topInfo: topInfo,
      heroes: heroes,
      bottom: bottom,
    );
  }
}
