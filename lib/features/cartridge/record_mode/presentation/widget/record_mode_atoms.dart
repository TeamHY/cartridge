import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/scheduler.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/theme/theme.dart';

const double kRightPanelPlaceholderHeight = 400.0;
const double kHeroCardAspect = 148 / 125; // ≈ 1.184, 타겟 기준
const double kHeroCardTitleHeight = 48.0;
const double kHeroCardGap = 16.0;

// ====== 공용 섹션 카드 ======
Widget sectionCard(
    BuildContext context, {
      required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(14),
      EdgeInsetsGeometry? margin,
    }) {
  final theme = FluentTheme.of(context);
  return Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: theme.resources.cardBackgroundFillColorDefault,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.resources.controlStrokeColorSecondary.withAlpha(32),
      ),
    ),
    child: child,
  );
}

// ====== TopInfoRow (기간 전환 + 기간/시드 칩) ======
class TopInfoRow extends StatelessWidget {
  const TopInfoRow({
    super.key,
    required this.challengeType,
    required this.onChallengeTypeChanged,
    required this.challengeTypeText,
    this.seedText,
    this.showSeed = true,
  });

  final ChallengeType challengeType;
  final ValueChanged<ChallengeType> onChallengeTypeChanged;
  final String challengeTypeText;
  final String? seedText;
  final bool showSeed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isCompact = c.maxWidth < 640;

        final seg = material.SegmentedButton<ChallengeType>(
          segments: const [
            material.ButtonSegment(value: ChallengeType.daily,  label: Text('일간 목표')),
            material.ButtonSegment(value: ChallengeType.weekly, label: Text('주간 목표')),
          ],
          selected: {challengeType},
          onSelectionChanged: (s) => onChallengeTypeChanged(s.first),
        );

        final chips = _InfoChips(
          challengeTypeText: challengeTypeText,
          seedText: seedText,
          showSeed: showSeed,
        );

        if (!isCompact) {
          // 넓은 화면: 한 줄에 모두 배치
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              seg,
              Gaps.w12,
              Flexible(child: chips.challengeTypePill()), // 폭 부족 시만 살짝 줄어듦
              Gaps.w8,
              Flexible(child: chips.seedPill()),
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
              child: Row(
                children: [
                  chips.challengeTypePill(),
                  if (showSeed && (seedText?.isNotEmpty ?? false)) ...[
                    Gaps.w8,
                    chips.seedPill(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoChips {
  _InfoChips({
    required this.challengeTypeText,
    required this.seedText,
    required this.showSeed,
  });

  final String challengeTypeText;
  final String? seedText;
  final bool showSeed;

  Widget _pill(BuildContext context, IconData icon, String text) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final fill = t.resources.cardBackgroundFillColorDefault;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppShapes.pill,
          border: Border.all(color: stroke, width: .8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // ← 칩이 내용 길이만큼만 차지 (가로 스크롤 친화적)
          children: [
            Icon(icon, size: 14),
            Gaps.w6,
            // 가로 스크롤 안에서 잘리지 않도록 한 줄 고정 (필요시 끝까지 스크롤)
            Text(text, softWrap: false),
          ],
        ),
      ),
    );
  }

  Widget challengeTypePill() => Builder(
    builder: (ctx) => _pill(ctx, FluentIcons.date_time2, challengeTypeText),
  );

  Widget seedPill() => Builder(
    builder: (ctx) => (showSeed && (seedText?.isNotEmpty ?? false))
        ? _pill(ctx, FluentIcons.map_pin, seedText!)
        : const SizedBox.shrink(),
  );
}


// ====== 히어로 카드(캐릭터/타겟) ======
class GameItemCard extends StatelessWidget {
  const GameItemCard({
    super.key,
    required this.title,
    required this.imageAsset,
    this.imageAspect = kHeroCardAspect, // ⟵ 기본 비율 상수 사용
    this.badge,
  });

  final String title;
  final String imageAsset;
  final double imageAspect;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final cardBg = t.resources.cardBackgroundFillColorDefault;
    final imageBg = t.micaBackgroundColor.withAlpha(40);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: imageAspect,
            child: Container(
              color: imageBg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(), // 자리 보정 (스켈레톤과 동일 구조 유지용)
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(imageAsset, fit: BoxFit.contain),
                  ),
                  if (badge != null && badge!.isNotEmpty)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.accentColor.withAlpha(190),
                          borderRadius: AppShapes.pill,
                        ),
                        child: Text(badge!, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            height: kHeroCardTitleHeight, // ⟵ 공용 상수
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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
  });

  final String characterName;
  final String characterAsset;
  final String targetName;
  final String targetAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GameItemCard(
            title: characterName,
            imageAsset: characterAsset,
            imageAspect: kHeroCardAspect, // ⟵ 공용 상수
            badge: '캐릭터',
          ),
        ),
        const SizedBox(width: kHeroCardGap), // ⟵ 공용 상수
        Expanded(
          child: GameItemCard(
            title: targetName,
            imageAsset: targetAsset,
            imageAspect: kHeroCardAspect, // ⟵ 공용 상수
            badge: '타겟',
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

// ====== 타이머 ======
class Timer64 extends StatefulWidget {
  const Timer64({super.key, required this.session});
  final GameSessionService session;

  @override
  State<Timer64> createState() => _Timer64State();
}

class _Timer64State extends State<Timer64> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  StreamSubscription<Duration>? _sub;

  Duration _serverElapsed = Duration.zero;
  Duration _displayElapsed = Duration.zero;
  DateTime _lastSync = DateTime.now();
  bool _running = false;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((_) {
      if (!_running) return;
      final now = DateTime.now();
      final dt = now.difference(_lastSync);
      final newDisplay = _serverElapsed + dt;
      // 너무 자주 setState 하지 않도록 8ms 이상 차이 날 때만 갱신 (선택)
      if ((newDisplay - _displayElapsed).inMilliseconds >= 8) {
        setState(() => _displayElapsed = newDisplay);
      }
    });

    _bindStream();
  }

  void _bindStream() {
    _sub?.cancel();
    _sub = widget.session.elapsed().listen((d) {
      _serverElapsed = d;
      _lastSync = DateTime.now();
      _running = d > Duration.zero;

      // 즉시 반영(점프 프레임 방지)
      setState(() => _displayElapsed = d);

      // 프레임 틱 on/off
      if (_running) {
        if (!_ticker.isActive) _ticker.start();
      } else {
        if (_ticker.isActive) _ticker.stop();
      }
    });
  }

  @override
  void didUpdateWidget(covariant Timer64 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _bindStream();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          getTimeString(_displayElapsed),
          style: const TextStyle(
            fontSize: 64,
            fontFeatures: [FontFeature.tabularFigures()],
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

// 참가자/허용모드 플레이스홀더
class ParticipantsBanner extends StatelessWidget {
  const ParticipantsBanner({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final bg = t.micaBackgroundColor.withAlpha(100);
    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.resources.cardStrokeColorDefault, width: .8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: const Center(child: Icon(FluentIcons.group, size: 18)),
          ),
          Gaps.w12,
          Expanded(child: Text('현재 $count명 참가 중', style: const TextStyle(fontWeight: FontWeight.w600))),
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

class MyBestRecordBanner extends StatelessWidget {
  const MyBestRecordBanner({super.key, required this.time});
  final Duration time;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final bg = t.micaBackgroundColor.withAlpha(90);

    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.resources.cardStrokeColorDefault, width: .8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: const Center(child: Icon(FluentIcons.trophy, size: 18)),
          ),
          Gaps.w12,
          const Expanded(
            child: Text('내 최고기록', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          // getTimeString 은 기존에 사용하던 포맷터(이미 import 되어 있음)
          Text(getTimeString(time),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class LiveStatusTile extends StatelessWidget {
  const LiveStatusTile({
    super.key,
    required this.participants,
    required this.myBest,
  });

  final int participants;
  final Duration? myBest;

  @override
  Widget build(BuildContext context) {
    final t  = FluentTheme.of(context);
    final bg = t.micaBackgroundColor.withAlpha(100);

    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.resources.cardStrokeColorDefault, width: .8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // 왼쪽: 참가자 수
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: const Center(child: Icon(FluentIcons.group, size: 18)),
          ),
          Gaps.w12,
          Expanded(
            child: Text('현재 $participants명 참가 중',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),

          // 가운데 가는 구분선(옵션)
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: t.resources.controlStrokeColorSecondary.withAlpha(40),
          ),

          // 오른쪽: 내 최고기록 or 유도 멘트
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                myBest != null ? FluentIcons.trophy : FluentIcons.play,
                size: 16,
                color: myBest != null ? t.accentColor : t.resources.textFillColorSecondary,
              ),
              Gaps.w8,
              if (myBest != null)
                Text('내 최고기록: ${getTimeString(myBest!)}',
                    style: const TextStyle(fontWeight: FontWeight.w700))
              else
                const Text('아직 참여하시지 않았습니다',
                    style: TextStyle(color: Color(0xFF7A7A7A))),
            ],
          ),
        ],
      ),
    );
  }
}
