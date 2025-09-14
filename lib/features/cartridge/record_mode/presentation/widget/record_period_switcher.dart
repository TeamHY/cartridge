import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';

/// 레코드 페이지 상단의 일간/주간 전환 세그먼트 컨트롤.
/// - 테마: FluentTheme에서 파생(고정색 사용 X)
/// - 다국어: AppLocalizations 사용
/// - 로딩/에러: 레이아웃 유지(고정 높이), 상호작용 비활성화
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

  /// true면 스켈레톤 형태로 렌더링(클릭 비활성)
  final bool loading;

  /// true면 동일 레이아웃을 유지하면서 상호작용만 막음
  final bool error;

  bool get _disabled => loading || error;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Segmented 높이를 안정적으로 맞춰 레이아웃 불안정 방지
    const double kHeight = 36;

    // ── 실제 SegmentedButton ─────────────────────────────────────────────
    return SizedBox(
      height: kHeight,
      child: Center(
        child: material.SegmentedButton<ChallengeType>(
          style: material.ButtonStyle(

          ),
          segments: [
            material.ButtonSegment<ChallengeType>(
              value: ChallengeType.daily,
              label: Text(loc.record_daily_target),
              enabled: !_disabled,
            ),
            material.ButtonSegment<ChallengeType>(
              value: ChallengeType.weekly,
              label: Text(loc.record_weekly_target),
              enabled: !_disabled,
            ),
          ],
          selected: {selected},
          onSelectionChanged: (set) {
            if (_disabled) return;
            if (set.isNotEmpty) onChanged(set.first);
          },
        ),
      ),
    );
  }
}
