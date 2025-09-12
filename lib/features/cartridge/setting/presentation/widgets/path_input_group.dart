import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class PathInputGroup extends StatelessWidget {
  const PathInputGroup({
    super.key,
    required this.isFile,
    required this.auto,
    required this.controller,
    required this.placeholder,
    required this.onModeChanged,
    required this.onPick,
    required this.onDetect,
    required this.pickLabel,
    this.isBusy = false,
  });

  final bool isFile;
  final bool auto;
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onPick;
  final VoidCallback onDetect;
  final String pickLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) 모드 선택
        Wrap(
          spacing: 24,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              RadioButton(checked: auto, onChanged: (_) => onModeChanged(true)),
              Gaps.w6, Text(loc.path_mode_auto, style: AppTypography.body),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              RadioButton(checked: !auto, onChanged: (_) => onModeChanged(false)),
              Gaps.w6, Text(loc.path_mode_manual, style: AppTypography.body),
            ]),
          ],
        ),
        Gaps.h8,

        // 2) 입력 필드만 단독 행
        Row(
          children: [
            Expanded(
              child: auto
                  ? TextFormBox(controller: controller, enabled: false, readOnly: true, placeholder: placeholder)
                  : _PickableTextBox(
                controller: controller,
                placeholder: placeholder,
                onPick: onPick,
                validator: (t) {
                  final v = (t ?? '').trim();
                  if (v.isEmpty) return loc.setting_validate_required;
                  return null;
                },
              ),
            ),
          ],
        ),

        // 3) 직접 지정 모드일 때만 액션
        if (!auto) ...[
          Gaps.h8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: isBusy ? null : onPick,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isFile ? FluentIcons.open_file : FluentIcons.open_folder_horizontal),
                  Gaps.w6, Text(pickLabel),
                ]),
              ),
              Tooltip(
                message: loc.path_detect_fill_tooltip,
                child: Button(
                  onPressed: isBusy ? null : onDetect,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(FluentIcons.search),
                    Gaps.w6,
                    Text(loc.path_detect_fill_button),
                  ]),
                ),
              ),
              Gaps.w6,
              SizedBox(
                width: 16, height: 16,
                child: isBusy ? const ProgressRing(strokeWidth: 2) : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// 내부 전용: 클릭으로 파일/폴더 선택
class _PickableTextBox extends StatelessWidget {
  const _PickableTextBox({
    required this.controller,
    required this.placeholder,
    required this.onPick,
    this.validator,
  });

  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onPick;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextFormBox(controller: controller, readOnly: true, placeholder: placeholder, validator: validator),
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onPick),
        ),
      ],
    );
  }
}
