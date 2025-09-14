import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 레코드 상단 정보 칩(기간, 시드)
/// - 테마: theme.md에 맞춰 FluentTheme 리소스만 사용
/// - 다국어: 툴팁/비어있음 문구 AppLocalizations
/// - 로딩/에러: 고정 높이 스켈레톤/간단한 대체 텍스트로 레이아웃 유지
class RecordInfoChips extends StatelessWidget {
  const RecordInfoChips({
    super.key,
    required this.challengeText,
    this.seedText,
    this.showSeed = true,
    this.loading = false,
    this.error = false,
  });

  final String challengeText;
  final String? seedText;
  final bool showSeed;
  final bool loading;
  final bool error;

  static const double _kHeight = 28;

  @override
  Widget build(BuildContext context) {
    final t   = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final stroke = t.resources.controlStrokeColorSecondary.withAlpha(32);
    final fill   = t.resources.cardBackgroundFillColorDefault;
    final fill2  = t.resources.cardBackgroundFillColorSecondary;

    // 스켈레톤(로딩): Segmented와 같은 라운드/보더 체계로 단순 막대 형태
    if (loading) {
      Widget skel(double w) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: _kHeight, minWidth: w),
        child: Container(
          height: _kHeight,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppShapes.pill,
            border: Border.all(color: stroke, width: .8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 자리
              Container(width: 14, height: 14, decoration: BoxDecoration(
                color: fill2, shape: BoxShape.circle,
              )),
              const SizedBox(width: 6),
              // 텍스트 자리
              Container(width: 72, height: 12, decoration: BoxDecoration(
                color: fill2, borderRadius: BorderRadius.circular(6),
              )),
            ],
          ),
        ),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          skel(112), Gaps.w8,
          if (showSeed) skel(120),
        ],
      );
    }

    // 에러: 동일 레이아웃 유지 + 부드러운 대체 문구
    final showSeedPill = showSeed && (seedText?.isNotEmpty ?? false);
    final periodTooltip = loc.record_chip_period_tooltip;      // "기간"
    final seedTooltip   = loc.record_chip_seed_tooltip;        // "시드"
    final seedEmptyText = loc.record_chip_seed_empty;          // "시드 없음"
    final unavailable   = loc.record_chip_unavailable;         // "지금은 확인할 수 없어요"

    Widget pill({required IconData icon, required String text, String? tooltip}) {
      final content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _kHeight),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppShapes.pill,
            border: Border.all(color: stroke, width: .8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              Gaps.w6,
              Text(text, softWrap: false),
            ],
          ),
        ),
      );
      return (tooltip == null || tooltip.isEmpty)
          ? content
          : Tooltip(message: tooltip, child: content);
    }

    if (error) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(icon: FluentIcons.date_time2, text: unavailable, tooltip: periodTooltip),
          if (showSeed) ...[
            Gaps.w8,
            pill(icon: FluentIcons.map_pin, text: unavailable, tooltip: seedTooltip),
          ],
        ],
      );
    }

    // 정상 상태
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill(
          icon: FluentIcons.date_time2,
          text: challengeText,
          tooltip: periodTooltip,
        ),
        if (showSeed) ...[
          Gaps.w8,
          pill(
            icon: FluentIcons.map_pin,
            text: showSeedPill ? seedText! : seedEmptyText,
            tooltip: seedTooltip,
          ),
        ],
      ],
    );
  }
}
