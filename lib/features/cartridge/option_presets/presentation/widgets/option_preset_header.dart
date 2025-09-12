import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class OptionPresetHeader extends ConsumerWidget {
  const OptionPresetHeader({
    super.key,
    required this.previewW,
    required this.previewH,
    required this.previewX,
    required this.previewY,
    required this.isFullscreen,
    required this.repentogonInstalled,
    required this.useRepentogon,
  });

  final int? previewW, previewH, previewX, previewY;
  final bool isFullscreen;
  final bool repentogonInstalled;
  final bool useRepentogon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final repColors = repentogonStatusOf(context, ref);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fTheme.accentColor.withAlpha(
                fTheme.brightness == Brightness.dark ? 128 : 80,
              ),
              borderRadius: AppShapes.pill,
            ),
            child: Text(
              isFullscreen
                  ? loc.option_window_fullscreen
                  : '${previewW ?? '-'} × ${previewH ??
                  '-'} • X:${previewX ??
                  '-'} Y:${previewY ?? '-'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (repentogonInstalled && useRepentogon) ...[
            Gaps.w8,
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: repColors.fg.withAlpha(
                  fTheme.brightness == Brightness.dark ? 128 : 80,
                ),
                borderRadius: AppShapes.pill,
              ),
              child: Text(loc.option_use_repentogon_label, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
