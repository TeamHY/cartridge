import 'dart:async';
import 'dart:io';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz.dart';
import 'package:cartridge/services/quiz_service.dart';
import 'package:file_picker/file_picker.dart';
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
  late final TextEditingController _openAnswerController;
  late final List<TextEditingController> _choiceControllers;
  final _questionFocus = FocusNode();

  Timer? _debounce;
  late int _answerIndex;
  late bool _isOpenEnded;
  String? _imagePath;
  late List<String?> _choiceImages;
  int? _timeLimit;
  late int _difficulty;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.quiz.question);
    _openAnswerController =
        TextEditingController(text: widget.quiz.openAnswer);
    _choiceControllers = List.generate(
      widget.quiz.choices.length,
      (i) => TextEditingController(text: widget.quiz.choices[i]),
    );
    _answerIndex = widget.quiz.answerIndex;
    _isOpenEnded = widget.quiz.isOpenEnded;
    _imagePath = widget.quiz.imagePath;
    _timeLimit = widget.quiz.timeLimit;
    _difficulty = widget.quiz.difficulty;
    _choiceImages = List<String?>.generate(
      widget.quiz.choices.length,
      (i) => i < widget.quiz.choiceImages.length
          ? widget.quiz.choiceImages[i]
          : null,
    );

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
    _openAnswerController.dispose();
    for (final c in _choiceControllers) {
      c.dispose();
    }
    _questionFocus.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _commit);
  }

  Quiz get _currentQuiz => Quiz(
        id: widget.quiz.id,
        question: _questionController.text,
        choices: _choiceControllers.map((c) => c.text).toList(),
        answerIndex: _answerIndex,
        isOpenEnded: _isOpenEnded,
        imagePath: _imagePath,
        openAnswer: _openAnswerController.text,
        choiceImages: List<String?>.of(_choiceImages),
        timeLimit: _timeLimit,
        difficulty: _difficulty,
      );

  void _commit() {
    widget.onChanged(_currentQuiz);
  }

  Future<String?> _importPickedImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final sourcePath = result?.files.single.path;
    if (sourcePath == null) return null;
    return QuizService.importImage(sourcePath);
  }

  Future<void> _pickQuestionImage() async {
    final imported = await _importPickedImage();
    if (imported == null || !mounted) return;
    setState(() => _imagePath = imported);
    _commit();
  }

  void _removeQuestionImage() {
    setState(() => _imagePath = null);
    _commit();
  }

  Future<void> _pickChoiceImage(int index) async {
    final imported = await _importPickedImage();
    if (imported == null || !mounted) return;
    setState(() => _choiceImages[index] = imported);
    _commit();
  }

  void _removeChoiceImage(int index) {
    setState(() => _choiceImages[index] = null);
    _commit();
  }

  void _addChoice() {
    if (_choiceControllers.length >= 8) return;
    setState(() {
      _choiceControllers.add(TextEditingController());
      _choiceImages.add(null);
    });
    _commit();
  }

  void _removeChoice(int index) {
    if (_choiceControllers.length <= 2) return;
    setState(() {
      _choiceControllers.removeAt(index).dispose();
      _choiceImages.removeAt(index);
      if (_answerIndex == index) {
        _answerIndex = 0;
      } else if (_answerIndex > index) {
        _answerIndex--;
      }
    });
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typography = FluentTheme.of(context).typography;

    return Card(
      padding: const EdgeInsets.all(16),
      backgroundColor:
          _currentQuiz.isComplete ? null : const Color(0xFFE4E4E4),
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
              const SizedBox(width: 4),
              Tooltip(
                message: loc.quiz_question_image,
                child: IconButton(
                  icon: const Icon(FluentIcons.photo2_add),
                  onPressed: _pickQuestionImage,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 8),
            Text(loc.quiz_question_image, style: typography.caption),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: loc.quiz_image_remove,
                child: _RemovableImage(
                  path: _imagePath!,
                  height: 100,
                  onRemove: _removeQuestionImage,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              ToggleSwitch(
                checked: _isOpenEnded,
                content: Text(loc.quiz_open_ended),
                onChanged: (value) {
                  setState(() => _isOpenEnded = value);
                  _commit();
                },
              ),
              const Spacer(),
              Text(loc.quiz_difficulty_label, style: typography.caption),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final filled = i < _difficulty;
                return IconButton(
                  icon: Icon(
                    filled
                        ? FluentIcons.favorite_star_fill
                        : FluentIcons.favorite_star,
                    size: 16,
                    color: filled ? const Color(0xFFF5A623) : null,
                  ),
                  onPressed: () {
                    setState(() =>
                        _difficulty = _difficulty == i + 1 ? 0 : i + 1);
                    _commit();
                  },
                );
              }),
              const SizedBox(width: 16),
              Text(loc.quiz_time_limit_label, style: typography.caption),
              const SizedBox(width: 6),
              Tooltip(
                message: loc.quiz_time_limit_custom_hint,
                child: SizedBox(
                  width: 110,
                  child: NumberBox<int>(
                    value: _timeLimit,
                    min: 5,
                    max: 600,
                    mode: SpinButtonPlacementMode.none,
                    placeholder: loc.quiz_time_limit_default,
                    onChanged: (value) {
                      _timeLimit = value;
                      _scheduleSave();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.quiz_answer_label, style: typography.caption),
          const SizedBox(height: 4),
          if (_isOpenEnded)
            TextBox(
              controller: _openAnswerController,
              placeholder: loc.quiz_open_answer_hint,
              onChanged: (_) => _scheduleSave(),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioGroup<int>(
                  groupValue: _answerIndex,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _answerIndex = value);
                    _scheduleSave();
                  },
                  child: Column(
                    children: List.generate(_choiceControllers.length, (i) {
                      final choiceImage = _choiceImages[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            RadioButton<int>(value: i),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextBox(
                                controller: _choiceControllers[i],
                                placeholder:
                                    '${loc.quiz_choice_hint} ${i + 1}',
                                onChanged: (_) => _scheduleSave(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (choiceImage != null)
                              Tooltip(
                                message: loc.quiz_image_remove,
                                child: _RemovableImage(
                                  path: choiceImage,
                                  width: 32,
                                  height: 32,
                                  onRemove: () => _removeChoiceImage(i),
                                ),
                              )
                            else
                              Tooltip(
                                message: loc.quiz_image_add,
                                child: IconButton(
                                  icon: const Icon(FluentIcons.photo2_add),
                                  onPressed: () => _pickChoiceImage(i),
                                ),
                              ),
                            if (_choiceControllers.length > 2) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(FluentIcons.chrome_close),
                                onPressed: () => _removeChoice(i),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                if (_choiceControllers.length < 8)
                  Button(
                    onPressed: _addChoice,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.add),
                        const SizedBox(width: 6),
                        Text(loc.quiz_choice_add),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RemovableImage extends StatefulWidget {
  const _RemovableImage({
    required this.path,
    required this.height,
    this.width,
    required this.onRemove,
  });

  final String path;
  final double height;
  final double? width;
  final VoidCallback onRemove;

  @override
  State<_RemovableImage> createState() => _RemovableImageState();
}

class _RemovableImageState extends State<_RemovableImage> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onRemove,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(widget.path),
                width: widget.width,
                height: widget.height,
                fit: widget.width != null ? BoxFit.cover : BoxFit.contain,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: widget.width ?? widget.height,
                  height: widget.height,
                  child: const Icon(FluentIcons.file_image),
                ),
              ),
            ),
            if (_hovering)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    FluentIcons.delete,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
