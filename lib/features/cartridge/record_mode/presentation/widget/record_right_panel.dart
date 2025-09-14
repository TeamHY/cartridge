import 'package:cartridge/features/cartridge/record_mode/presentation/widget/allowed_mods/allowed_modes_section.dart';
import 'package:cartridge/features/cartridge/record_mode/presentation/widget/live_status_tile.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'layout/record_panels.dart';
import 'package:cartridge/theme/theme.dart';

import 'layout/section_card.dart';

class RecordModeRightPanel extends ConsumerWidget {
  const RecordModeRightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui     = ref.watch(recordModeUiControllerProvider);
    final uiCtrl = ref.read(recordModeUiControllerProvider.notifier);
    final entries = ui.entries;
    final isAdmin = ref.watch(recordModeAuthUserProvider).value?.isAdmin ?? false;
    final temporal = RecordId.temporalOf(ui.gameId);
    final loading  = ui.loadingMore && entries.isEmpty;

    Widget navBar() => Row(
      children: [
        IconButton(icon: const Icon(FluentIcons.chevron_left),
            onPressed: ui.neighbors?.prev == null ? null : uiCtrl.navPrev),
        Gaps.w6,
        IconButton(icon: const Icon(FluentIcons.chevron_right),
            onPressed: ui.neighbors?.next == null ? null : uiCtrl.navNext),
        Gaps.w12,
        Expanded(
          child: Text(
            ui.gameId == null ? '로딩 중...' : RecordId.formatGameLabel(ui.gameId!),
            maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
          ),
        ),
        IconButton(
          icon: const Icon(FluentIcons.refresh),
          onPressed: () => uiCtrl.fetchMore(reset: true),
        ),
      ],
    );

    if (temporal == ContestTemporal.past) {
      final podium = entries.take(3).toList(growable: false);
      final rest   = entries.length > 3 ? entries.sublist(3) : const <LeaderboardEntry>[];

      final ranking = SectionCard(
        rows: 40,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            navBar(),
            Gaps.h8,
            if (loading) const RankingSkeleton()
            else if (entries.isEmpty) const RankingEmptyPanelPast()
            else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                  child: Podium(entries: podium, isAdmin: isAdmin),
                ),
                if (rest.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rest.length,
                    separatorBuilder: (_, __) => Gaps.h8,
                    itemBuilder: (_, i) => RankTile(entry: rest[i], isAdmin: isAdmin),
                  ),
              ],
          ],
        ),
      );

      return RecordRightPanelPastGrid(rankingBoard: ranking);
    }

    final header = SectionCard(
      rows: 13,
      gapBelowRows: 1,
      child: _RightNowBlock(navBarBuilder: navBar),
    );

    // AllowedModsSection 내부에서 이미 SectionCard를 감싸고 있다면
    // 여기서 rows를 보장하고 싶으면 AllowedModsSection 쪽도 SectionCard(rows:4)로 바꿔줘.
    final allowed = SectionCard(
      rows: 26,
      child: const AllowedModsSection(),
    );

    return RecordRightPanelCurrentGrid(
      header: header,
      allowedDashboard: allowed,
    );
  }
}

class _RightNowBlock extends ConsumerWidget {
  const _RightNowBlock({this.navBarBuilder});
  final Widget Function()? navBarBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui     = ref.watch(recordModeUiControllerProvider);
    final entries = ui.entries;

    final me      = ref.watch(recordModeAuthUserProvider).value;
    final myNick  = me?.nickname.trim();

    final Duration? myBestTime = (myNick == null || myNick.isEmpty)
        ? null
        : entries
        .where((e) => e.nickname.trim() == myNick && e.clearTime != null)
        .map((e) => e.clearTime!)
        .fold<Duration?>(null, (min, t) => (min == null || t < min) ? t : min);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (navBarBuilder != null) navBarBuilder!(),
        Gaps.h4,
        const Divider(
          style: DividerThemeData(thickness: 1, horizontalMargin: EdgeInsets.zero),
        ),
        Gaps.h8,
        LiveStatusTile(participants: entries.length, myBest: myBestTime),
      ],
    );
  }
}
