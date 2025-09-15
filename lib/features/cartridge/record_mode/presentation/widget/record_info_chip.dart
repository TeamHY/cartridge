import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 레코드 상단 정보 칩(기간, 시드)
/// - 테마: theme.md에 맞춰 FluentTheme 리소스만 사용
/// - 다국어: 툴팁/비어있음 문구 AppLocalizations
/// - 로딩/에러: 고정 높이 스켈레톤/간단한 대체 텍스트로 레이아웃 유지
class RecordInfoChip extends StatelessWidget {
  const RecordInfoChip({
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

    // 에러: 동일 레이아웃 유지 + 부드러운 대체 문구
    final showSeedPill = showSeed && (seedText?.isNotEmpty ?? false);
    final seedEmptyText = loc.record_chip_seed_empty;

    return ConstrainedBox(
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
            Icon(FluentIcons.map_pin, size: 14),
            Gaps.w6,
            Text(showSeedPill ? seedText! : seedEmptyText, softWrap: false),
          ],
        ),
      ),
    );
  }
}
