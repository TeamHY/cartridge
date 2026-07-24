import 'package:cartridge/constants/quiz_category_options.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz_category.dart';
import 'package:cartridge/pages/quiz/components/quiz_play_options_dialog.dart';
import 'package:cartridge/pages/quiz/quiz_play_page.dart';
import 'package:cartridge/pages/quiz/quiz_settings_page.dart';
import 'package:cartridge/pages/record/components/back_arrow_view.dart';
import 'package:cartridge/providers/quiz_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  void _startQuiz(
      BuildContext context, WidgetRef ref, QuizCategory category) {
    final loc = AppLocalizations.of(context);
    final validCount = category.quizzes.where((q) => q.isComplete).length;

    if (validCount == 0) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(loc.quiz_start_empty),
          severity: InfoBarSeverity.warning,
          onClose: close,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => QuizPlayPage(categoryId: category.id),
      ),
    );
  }

  void _startRandomQuiz(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final quiz = ref.read(quizProvider);
    final completeQuizzes = quiz.categories
        .expand((c) => c.quizzes)
        .where((q) => q.isComplete)
        .toList();
    final unusedCount = completeQuizzes
        .where((q) => !quiz.usedQuizIds.contains(q.id))
        .length;

    if (unusedCount == 0) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(
            completeQuizzes.isEmpty ? loc.quiz_start_empty : loc.quiz_all_used,
          ),
          severity: InfoBarSeverity.warning,
          onClose: close,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => const QuizPlayPage(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => const QuizSettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final typography = FluentTheme.of(context).typography;
    final quiz = ref.watch(quizProvider);

    return BackArrowView(
      controlColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(loc.quiz_title, style: typography.title),
                ),
                ToggleSwitch(
                  checked: quiz.autoAdvance,
                  onChanged: (value) =>
                      ref.read(quizProvider).setAutoAdvance(value),
                  content: Text(loc.quiz_auto_advance),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: InfoLabel(
                    label: loc.quiz_question_count_label,
                    child: NumberBox<int>(
                      value: quiz.questionCount,
                      min: 1,
                      max: 100,
                      mode: SpinButtonPlacementMode.inline,
                      onChanged: quiz.autoAdvance
                          ? null
                          : (value) {
                              if (value != null) {
                                ref.read(quizProvider).setQuestionCount(value);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: () => showQuizPlayOptionsDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.equalizer),
                        const SizedBox(width: 8),
                        Text(loc.quiz_play_options),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: quiz.usedQuizIds.isEmpty
                      ? null
                      : () => ref.read(quizProvider).resetUsedQuizzes(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.refresh),
                        const SizedBox(width: 8),
                        Text(loc.quiz_reset_used),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: () => _openSettings(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.settings),
                        const SizedBox(width: 8),
                        Text(loc.quiz_settings),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: quiz.categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(loc.quiz_category_empty, style: typography.body),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _openSettings(context),
                            child: Text(loc.quiz_settings),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 168,
                      ),
                      itemCount: quiz.categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final completeQuizzes = quiz.categories
                              .expand((c) => c.quizzes)
                              .where((q) => q.isComplete)
                              .toList();
                          return _AllRandomCard(
                            remainingCount: completeQuizzes
                                .where(
                                    (q) => !quiz.usedQuizIds.contains(q.id))
                                .length,
                            totalCount: completeQuizzes.length,
                            onTap: () => _startRandomQuiz(context, ref),
                          );
                        }
                        final category = quiz.categories[index - 1];
                        return _CategoryCard(
                          category: category,
                          onTap: () => _startQuiz(context, ref, category),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllRandomCard extends StatelessWidget {
  const _AllRandomCard({
    required this.remainingCount,
    required this.totalCount,
    required this.onTap,
  });

  final int remainingCount;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return material.Material(
      color: Colors.transparent,
      child: material.InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  PhosphorIconsFill.shuffle,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.quiz_all_random,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$remainingCount / $totalCount ${loc.quiz_count_suffix}',
                style: TextStyle(
                  color: const Color(0xFF1F2937).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final QuizCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = Color(category.colorValue);

    return material.Material(
      color: Colors.transparent,
      child: material.InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  quizCategoryIconData(category.iconName),
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${category.quizzes.where((q) => q.isComplete).length} ${loc.quiz_count_suffix}',
                style: TextStyle(
                  color: const Color(0xFF1F2937).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
