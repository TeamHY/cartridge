import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';

/// 일간/주간 전환 컨트롤(Fluent 전용)
/// - 선택된 항목은 FilledButton, 비선택은 기본 Button
class RecordPeriodSwitcher extends StatelessWidget {
  const RecordPeriodSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
    this.loading = false,
    this.error = false,
  });

  final ChallengeType selected;
  final ValueChanged<ChallengeType> onChanged;
  final bool loading;
  final bool error;

  bool get _disabled => loading || error;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const kHeight = 36.0;

    Widget buildBtn({
      required bool isSelected,
      required String label,
      required VoidCallback onTap,
      required BorderRadiusGeometry radius,
    }) {
      final child = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      final style = ButtonStyle(
        // 좌/우 버튼이 맞닿을 때 깔끔하게 보이도록 모서리 제어
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: radius),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
      );

      return SizedBox(
        height: kHeight,
        child: isSelected
            ? FilledButton(
          style: style,
          onPressed: _disabled ? null : onTap,
          child: child,
        )
            : Button(
          style: style,
          onPressed: _disabled ? null : onTap,
          child: child,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildBtn(
            isSelected: selected == ChallengeType.daily,
            label: loc.record_daily_target,
            onTap: () {
              if (selected != ChallengeType.daily) onChanged(ChallengeType.daily);
            },
            radius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
        ),
        Expanded(
          child: buildBtn(
            isSelected: selected == ChallengeType.weekly,
            label: loc.record_weekly_target,
            onTap: () {
              if (selected != ChallengeType.weekly) onChanged(ChallengeType.weekly);
            },
            radius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
