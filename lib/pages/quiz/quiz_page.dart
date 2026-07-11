import 'package:cartridge/constants/quiz_category_options.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz_category.dart';
import 'package:cartridge/pages/quiz/quiz_play_page.dart';
import 'package:cartridge/pages/quiz/quiz_settings_page.dart';
import 'package:cartridge/pages/record/components/back_arrow_view.dart';
import 'package:cartridge/providers/quiz_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                SizedBox(
                  width: 140,
                  child: InfoLabel(
                    label: loc.quiz_question_count_label,
                    child: NumberBox<int>(
                      value: quiz.questionCount,
                      min: 1,
                      max: 100,
                      mode: SpinButtonPlacementMode.inline,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(quizProvider).setQuestionCount(value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: InfoLabel(
                    label: loc.quiz_time_limit_label,
                    child: NumberBox<int>(
                      value: quiz.timeLimit,
                      min: 5,
                      max: 600,
                      mode: SpinButtonPlacementMode.inline,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(quizProvider).setTimeLimit(value);
                        }
                      },
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
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: quiz.categories.length,
                      itemBuilder: (context, index) {
                        final category = quiz.categories[index];
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
      borderRadius: BorderRadius.circular(16),
      child: material.Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: material.InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 16),
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
                  '${category.quizzes.length} ${loc.quiz_count_suffix}',
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
      ),
    );
  }
}
