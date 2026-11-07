import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/providers/quiz_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<void> showQuizPlayOptionsDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);

  return showAppDialog<void>(
    context: context,
    builder: (context) => AppDialog(
      title: Text(loc.quiz_play_options),
      constraints: const BoxConstraints(maxWidth: 480),
      content: Consumer(
        builder: (context, ref, _) {
          final quiz = ref.watch(quizProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLabeled(
                label: loc.quiz_time_limit_label,
                child: AppNumberField(
                  value: quiz.timeLimit,
                  min: 5,
                  max: 600,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(quizProvider).setTimeLimit(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppLabeled(
                label: loc.quiz_auto_advance_wait_label,
                child: AppNumberField(
                  value: quiz.autoAdvanceSeconds,
                  min: 1,
                  max: 60,
                  onChanged: quiz.autoAdvance
                      ? (value) {
                          if (value != null) {
                            ref.read(quizProvider).setAutoAdvanceSeconds(value);
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              AppLabeled(
                label:
                    '${loc.quiz_font_scale_label} (${quiz.questionFontScale.toStringAsFixed(1)}x)',
                child: Slider(
                  value: quiz.questionFontScale * 100,
                  min: 80,
                  max: 200,
                  divisions: 12,
                  onChanged: (value) =>
                      ref.read(quizProvider).setQuestionFontScale(value / 100),
                ),
              ),
              const SizedBox(height: 16),
              AppLabeled(
                label: loc.quiz_text_align_label,
                child: _TextAlignSelector(
                  value: quiz.questionTextAlign,
                  onChanged: (value) =>
                      ref.read(quizProvider).setQuestionTextAlign(value),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        AppButton.primary(
          child: Text(loc.quiz_confirm),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class _TextAlignSelector extends StatelessWidget {
  const _TextAlignSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final options = [
      ('left', PhosphorIconsRegular.textAlignLeft, loc.quiz_align_left),
      ('center', PhosphorIconsRegular.textAlignCenter, loc.quiz_align_center),
      ('right', PhosphorIconsRegular.textAlignRight, loc.quiz_align_right),
    ];

    return Row(
      children: [
        for (final option in options) ...[
          AppToggleButton(
            checked: value == option.$1,
            onChanged: (_) => onChanged(option.$1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(option.$2, size: 16),
                const SizedBox(width: 6),
                Text(option.$3),
              ],
            ),
          ),
          if (option != options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
