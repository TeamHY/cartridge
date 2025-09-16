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
    final hasGoal = snap != null;

    final challengeTypeText = () {
      final id = ui.gameId;
      if (id != null) {
        return RecordId.formatWeeklyRange(loc, id) ?? RecordId.formatGameLabel(loc, id);
      }
      return '';
    }();

    final temporal = RecordId.temporalOf(ui.gameId);

    // (1) 상단 정보 블록 (rows=2)
    final topInfo = SectionCard(
      rows: 7,
      gapBelowRows: 1,
      decoration: BoxDecoration(),
      padding: EdgeInsets.zero,
      child: TopInfoRow(
        challengeType: ui.challengeType,
        onChallengeTypeChanged: (p) => uiCtrl.setChallengeType(p),
        challengeTypeText: challengeTypeText,
        seedText: hasGoal ? snap.seed : null,
        showSeed: hasGoal,
        loading: ui.loadingGoal,
        error: false,
      ),
    );

    final Widget heroesChild;
    if (ui.loadingGoal) {
      // 로딩: 동일 레이아웃 유지(카드 스켈레톤 2개)
      heroesChild = Row(
        children: const [
          Expanded(child: GameItemCard(title: '', imageAsset: null, loading: true)),
          Gaps.w16,
          Expanded(child: GameItemCard(title: '', imageAsset: null, loading: true)),
        ],
      );
    } else {
    final g = ui.goal;
    if (g == null) {
      // 챌린지 없음: 안내 문구(기본 SectionCard 스타일과 어울리게)
      heroesChild = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              loc.record_no_challenge_title, // 예: "해당 기간에 챌린지가 없어요."
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Gaps.h6,
            Text(
              loc.record_no_challenge_body,  // 예: "조금만 기다리면 새로운 챌린지가 열릴 거예요."
              style: TextStyle(
                color: FluentTheme.of(context).resources.textFillColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      heroesChild = Row(
        children: [
          Expanded(
            child: GameItemCard(
              title: g.character.localizedName(loc),
              imageAsset: g.character.imageAsset,
              badgeText: loc.record_badge_character,
            ),
          ),
          Gaps.w16,
          Expanded(
            child: GameItemCard(
              title: g.goal.localizedTitle(loc),
              imageAsset: g.goal.imageAsset,
              badgeText: loc.record_badge_target,
            ),
          ),
        ],
      );
    }
    }

    SectionCard heroes;
    if (ui.goal == null) {
      heroes = SectionCard(
        rows: 20,
        gapBelowRows: 1,
        child: heroesChild,
      );
    } else {
      heroes = SectionCard(
        rows: 20,
        gapBelowRows: 1,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(),
        child: heroesChild,
      );
    }

    // (3) 하단 타이머/배너 (rows=1)
    final kBannerHeight = 9;
    final bottom = SectionCard(
      rows: kBannerHeight,
      padding: EdgeInsets.zero,
      child: (temporal == ContestTemporal.current && ui.goal != null)
          ? Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: const RecordTimer(),
      )
          : YoutubeBanner(height: kBannerHeight * kPanelRowUnit),
    );

    return RecordLeftPanelGrid(
      topInfo: topInfo,
      heroes: heroes,
      bottom: bottom,
    );
  }
}
