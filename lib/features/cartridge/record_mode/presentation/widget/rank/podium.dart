import 'package:cartridge/features/cartridge/record_mode/presentation/controllers/record_mode_detail_page_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/record_mode/domain/models/leaderboard_entry.dart';
import 'package:cartridge/theme/theme.dart';

const bool showClearTime = true;

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