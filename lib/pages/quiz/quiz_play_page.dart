import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz.dart';
import 'package:cartridge/pages/record/components/back_arrow_view.dart';
import 'package:cartridge/providers/hotkey_provider.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/quiz_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PlayChoice {
  _PlayChoice({required this.text, required this.imagePath});

  final String text;
  final String? imagePath;
}

class _PlayQuestion {
  _PlayQuestion({
    required this.id,
    required this.categoryName,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.isOpenEnded,
    required this.imagePath,
    required this.openAnswer,
    required this.answerImagePath,
    required this.timeLimit,
    required this.difficulty,
  });

  final String id;
  final String categoryName;
  final String question;
  final List<_PlayChoice> choices;
  final int answerIndex;
  final bool isOpenEnded;
  final String? imagePath;
  final String openAnswer;
  final String? answerImagePath;
  final int? timeLimit;
  final int difficulty;
}

class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({super.key, this.categoryId});

  final String? categoryId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  late final List<List<Quiz>> _pools;
  late final Map<String, String> _categoryNames;
  late final int _defaultTimeLimit;
  late final int _questionCount;
  List<_PlayQuestion> _questions = [];

  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _revealed = false;
  bool _timeUp = false;
  bool _paused = false;
  int _remaining = 0;
  int _currentLimit = 1;
  Timer? _timer;
  final _openInputController = TextEditingController();

  List<String> _bgmPaths = [];
  AudioPlayer? _bgmPlayer;
  String? _correctSfxPath;
  String? _wrongSfxPath;
  late final HotkeyNotifier _hotkeyNotifier;

  void _judge(bool correct) {
    if (correct) {
      _correct++;
    }
    _playSfx(correct);
    _next();
  }

  void _playSfx(bool correct) {
    final path = correct ? _correctSfxPath : _wrongSfxPath;
    if (path == null) return;
    final volume = ref.read(quizProvider).bgmVolume;
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) => player.dispose());
    player.play(DeviceFileSource(path), volume: volume);
  }

  @override
  void initState() {
    super.initState();

    final quiz = ref.read(quizProvider);
    _defaultTimeLimit = quiz.timeLimit;
    _questionCount = quiz.questionCount;
    _categoryNames = {
      for (final category in quiz.categories)
        for (final q in category.quizzes) q.id: category.name,
    };

    if (widget.categoryId == null) {
      _pools = quiz.categories
          .map((c) => c.quizzes.where((q) => q.isComplete).toList())
          .where((pool) => pool.isNotEmpty)
          .toList();
    } else {
      final category = quiz.findCategory(widget.categoryId!);
      final pool =
          (category?.quizzes ?? []).where((q) => q.isComplete).toList();
      _pools = pool.isEmpty ? [] : [pool];
    }

    ref.read(musicPlayerProvider).pause();

    _draw();
    _initBgm(quiz.bgmPaths, quiz.bgmVolume);
    _correctSfxPath = _validSoundPath(quiz.correctSfxPath);
    _wrongSfxPath = _validSoundPath(quiz.wrongSfxPath);
    _registerHotkeyOverrides();

    if (_questions.isNotEmpty) {
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) => _markCurrentUsed());
    }
  }

  void _markCurrentUsed() {
    if (widget.categoryId != null) return;
    if (!mounted || _index >= _questions.length) return;
    ref.read(quizProvider).markQuizUsed(_questions[_index].id);
  }

  void _draw() {
    final rng = Random();
    final used = widget.categoryId == null
        ? ref.read(quizProvider).usedQuizIds
        : const <String>{};
    final pools = _pools
        .map((pool) => pool.where((q) => !used.contains(q.id)).toList())
        .where((pool) => pool.isNotEmpty)
        .toList();
    final result = <Quiz>[];

    while (result.length < _questionCount && pools.isNotEmpty) {
      final poolIndex = rng.nextInt(pools.length);
      final pool = pools[poolIndex];
      result.add(pool.removeAt(rng.nextInt(pool.length)));
      if (pool.isEmpty) {
        pools.removeAt(poolIndex);
      }
    }

    _questions = result.map(_toPlayQuestion).toList();
  }

  _PlayQuestion _toPlayQuestion(Quiz quiz) {
    if (quiz.isOpenEnded) {
      return _PlayQuestion(
        id: quiz.id,
        categoryName: _categoryNames[quiz.id] ?? '',
        question: quiz.question,
        choices: const [],
        answerIndex: -1,
        isOpenEnded: true,
        imagePath: quiz.imagePath,
        openAnswer: quiz.openAnswer.trim(),
        answerImagePath: quiz.answerImagePath,
        timeLimit: quiz.timeLimit,
        difficulty: quiz.difficulty,
      );
    }

    final choices = List<_PlayChoice>.generate(
      quiz.choices.length,
      (i) => _PlayChoice(
        text: quiz.choices[i],
        imagePath: i < quiz.choiceImages.length ? quiz.choiceImages[i] : null,
      ),
    );
    final answer = choices[quiz.answerIndex];
    choices.shuffle();
    return _PlayQuestion(
      id: quiz.id,
      categoryName: _categoryNames[quiz.id] ?? '',
      question: quiz.question,
      choices: choices,
      answerIndex: choices.indexOf(answer),
      isOpenEnded: false,
      imagePath: quiz.imagePath,
      openAnswer: '',
      answerImagePath: quiz.answerImagePath,
      timeLimit: quiz.timeLimit,
      difficulty: quiz.difficulty,
    );
  }

  String? _validSoundPath(String? path) =>
      path != null && File(path).existsSync() ? path : null;

  void _initBgm(List<String> paths, double volume) {
    _bgmPaths = paths.where((path) => File(path).existsSync()).toList();
    if (_bgmPaths.isEmpty) return;

    final player = AudioPlayer();
    _bgmPlayer = player;
    player.setReleaseMode(ReleaseMode.loop);
    player.setVolume(volume);

    if (_questions.isNotEmpty) {
      _playRandomBgm();
    }
  }

  void _playRandomBgm() {
    final player = _bgmPlayer;
    if (player == null || _bgmPaths.isEmpty) return;
    final path = _bgmPaths[Random().nextInt(_bgmPaths.length)];
    player.stop();
    player.play(DeviceFileSource(path));
  }

  void _registerHotkeyOverrides() {
    _hotkeyNotifier = ref.read(hotkeyProvider);
    _hotkeyNotifier.playPauseOverride = _togglePause;
    _hotkeyNotifier.volumeUpOverride = () => _adjustVolume(1);
    _hotkeyNotifier.volumeDownOverride = () => _adjustVolume(-1);
  }

  void _adjustVolume(int direction) {
    final step = ref.read(settingProvider).volumeStepSize;
    final volume = (ref.read(quizProvider).bgmVolume + direction * step)
        .clamp(0.0, 1.0);
    _setVolume(volume);
  }

  void _setVolume(double volume) {
    ref.read(quizProvider).setBgmVolume(volume);
    _bgmPlayer?.setVolume(volume);
  }

  void _startTimer() {
    _timer?.cancel();
    _paused = false;
    _timeUp = false;
    _currentLimit = _questions[_index].timeLimit ?? _defaultTimeLimit;
    _remaining = _currentLimit;
    _bgmPlayer?.resume();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused) return;
      if (_remaining <= 1) {
        timer.cancel();
        _bgmPlayer?.pause();
        setState(() {
          _remaining = 0;
          _timeUp = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _togglePause() {
    if (!mounted ||
        _revealed ||
        _timeUp ||
        _questions.isEmpty ||
        _index >= _questions.length) {
      return;
    }
    setState(() => _paused = !_paused);
    if (_paused) {
      _bgmPlayer?.pause();
    } else {
      _bgmPlayer?.resume();
    }
  }

  void _selectChoice(int choiceIndex) {
    if (_revealed) return;
    setState(() => _selected = choiceIndex);
  }

  void _reveal() {
    if (_revealed) return;
    _timer?.cancel();
    _bgmPlayer?.pause();
    setState(() {
      _paused = false;
      _revealed = true;
    });
  }

  void _next() {
    _timer?.cancel();
    if (_index >= _questions.length - 1) {
      _bgmPlayer?.pause();
      if (_questions.length == 1) {
        Navigator.pop(context);
        return;
      }
      setState(() => _index = _questions.length);
      return;
    }
    _openInputController.clear();
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
      _timeUp = false;
    });
    _markCurrentUsed();
    _startTimer();
  }

  void _retry() {
    _openInputController.clear();
    setState(() {
      _draw();
      _index = 0;
      _correct = 0;
      _selected = null;
      _revealed = false;
      _timeUp = false;
    });
    if (_questions.isEmpty) return;
    _markCurrentUsed();
    _playRandomBgm();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgmPlayer?.dispose();
    _openInputController.dispose();
    _hotkeyNotifier.clearOverrides();
    super.dispose();
  }

  Color? _choiceColor(int i) {
    if (!_revealed) {
      return i == _selected ? Colors.blue.lighter : null;
    }
    final answerIndex = _questions[_index].answerIndex;
    if (i == answerIndex) return Colors.green.lighter;
    if (i == _selected) return Colors.red.lighter;
    return null;
  }

  Widget _buildChoiceList(_PlayQuestion question) {
    final typography = FluentTheme.of(context).typography;

    final allImageOnly = question.choices.isNotEmpty &&
        question.choices.every(
          (c) => c.imagePath != null && c.text.trim().isEmpty,
        );

    if (allImageOnly) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 4 / 3,
        ),
        itemCount: question.choices.length,
        itemBuilder: (context, i) {
          final choice = question.choices[i];
          return Button(
            style: ButtonStyle(
              backgroundColor: _choiceColor(i) == null
                  ? null
                  : WidgetStatePropertyAll(_choiceColor(i)),
              padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
            ),
            onPressed: _revealed ? null : () => _selectChoice(i),
            child: SizedBox.expand(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(choice.imagePath!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      itemCount: question.choices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final choice = question.choices[i];
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
            onPressed: _revealed ? null : () => _selectChoice(i),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (choice.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(choice.imagePath!),
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      choice.text,
                      style: typography.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typography = FluentTheme.of(context).typography;
    final bgmVolume = ref.watch(quizProvider).bgmVolume;

    if (_questions.isEmpty) {
      return BackArrowView(
        controlColor: Colors.black,
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
    final isUrgent = _remaining <= 5;

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
                if (question.difficulty > 0) ...[
                  const SizedBox(width: 12),
                  ...List.generate(
                    question.difficulty,
                    (_) => const Icon(
                      FluentIcons.favorite_star_fill,
                      size: 14,
                      color: Color(0xFFF5A623),
                    ),
                  ),
                ],
                const Spacer(),
                if (_bgmPlayer != null) ...[
                  const Icon(FluentIcons.volume2),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      value: bgmVolume * 100,
                      min: 0,
                      max: 100,
                      onChanged: (value) => _setVolume(value / 100),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  icon: Icon(
                    _paused ? FluentIcons.play : FluentIcons.pause,
                  ),
                  onPressed: _revealed || _timeUp ? null : _togglePause,
                ),
                const SizedBox(width: 12),
                Icon(
                  FluentIcons.timer,
                  color: isUrgent ? Colors.red : null,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_remaining',
                  style: typography.bodyStrong?.copyWith(
                    color: isUrgent ? Colors.red : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressBar(
              value: _remaining / _currentLimit * 100,
              activeColor: isUrgent ? Colors.red : null,
            ),
            const SizedBox(height: 24),
            Text(
              question.categoryName.isEmpty
                  ? question.question
                  : '[${question.categoryName}] ${question.question}',
              style: typography.subtitle,
            ),
            if (question.isOpenEnded && question.imagePath != null) ...[
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(question.imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: question.isOpenEnded
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_revealed) ...[
                          if (question.answerImagePath != null) ...[
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(question.answerImagePath!),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (question.openAnswer.isNotEmpty) ...[
                            Text(
                              '${loc.quiz_answer_label}: ${question.openAnswer}',
                              style: typography.subtitle,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        TextBox(
                          controller: _openInputController,
                          placeholder: loc.quiz_open_input_hint,
                          style: typography.subtitle,
                        ),
                      ],
                    )
                  : question.imagePath != null
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox.expand(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(question.imagePath!),
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topLeft,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(child: _buildChoiceList(question)),
                          ],
                        )
                      : _buildChoiceList(question),
            ),
            const SizedBox(height: 8),
            if (!_revealed) ...[
              if (_timeUp) ...[
                Text(
                  loc.quiz_time_over,
                  style: typography.bodyStrong?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: _reveal,
                child: Text(loc.quiz_reveal),
              ),
            ] else ...[
              if (!question.isOpenEnded) ...[
                const SizedBox(height: 4),
                Text(
                  _selected == question.answerIndex
                      ? loc.quiz_correct
                      : (_selected == null
                          ? loc.quiz_time_over
                          : loc.quiz_wrong),
                  style: typography.bodyStrong,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(Colors.green.dark),
                      ),
                      onPressed: () => _judge(true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(loc.quiz_correct),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(Colors.red.dark),
                      ),
                      onPressed: () => _judge(false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(loc.quiz_wrong),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
