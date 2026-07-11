import 'dart:async';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz.dart';
import 'package:fluent_ui/fluent_ui.dart';

class QuizEditorCard extends StatefulWidget {
  const QuizEditorCard({
    super.key,
    required this.index,
    required this.quiz,
    required this.onChanged,
    required this.onDelete,
    this.autofocus = false,
  });

  final int index;
  final Quiz quiz;
  final ValueChanged<Quiz> onChanged;
  final VoidCallback onDelete;
  final bool autofocus;

  @override
  State<QuizEditorCard> createState() => _QuizEditorCardState();
}

class _QuizEditorCardState extends State<QuizEditorCard> {
  late final TextEditingController _questionController;
  late final List<TextEditingController> _choiceControllers;
  final _questionFocus = FocusNode();

  Timer? _debounce;
  late int _answerIndex;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.quiz.question);
    _choiceControllers = List.generate(
      5,
      (i) => TextEditingController(
        text: i < widget.quiz.choices.length ? widget.quiz.choices[i] : '',
      ),
    );
    _answerIndex = widget.quiz.answerIndex;

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _questionFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _questionController.dispose();
    for (final c in _choiceControllers) {
      c.dispose();
    }
    _questionFocus.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _commit);
  }

  void _commit() {
    widget.onChanged(Quiz(
      id: widget.quiz.id,
      question: _questionController.text,
      choices: _choiceControllers.map((c) => c.text).toList(),
      answerIndex: _answerIndex,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typography = FluentTheme.of(context).typography;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${widget.index + 1}', style: typography.bodyStrong),
              const SizedBox(width: 8),
              Expanded(
                child: TextBox(
                  controller: _questionController,
                  focusNode: _questionFocus,
                  placeholder: loc.quiz_question_hint,
                  onChanged: (_) => _scheduleSave(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.quiz_answer_label, style: typography.caption),
          const SizedBox(height: 4),
          ...List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  RadioButton(
                    checked: _answerIndex == i,
                    onChanged: (checked) {
                      if (checked) {
                        setState(() => _answerIndex = i);
                        _scheduleSave();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextBox(
                      controller: _choiceControllers[i],
                      placeholder: '${loc.quiz_choice_hint} ${i + 1}',
                      onChanged: (_) => _scheduleSave(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
