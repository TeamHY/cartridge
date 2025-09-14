import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart' show getTimeString;
import 'package:cartridge/theme/theme.dart';

/// 현재 참가자 수 & 내 최고기록 표시 타일
/// - theme.md 준수(고정색 사용 금지)
/// - 로딩/에러: 동일 레이아웃 유지(간결한 문구만 노출, 에러 코드 숨김)
class LiveStatusTile extends StatelessWidget {
  const LiveStatusTile({
    super.key,
    required this.participants,
    required this.myBest,
    this.loading = false,
    this.error = false,
  });

  /// 참가자 수 (로딩/에러 시에도 값은 유지 가능)
  final int participants;

  /// 내 최고 기록(없으면 null)
  final Duration? myBest;

  /// 데이터 로딩 중
  final bool loading;

  /// 데이터 오류
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t   = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    final cardBg   = t.cardColor;
    final border   = t.resources.cardStrokeColorDefault;
    final divider  = t.resources.controlStrokeColorSecondary.withAlpha(40);
    final chipBg   = t.micaBackgroundColor.withAlpha(100);
    final textSub  = t.resources.textFillColorSecondary;
    final accent   = t.accentColor;

    // 왼쪽 원형 아이콘(참가자)
    Widget leading() => Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
      child: const Center(child: Icon(FluentIcons.group, size: 18)),
    );

    // 가운데 문구 (로딩/에러도 동일 위치/크기 유지)
    String centerText() {
      if (loading) return loc.live_status_loading;
      if (error)   return loc.live_status_error;
      // plural 처리
      return loc.live_status_participants(participants);
    }

    // 오른쪽 정보(아이콘 + 텍스트) — 상태별로 문구만 바뀌고 레이아웃은 동일
    IconData rightIcon() {
      if (error)   return FluentIcons.info;
      if (myBest != null) return FluentIcons.trophy;
      return FluentIcons.play;
    }

    Color rightIconColor() {
      if (error)       return textSub;
      if (myBest != null) return accent;
      return textSub;
    }

    String? rightText() {
      if (loading) return null; // 로딩 땐 아이콘만으로 간결하게
      if (error)   return loc.live_status_error; // 에러 문구 간단히
      if (myBest != null) return loc.live_status_my_best(getTimeString(myBest!));
      return loc.live_status_not_participated;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: .8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          leading(),
          Gaps.w12,
          // 가운데: 참가자 텍스트
          Expanded(
            child: Text(
              centerText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // 가운데 가는 구분선(상태와 무관)
          Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 12), color: divider),
          // 오른쪽: 상태별 정보(아이콘 + 텍스트)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(rightIcon(), size: 16, color: rightIconColor()),
              if (rightText() != null) ...[
                Gaps.w8,
                Text(
                  rightText()!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: (myBest != null) ? null : textSub, // 기록 없거나 에러일 땐 보조 컬러
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
