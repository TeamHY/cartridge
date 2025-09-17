import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options_schema.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

const quickSizes = <(int, int)>[
  (960, 540), (1280, 720), (1600, 900), (1920, 1080),
];

class OptionPresetBasicSection extends StatelessWidget {
  const OptionPresetBasicSection({
    super.key,
    required this.nameCtl,
    required this.widthCtl,
    required this.heightCtl,
    required this.xCtl,
    required this.yCtl,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.onApplyQuickSize,
    required this.onAnyChanged,
  });

  final TextEditingController nameCtl, widthCtl, heightCtl, xCtl, yCtl;
  final bool isFullscreen;
  final ValueChanged<bool> onToggleFullscreen;
  final ValueChanged<(int, int)> onApplyQuickSize;
  final VoidCallback onAnyChanged;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    String? req(String? v) => (v == null || v.trim().isEmpty) ? loc.option_window_error_name_required : null;

    String? validateSize(String? t, String rangeMsg) {
      if (isFullscreen) return null; // 전체화면일 땐 검증 제외
      final v = int.tryParse((t ?? '').trim());
      if (v == null) return rangeMsg;
      if (v < IsaacOptionsSchema.winMin || v > IsaacOptionsSchema.winMax) return rangeMsg;
      return null;
    }

    String? validatePos(String? t, String rangeMsg) {
      if (isFullscreen) return null;
      final v = int.tryParse((t ?? '').trim());
      if (v == null) return rangeMsg;
      if (v < IsaacOptionsSchema.posMin || v > IsaacOptionsSchema.posMax) return rangeMsg;
      return null;
    }

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

    Widget chipButton(String label, VoidCallback onPressed) => Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
        backgroundColor: WidgetStateProperty.all(
          fTheme.accentColor.withAlpha(fTheme.brightness == Brightness.dark ? 128 : 80),
        ),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: AppShapes.pill)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );

    Widget disableIfFullscreen(Widget child) {
      if (!isFullscreen) return child;
      return Opacity(opacity: 0.5, child: IgnorePointer(ignoring: true, child: child));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(loc.option_name_label),
        TextFormBox(
          controller: nameCtl,
          placeholder: loc.option_preset_fallback_name,
          validator: (v) => req(v),
          onChanged: (_) => onAnyChanged(),
        ),
        Gaps.h12,

        sectionLabel(loc.option_window_fullscreen),
        ToggleSwitch(
          checked: isFullscreen,
          onChanged: onToggleFullscreen,
          content: Text(isFullscreen ? loc.common_on : loc.common_off),
        ),
        Gaps.h12,

        sectionLabel(loc.option_window_resolution_recommend),
        disableIfFullscreen(
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final s in quickSizes)
                chipButton('${s.$1} × ${s.$2}', () {
                  onApplyQuickSize(s);
                }),
            ],
          ),
        ),
        Gaps.h12,

        sectionLabel(loc.option_window_size_title),
        disableIfFullscreen(
          Row(
            children: [
              Expanded(
                child: TextFormBox(
                  controller: widthCtl,
                  placeholder: loc.option_window_width_label,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => validateSize(v, loc.option_window_error_width_range),
                  onChanged: (_) => onAnyChanged(),
                ),
              ),
              Gaps.w8,
              Expanded(
                child: TextFormBox(
                  controller: heightCtl,
                  placeholder: loc.option_window_height_label,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => validateSize(v, loc.option_window_error_height_range),
                  onChanged: (_) => onAnyChanged(),
                ),
              ),
            ],
          ),
        ),
        Gaps.h12,

        sectionLabel(loc.option_window_position_title),
        disableIfFullscreen(
          Row(
            children: [
              Expanded(
                child: TextFormBox(
                  controller: xCtl,
                  placeholder: loc.option_window_pos_x_label,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d+'))],
                  validator: (v) => validatePos(v, loc.option_window_error_posx_range),
                  onChanged: (_) => onAnyChanged(),
                ),
              ),
              Gaps.w8,
              Expanded(
                child: TextFormBox(
                  controller: yCtl,
                  placeholder: loc.option_window_pos_y_label,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d+'))],
                  validator: (v) => validatePos(v, loc.option_window_error_posy_range),
                  onChanged: (_) => onAnyChanged(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
