import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);

    final challengeTypeText = () {
      final id = ui.gameId;
      if (id != null) {
        return RecordId.formatWeeklyRange(loc, id) ?? RecordId.formatGameLabel(loc, id);
      }
      return '';
    }();

    Widget navBar() => Row(
      children: [
        IconButton(icon: const Icon(FluentIcons.chevron_left),
            onPressed: ui.neighbors?.prev == null ? null : uiCtrl.navPrev),
        Gaps.w6,
        IconButton(icon: const Icon(FluentIcons.chevron_right),
            onPressed: ui.neighbors?.next == null ? null : uiCtrl.navNext),
        Gaps.w12,
        if (ui.gameId != null)
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Icon(FluentIcons.date_time2, size: 15),
          ),
        Expanded(
          child: Text(
            ui.gameId == null ? loc.common_loading : challengeTypeText,
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
        rows: 38,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            navBar(),
            Gaps.h8,
            Expanded(
              child: () {
                if (entries.isEmpty && !loading) return const RankingEmptyPanelPast();

                // 스크롤 + 로딩/데이터 공용 처리
                return _RankingScroll(
                  podium: podium,
                  rest: rest,
                  isAdmin: isAdmin,
                  loading: loading,
                );
              }(),
            ),
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
      rows: 24,
      child: const AllowedModsSection(),
    );

    return RecordRightPanelCurrentGrid(
      header: header,
      allowedDashboard: allowed,
    );
  }
}

class _RankingScroll extends StatefulWidget {
  const _RankingScroll({
    required this.podium,
    required this.rest,
    required this.isAdmin,
    this.loading = false,
  });

  final List<LeaderboardEntry> podium;
  final List<LeaderboardEntry> rest;
  final bool isAdmin;
  final bool loading;

  @override
  State<_RankingScroll> createState() => _RankingScrollState();
}

class _RankingScrollState extends State<_RankingScroll> {
  late final ScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _ctrl,
      thumbVisibility: true,
      child: CustomScrollView(
        controller: _ctrl,
        primary: false,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Podium(
                entries: widget.podium,
                isAdmin: widget.isAdmin,
                loading: widget.loading,
              ),
            ),
          ),
          if (widget.loading)
            SliverList.builder(
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: RankTile.loading(),
              ),
            )
          else
            SliverList.separated(
              itemCount: widget.rest.length,
              itemBuilder: (_, i) =>
                  RankTile(entry: widget.rest[i], isAdmin: widget.isAdmin),
              separatorBuilder: (_, __) => Gaps.h8,
            ),
        ],
      ),
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

    final live = LiveStatusTile(participants: entries.length, myBest: myBestTime);

    return LayoutBuilder(
      builder: (context, c) {
        final bounded = c.hasBoundedHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (navBarBuilder != null) navBarBuilder!(),
            Gaps.h4,
            const Divider(
              style: DividerThemeData(thickness: 1, horizontalMargin: EdgeInsets.zero),
            ),
            Gaps.h12,
            if (bounded)
              Expanded(child: live) // ⟵ 섹션의 남는 높이 전부 타일에
            else
              live,
          ],
        );
      },
    );
  }
}
