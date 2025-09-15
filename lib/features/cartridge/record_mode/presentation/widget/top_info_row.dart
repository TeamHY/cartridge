import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

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

  bool get _disabled => loading || error;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = FluentTheme.of(context);
    final Color strokeColor = theme.resources.controlStrokeColorDefault;

    Widget buildBtn({
      required bool selected,
      required String label,
      required VoidCallback onTap,
      required BorderRadiusGeometry radius,
    }) {
      final style = ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            side: BorderSide(color: strokeColor),
            borderRadius: radius,
          ),
        ),
      );

      final child = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      return selected
          ? FilledButton(
        style: style,
        onPressed: _disabled ? null : onTap,
        child: child,
      )
          : Button(
        style: style,
        onPressed: _disabled ? null : onTap,
        child: child,
      );
    }

    final infoChip = RecordInfoChip(
      challengeText: challengeTypeText,
      seedText: seedText,
      showSeed: showSeed,
      loading: loading,
      error:   error,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 한 줄에: [일간 버튼][주간 버튼] | [정보 칩]
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 일간
            buildBtn(
              selected: challengeType == ChallengeType.daily,
              label: loc.record_daily_target,
              onTap: () {
                if (_disabled || challengeType == ChallengeType.daily) return;
                onChallengeTypeChanged(ChallengeType.daily);
              },
              radius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            // 주간
            buildBtn(
              selected: challengeType == ChallengeType.weekly,
              label: loc.record_weekly_target,
              onTap: () {
                if (_disabled || challengeType == ChallengeType.weekly) return;
                onChallengeTypeChanged(ChallengeType.weekly);
              },
              radius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),

            Gaps.w16,
            // 정보 칩
            Flexible(child: infoChip),
          ],
        ),
        Gaps.h8,
        Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(loc.record_top_info_subtitle),),
      ],
    );
  }
}
