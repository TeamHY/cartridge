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

  final int participants;
  final Duration? myBest;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t   = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    final cardBg   = t.cardColor;
    final border   = t.resources.cardStrokeColorDefault;
    final chipBg   = t.micaBackgroundColor.withAlpha(100);
    final textSub  = t.resources.textFillColorSecondary;
    final accent   = t.accentColor;

    String centerText() {
      if (loading) return loc.live_status_loading;
      if (error)   return loc.live_status_error;
      return loc.live_status_participants(participants);
    }

    IconData rightIcon() {
      if (error)        return FluentIcons.info;
      if (myBest != null) return FluentIcons.trophy;
      return FluentIcons.play;
    }

    Color rightIconColor() {
      if (error)         return textSub;
      if (myBest != null) return accent;
      return textSub;
    }

    String? rightText() {
      if (loading) return null; // 로딩 땐 아이콘만
      if (error)   return loc.live_status_error;
      if (myBest != null) return loc.live_status_my_best(getTimeString(myBest!));
      return loc.live_status_not_participated;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final bounded = c.hasBoundedHeight;
        final h = c.maxHeight;

        // 높이에 따른 스케일 (대략적인 단계형)
        final roomy = bounded && h >= 120;
        final chipSize = roomy ? 40.0 : 32.0;
        final iconLead = roomy ? 20.0 : 18.0;
        final iconRight = roomy ? 18.0 : 16.0;
        final fontBody = roomy ? 16.0 : 14.0;
        final padV = roomy ? AppSpacing.md : AppSpacing.sm;

        Widget circleIcon(IconData icon, double size, Color? color) => Container(
          width: chipSize, height: chipSize,
          decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: size, color: color)),
        );

        final centerTextWidget = Text(
          centerText(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontBody),
        );

        final rightTextStr = rightText();
        final rightRow = Row(
          children: [
            circleIcon(rightIcon(), iconRight, rightIconColor()),
            if (rightTextStr != null) ...[
              Gaps.w12,
              Flexible(
                child: Text(
                  rightTextStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: fontBody,
                    color: (myBest != null) ? null : textSub,
                  ),
                ),
              ),
            ],
          ],
        );

        return Container(
          // 섹션이 높이를 주면 그 높이를 꽉 채움, 아니면 내용 높이만큼
          constraints: bounded
              ? const BoxConstraints(minHeight: double.infinity)
              : const BoxConstraints(),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: .8),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: padV),
          child: Column(
            mainAxisAlignment: bounded ? MainAxisAlignment.center : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  circleIcon(FluentIcons.group, iconLead, null),
                  Gaps.w12,
                  Expanded(child: centerTextWidget),
                ],
              ),
              rightRow,
            ],
          ),
        );
      },
    );
  }
}
