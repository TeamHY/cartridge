import 'dart:async';
import 'package:cartridge/features/cartridge/record_mode/presentation/widget/record_game_item_card.dart';
import 'package:cartridge/features/cartridge/record_mode/presentation/widget/record_info_chips.dart';
import 'package:cartridge/features/cartridge/record_mode/presentation/widget/record_period_switcher.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/theme/theme.dart';

const double kRightPanelPlaceholderHeight = 400.0;
const double kHeroCardAspect = 148 / 125; // ≈ 1.184, 타겟 기준
const double kHeroCardTitleHeight = 48.0;
const double kHeroCardGap = 16.0;


// ====== TopInfoRow (기간 전환 + 기간/시드 칩) ======
class TopInfoRow extends StatelessWidget {
  const TopInfoRow({
    super.key,
    required this.challengeType,
    required this.onChallengeTypeChanged,
    required this.challengeTypeText,
    this.seedText,
    this.showSeed = true,
    this.loading = false,
    this.error = false,
  });

  final ChallengeType challengeType;
  final ValueChanged<ChallengeType> onChallengeTypeChanged;
  final String challengeTypeText;
  final String? seedText;
  final bool showSeed;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isCompact = c.maxWidth < 640;

        final seg = RecordPeriodSwitcher(
          selected: challengeType,
          onChanged: onChallengeTypeChanged,
          loading: loading,
          error:   error,
        );
        final chips = RecordInfoChips(
          challengeText: challengeTypeText,
          seedText: seedText,
          showSeed: showSeed,
          loading: loading,
          error:   error,
        );

        if (!isCompact) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              seg,
              Gaps.w12,
              Flexible(child: chips),
            ],
          );
        }

        // 좁은 화면: 1줄 = Segmented, 2줄 = [기간][시드]를 "같은 줄" + 가로 스크롤
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            seg,
            Gaps.h8,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: [chips]),
            ),
          ],
        );
      },
    );
  }
}


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
            imageAspect: kHeroCardAspect, // 기존 상수 계속 사용
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
            imageAspect: kHeroCardAspect,
            badgeText: loc.record_badge_target,
            loading: loading,
            error: error,
          ),
        ),
      ],
    );
  }
}


class HeroCardsSkeleton extends StatelessWidget {
  const HeroCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final cardBg = t.resources.cardBackgroundFillColorDefault;
    final imageBg = t.micaBackgroundColor.withAlpha(40);

    Widget skeletonCard() => Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 실제 카드와 동일한 비율의 이미지 영역
          AspectRatio(
            aspectRatio: kHeroCardAspect,
            child: Container(
              color: imageBg,
              // 필요하면 안쪽에 더 옅은 바(로딩 느낌) 레이어를 깔아도 됨
            ),
          ),
          // 실제 카드와 동일한 타이틀 높이
          Container(
            height: kHeroCardTitleHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.resources.cardBackgroundFillColorSecondary, // 살짝 대비
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(child: skeletonCard()),
        const SizedBox(width: kHeroCardGap),
        Expanded(child: skeletonCard()),
      ],
    );
  }
}

class GoalEmpty extends StatelessWidget {
  const GoalEmpty({
    super.key,
    required this.type,
    required this.rangeText,
  });

  final ChallengeType type;   // daily / weekly
  final String rangeText;     // “YYYY년 MM월 DD일” 또는 “YYYY년 nn주차”, 범위 등

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final fill = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    final title = switch (type) {
      ChallengeType.daily  => '해당 날짜의 일간 목표가 없습니다.',
      ChallengeType.weekly => '해당 기간의 주간 목표가 없습니다.',
    };

    final subtitle = '선택된 기간: $rangeText';

    return Container(
      height: 120,
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
          Gaps.w4,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Gaps.h4,
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RankingEmptyPanelPast extends StatelessWidget {
  const RankingEmptyPanelPast({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final fill = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    return SizedBox( // ⟵ 고정 높이 적용 (스켈레톤과 동일)
      height: kRightPanelPlaceholderHeight,
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
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // ⟵ 세로 중앙 정렬
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('해당 기간의 기록이 없습니다.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('다른 날짜로 이동해 보세요.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankingSkeleton extends StatelessWidget {
  const RankingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final fill = t.resources.cardBackgroundFillColorDefault;
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    Widget bar(double w, double h, [double r = 12]) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: stroke, width: .8),
      ),
    );

    return SizedBox( // ⟵ 고정 높이 적용
      height: kRightPanelPlaceholderHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: bar(520, 72),
            ),
          ),
          Row(children: [
            Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: bar(double.infinity, 60),
            )),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: bar(double.infinity, 60),
            )),
          ]),
          Gaps.h12,
          for (int i = 0; i < 4; i++) ...[
            bar(double.infinity, 52),
            Gaps.h8,
          ],
        ],
      ),
    );
  }
}


class Podium extends StatelessWidget {
  const Podium({super.key, required this.entries, required this.isAdmin});
  final List<LeaderboardEntry> entries; // 상위 3개 기대
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final first  = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third  = entries.length > 2 ? entries[2] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (first != null) ...[
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: PodiumTile(rank: 1, entry: first, big: true, isAdmin: isAdmin, centered: true),
            ),
          ),
          Gaps.h12,
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: second == null ? const SizedBox.shrink() : PodiumTile(rank: 2, entry: second, isAdmin: isAdmin),
            )),
            Gaps.w12,
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: third == null ? const SizedBox.shrink() : PodiumTile(rank: 3, entry: third, isAdmin: isAdmin),
            )),
          ],
        ),
      ],
    );
  }
}

class PodiumTile extends StatelessWidget {
  const PodiumTile({
    super.key,
    required this.rank,
    required this.entry,
    this.big = false,
    required this.isAdmin,
    this.centered = false,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool big;
  final bool isAdmin;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final bg = t.resources.cardBackgroundFillColorDefault;

    final badgeColor = switch (rank) {
      1 => t.accentColor,
      2 => Colors.grey,
      3 => Colors.orange,
      _ => t.resources.textFillColorSecondary,
    };

    final name = Text(
      entry.nickname,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );

    final time = (isAdmin && entry.clearTime != null)
        ? Text(
      getTimeString(entry.clearTime!),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(color: t.resources.textFillColorSecondary, fontSize: 12),
    )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke, width: .8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: big ? 18 : 12),
      child: Row(
        children: [
          Container(
            width: big ? 36 : 28,
            height: big ? 36 : 28,
            decoration: BoxDecoration(color: badgeColor.withAlpha(80), shape: BoxShape.circle),
            child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: big ? 18 : 14))),
          ),
          Gaps.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                name,
                if (time != null) ...[Gaps.h2, time],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 스켈레톤 스위처 (최소 노출 시간)
class LazySwitcher extends StatefulWidget {
  const LazySwitcher({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.child,
    this.empty,
    this.minSkeleton = const Duration(milliseconds: 400),
    this.fade = const Duration(milliseconds: 180),
  });

  final bool loading;
  final Widget skeleton;
  final Widget child;
  final Widget? empty;
  final Duration minSkeleton;
  final Duration fade;

  @override
  State<LazySwitcher> createState() => _LazySwitcherState();
}

class _LazySwitcherState extends State<LazySwitcher> {
  bool _showSkeleton = false;
  DateTime? _start;

  @override
  void initState() { super.initState(); _maybeStartSkeleton(); }
  @override
  void didUpdateWidget(covariant LazySwitcher oldWidget) { super.didUpdateWidget(oldWidget); _maybeStartSkeleton(); }

  void _maybeStartSkeleton() {
    if (widget.loading) {
      _start = DateTime.now();
      if (!_showSkeleton) setState(() => _showSkeleton = true);
    } else if (_showSkeleton) {
      final spent = DateTime.now().difference(_start ?? DateTime.now());
      final remain = widget.minSkeleton - spent;
      if (remain.isNegative) {
        setState(() => _showSkeleton = false);
      } else {
        Future.delayed(remain, () { if (mounted) setState(() => _showSkeleton = false); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSkeleton = widget.loading || _showSkeleton;
    final body = showSkeleton ? widget.skeleton
        : (widget.child is SizedBox && (widget.child as SizedBox).height == 0)
        ? (widget.empty ?? const SizedBox.shrink())
        : widget.child;

    return AnimatedSwitcher(
      duration: widget.fade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: body,
    );
  }
}

