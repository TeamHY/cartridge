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
const bool showClearTime = true;

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

class Podium extends StatelessWidget {
  const Podium({
    super.key,
    required this.entries,
    required this.isAdmin,
    this.height = 180,
    this.loading = false,
  });

  final List<LeaderboardEntry> entries;
  final bool isAdmin;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final first  = loading ? null : (entries.isNotEmpty ? entries[0] : null);
    final second = loading ? null : (entries.length > 1 ? entries[1] : null);
    final third  = loading ? null : (entries.length > 2 ? entries[2] : null);

    const h1 = 1.00, h2 = .72, h3 = .72;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _Pedestal(entry: second, rank: 2, factor: h2, isAdmin: showClearTime | isAdmin, loading: loading)),
          const SizedBox(width: 12),
          Expanded(child: _Pedestal(entry: first,  rank: 1, factor: h1, isAdmin: showClearTime | isAdmin, loading: loading)),
          const SizedBox(width: 12),
          Expanded(child: _Pedestal(entry: third,  rank: 3, factor: h3, isAdmin: showClearTime | isAdmin, loading: loading)),
        ],
      ),
    );
  }
}


class _Pedestal extends StatelessWidget {
  const _Pedestal({
    required this.entry,
    required this.rank,
    required this.factor,
    required this.isAdmin,
    this.loading = false,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double factor;
  final bool isAdmin;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final textSecondary = t.resources.textFillColorSecondary;
    final barBg = t.resources.cardBackgroundFillColorSecondary;

    final style = _MedalStyle.of(rank, t.brightness);

    return LayoutBuilder(
      builder: (context, c) {
        final colH = (c.maxHeight * factor).clamp(120.0, c.maxHeight);
        final medalSize = rank == 1 ? 48.0 : 40.0;

        return SizedBox(
          height: colH,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 메달 (크기/위치 동일)
              Positioned(
                top: 0,
                child: loading
                    ? Container(
                  width: medalSize, height: medalSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: barBg,
                    border: Border.all(color: t.resources.controlStrokeColorSecondary.withAlpha(48), width: .8),
                  ),
                )
                    : _MedalChip(rank: rank, style: style),
              ),
              // 기둥(닉네임/타임/포인트 바) — 동일 배치
              Positioned.fill(
                top: rank == 1 ? 60 : 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 닉네임 자리
                    loading
                        ? Container(
                      height: 14, width: rank == 1 ? 120 : 100,
                      decoration: BoxDecoration(color: barBg, borderRadius: BorderRadius.circular(6)),
                    )
                        : Text(
                      entry?.nickname ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: rank == 1 ? 17 : 15, fontWeight: FontWeight.w800),
                    ),
                    // 클리어 타임 자리
                    if (loading) ...[
                      Gaps.h10,
                      Container(
                        height: 10, width: 80,
                        decoration: BoxDecoration(color: barBg, borderRadius: BorderRadius.circular(6)),
                      ),
                    ] else if (showClearTime | isAdmin && entry?.clearTime != null) ...[
                      Gaps.h10,
                      Text(
                        getTimeString(entry!.clearTime!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    Gaps.h6,
                    // 포인트 바
                    Container(
                      height: 4, width: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: loading ? null : LinearGradient(colors: style.accentBar),
                        color: loading ? barBg : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MedalChip extends StatelessWidget {
  const _MedalChip({required this.rank, required this.style});
  final int rank;
  final _MedalStyle style;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final onAccent = t.resources.textOnAccentFillColorPrimary;

    final medalSize = rank == 1 ? 44.0 : 36.0;

    return Container(
      width: medalSize, height: medalSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: style.medalFill,
        ),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: rank == 1 ? 24 : 18,
            color: onAccent, // 메달 내부 대비 높은 텍스트
          ),
        ),
      ),
    );
  }
}

/// 금/은/동 스타일 세트
class _MedalStyle {
  final List<Color> medalFill;   // 칩 내부
  final List<Color> ringSweep;   // 칩 링(스윕)
  final List<Color> accentBar;   // 기둥 포인트 바
  final Color gloss;             // 상단 글로시
  final Color shadow;            // 칩 드롭쉐도
  final Color base;              // 메탈 베이스톤

  _MedalStyle({
    required this.medalFill,
    required this.ringSweep,
    required this.accentBar,
    required this.gloss,
    required this.shadow,
    required this.base,
  });

  // 기둥 그라디언트(테마 카드색 위에 메탈 하이라이트를 살짝 섞음)
  List<Color> pillarGradient(Color cardFill) {
    return [
      Color.alphaBlend(base.withAlpha(20), cardFill),
      cardFill,
      Color.alphaBlend(base.withAlpha(28), cardFill),
    ];
  }

  static _MedalStyle of(int rank, Brightness brightness) {
    // 메탈 베이스 컬러(톤은 테마 밝기에 살짝 보정)
    Color metal(int light, int dark) =>
        brightness == Brightness.dark ? Color(dark) : Color(light);

    // 금/은/동 베이스
    final gold   = metal(0xFFFACC15, 0xFFEAB308);
    final silver = metal(0xFFD1D5DB, 0xFF9CA3AF);
    final bronze = metal(0xFFB45309, 0xFF92400E);

    switch (rank) {
      case 1: return _MedalStyle(
        base: gold,
        medalFill: [gold.withAlpha(230), gold.withAlpha(200)],
        ringSweep: [
          gold.withAlpha(220), gold.withAlpha(120),
          gold.withAlpha(220), gold.withAlpha(120),
          gold.withAlpha(220),
        ],
        accentBar: [gold.withAlpha(220), gold.withAlpha(160)],
        gloss: Colors.white,
        shadow: Colors.black.withAlpha(90),
      );
      case 2: return _MedalStyle(
        base: silver,
        medalFill: [silver.withAlpha(230), silver.withAlpha(200)],
        ringSweep: [
          silver.withAlpha(220), silver.withAlpha(120),
          silver.withAlpha(220), silver.withAlpha(120),
          silver.withAlpha(220),
        ],
        accentBar: [silver.withAlpha(210), silver.withAlpha(150)],
        gloss: Colors.white,
        shadow: Colors.black.withAlpha(80),
      );
      default: return _MedalStyle(
        base: bronze,
        medalFill: [bronze.withAlpha(230), bronze.withAlpha(200)],
        ringSweep: [
          bronze.withAlpha(220), bronze.withAlpha(120),
          bronze.withAlpha(220), bronze.withAlpha(120),
          bronze.withAlpha(220),
        ],
        accentBar: [bronze.withAlpha(210), bronze.withAlpha(150)],
        gloss: Colors.white,
        shadow: Colors.black.withAlpha(70),
      );
    }
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

