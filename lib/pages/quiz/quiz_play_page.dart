import 'dart:async';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz.dart';
import 'package:cartridge/pages/record/components/back_arrow_view.dart';
import 'package:cartridge/providers/quiz_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PlayQuestion {
  _PlayQuestion({
    required this.question,
    required this.choices,
    required this.answerIndex,
  });

  final String question;
  final List<String> choices;
  final int answerIndex;
}

class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  late final List<Quiz> _pool;
  late final int _timeLimit;
  late final int _questionCount;
  List<_PlayQuestion> _questions = [];

  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _revealed = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    final quiz = ref.read(quizProvider);
    _timeLimit = quiz.timeLimit;
    _questionCount = quiz.questionCount;
    final category = quiz.findCategory(widget.categoryId);

    _pool = (category?.quizzes ?? []).where((q) => q.isComplete).toList();
    _draw();

    if (_questions.isNotEmpty) {
      _startTimer();
    }
  }

  void _draw() {
    final shuffled = List<Quiz>.of(_pool)..shuffle();
    _questions = shuffled.take(_questionCount).map(_toPlayQuestion).toList();
  }

  _PlayQuestion _toPlayQuestion(Quiz quiz) {
    final answer = quiz.choices[quiz.answerIndex];
    final shuffled = List<String>.of(quiz.choices)..shuffle();
    return _PlayQuestion(
      question: quiz.question,
      choices: shuffled,
      answerIndex: shuffled.indexOf(answer),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        _reveal(null);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reveal(int? choiceIndex) {
    if (_revealed) return;
    _timer?.cancel();
    setState(() {
      _selected = choiceIndex;
      _revealed = true;
      if (choiceIndex != null &&
          choiceIndex == _questions[_index].answerIndex) {
        _correct++;
      }
    });
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      if (_questions.length == 1) {
        Navigator.pop(context);
        return;
      }
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
    _startTimer();
  }

  void _retry() {
    setState(() {
      _draw();
      _index = 0;
      _correct = 0;
      _selected = null;
      _revealed = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color? _choiceColor(int i) {
    if (!_revealed) return null;
    final answerIndex = _questions[_index].answerIndex;
    if (i == answerIndex) return Colors.green.lighter;
    if (i == _selected) return Colors.red.lighter;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typography = FluentTheme.of(context).typography;

    if (_questions.isEmpty) {
      return BackArrowView(
        child: Center(child: Text(loc.quiz_start_empty)),
      );
    }

    if (_index >= _questions.length) {
      return BackArrowView(
        controlColor: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.quiz_result_title, style: typography.title),
              const SizedBox(height: 16),
              Text(
                '$_correct / ${_questions.length} ${loc.quiz_score_suffix}',
                style: typography.subtitle,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Button(
                    onPressed: _retry,
                    child: Text(loc.quiz_retry),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.quiz_exit),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_index];

    return BackArrowView(
      controlColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '${_index + 1} / ${_questions.length}',
                  style: typography.bodyStrong,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(FluentIcons.timer),
                    const SizedBox(width: 6),
                    Text('$_remaining', style: typography.bodyStrong),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressBar(
              value: _remaining / _timeLimit * 100,
            ),
            const SizedBox(height: 24),
            Text(question.question, style: typography.subtitle),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: question.choices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: double.infinity,
                    child: Button(
                      style: ButtonStyle(
                        backgroundColor: _choiceColor(i) == null
                            ? null
                            : WidgetStatePropertyAll(_choiceColor(i)),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                      onPressed: _revealed ? null : () => _reveal(i),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          question.choices[i],
                          style: typography.body,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_revealed) ...[
              const SizedBox(height: 12),
              Text(
                _selected == question.answerIndex
                    ? loc.quiz_correct
                    : (_selected == null
                        ? loc.quiz_time_over
                        : loc.quiz_wrong),
                style: typography.bodyStrong,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _next,
                child: Text(
                  _index >= _questions.length - 1
                      ? (_questions.length == 1
                          ? loc.quiz_exit
                          : loc.quiz_finish)
                      : loc.quiz_next,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
