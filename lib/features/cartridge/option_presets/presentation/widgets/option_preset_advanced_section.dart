import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class OptionPresetAdvancedSection extends StatelessWidget {
  const OptionPresetAdvancedSection({
    super.key,
    required this.initiallyExpanded,
    required this.onExpandedChanged,
    required this.gamma,
    required this.gammaCtl,
    required this.syncingGammaText,
    required this.onGammaSliderChanged,
    required this.onGammaTextChanged,
    required this.enableDebugConsole,
    required this.onToggleDebugConsole,
    required this.pauseOnFocusLost,
    required this.onTogglePauseOnFocusLost,
    required this.mouseControl,
    required this.onToggleMouseControl,
    required this.repentogonInstalled,
    required this.useRepentogon,
    required this.onToggleRepentogon,
  });

  final bool initiallyExpanded;
  final ValueChanged<bool> onExpandedChanged;

  final double gamma;
  final TextEditingController gammaCtl;
  final bool syncingGammaText;
  final ValueChanged<double> onGammaSliderChanged;
  final ValueChanged<String> onGammaTextChanged;

  final bool enableDebugConsole;
  final ValueChanged<bool> onToggleDebugConsole;
  final bool pauseOnFocusLost;
  final ValueChanged<bool> onTogglePauseOnFocusLost;
  final bool mouseControl;
  final ValueChanged<bool> onToggleMouseControl;

  final bool repentogonInstalled;
  final bool useRepentogon;
  final ValueChanged<bool> onToggleRepentogon;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: AppTypography.bodyStrong),
    );

    return Expander(
      key: ValueKey<bool>(initiallyExpanded),
      initiallyExpanded: initiallyExpanded,
      onStateChanged: onExpandedChanged,
      headerBackgroundColor: WidgetStateProperty.all(fTheme.cardColor),
      contentBackgroundColor: fTheme.cardColor,
      header: Text(loc.option_advanced_title, style: AppTypography.sectionTitle,),
      headerShape: (isOpen) {
        if (isOpen) {
          return RoundedRectangleBorder(
            side: BorderSide(color: fTheme.dividerColor),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
            ),
          );
        } else {
          return RoundedRectangleBorder(
            side: BorderSide(color: fTheme.dividerColor),
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          );
        }
      },
      contentShape: (_) => RoundedRectangleBorder(
        side: BorderSide(color: fTheme.dividerColor),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gamma
          sectionLabel(loc.option_gamma_label),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: gamma,
                  min: 0.5, max: 3.5,
                  onChanged: onGammaSliderChanged,
                ),
              ),
              Gaps.w8,
              SizedBox(
                width: 56,
                child: TextBox(
                  placeholder: '1.0',
                  controller: gammaCtl,
                  inputFormatters: const [],
                  onChanged: onGammaTextChanged,
                ),
              ),
            ],
          ),
          Gaps.h12,

          // Gameplay/System
          sectionLabel(loc.option_gameplay_title),
          Wrap(
            spacing: 12, runSpacing: 8,
            children: [
              ToggleSwitch(
                checked: enableDebugConsole,
                onChanged: onToggleDebugConsole,
                content: Text(loc.option_debug_console_label),
              ),
              ToggleSwitch(
                checked: pauseOnFocusLost,
                onChanged: onTogglePauseOnFocusLost,
                content: Text(loc.option_pause_on_focus_lost_label),
              ),
              ToggleSwitch(
                checked: mouseControl,
                onChanged: onToggleMouseControl,
                content: Text(loc.option_mouse_control_label),
              ),
            ],
          ),
          Gaps.h12,

          if (repentogonInstalled) ...[
            const Divider(),
            sectionLabel(loc.option_repentogon_label),
            ToggleSwitch(
              checked: useRepentogon,
              onChanged: onToggleRepentogon,
              content: Text(loc.option_use_repentogon_label),
            ),
          ],
        ],
      ),
    );
  }
}
