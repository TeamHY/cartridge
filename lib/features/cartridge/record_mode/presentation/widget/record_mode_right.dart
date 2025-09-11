import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/theme/theme.dart';


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

    // 상단 네비 (항상 유지)
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

      return sectionCard(
        context,
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
    }

    // 현재/예정
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionCard(
          context,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: _RightNowBlock(),
        ),
        Gaps.h12,
        AllowedModsSection(),
      ],
    );
  }
}

class _RightNowBlock extends ConsumerWidget {
  const _RightNowBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui     = ref.watch(recordModeUiControllerProvider);
    final uiCtrl = ref.read(recordModeUiControllerProvider.notifier);
    final entries = ui.entries;

    // 현재 로그인 사용자 닉네임
    final me      = ref.watch(recordModeAuthUserProvider).value;
    final myNick  = me?.nickname.trim();

    // 내 최고기록(가장 짧은 clearTime)
    final Duration? myBestTime = (myNick == null || myNick.isEmpty)
        ? null
        : entries
        .where((e) => e.nickname.trim() == myNick && e.clearTime != null)
        .map((e) => e.clearTime!)
        .fold<Duration?>(null, (min, t) => (min == null || t < min) ? t : min);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
        ),
        const Divider(),
        LiveStatusTile(
          participants: entries.length,
          myBest: myBestTime,
        ),
      ],
    );
  }
}
