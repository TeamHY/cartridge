import 'package:cartridge/constants/quiz_category_options.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/quiz_category.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cartridge/pages/quiz/components/quiz_editor_card.dart';
import 'package:cartridge/pages/record/components/back_arrow_view.dart';
import 'package:cartridge/providers/quiz_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuizSettingsPage extends ConsumerStatefulWidget {
  const QuizSettingsPage({super.key});

  @override
  ConsumerState<QuizSettingsPage> createState() => _QuizSettingsPageState();
}

class _QuizSettingsPageState extends ConsumerState<QuizSettingsPage> {
  final _scrollController = ScrollController();
  String? _selectedCategoryId;
  String? _autofocusQuizId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<({String name, String iconName, int colorValue})?> _showCategoryDialog(
    String title, {
    String? initialName,
    String? initialIcon,
    int? initialColor,
  }) {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: initialName);
    var selectedIcon = initialIcon ?? defaultQuizCategoryIcon;
    var selectedColor = initialColor ?? defaultQuizCategoryColor;
    final iconEntries = quizCategoryIcons.entries.toList();

    return showAppDialog<({String name, String iconName, int colorValue})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final c = AppColors.of(context);

          void submit() {
            Navigator.pop(context, (
              name: controller.text,
              iconName: selectedIcon,
              colorValue: selectedColor,
            ));
          }

          return AppDialog(
            title: Text(title),
            constraints: const BoxConstraints(maxWidth: 480),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: controller,
                  placeholder: loc.quiz_category_name_label,
                  autofocus: true,
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 16),
                AppLabeled(
                  label: loc.quiz_color_label,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quizCategoryColors.map((color) {
                      final value = color.toARGB32();
                      final isSelected = value == selectedColor;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => selectedColor = value),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: c.ink, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? const PhosphorIcon(
                                    PhosphorIconsBold.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                AppLabeled(
                  label: loc.quiz_icon_label,
                  child: SizedBox(
                    height: 220,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: iconEntries.length,
                      itemBuilder: (context, index) {
                        final entry = iconEntries[index];
                        final isSelected = entry.key == selectedIcon;
                        return AppPressable(
                          onPressed: () =>
                              setState(() => selectedIcon = entry.key),
                          builder: (context, states) {
                            final hovered =
                                states.contains(WidgetState.hovered);
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(selectedColor)
                                        .withValues(alpha: 0.2)
                                    : (hovered
                                        ? c.surface3
                                        : Colors.transparent),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                entry.value,
                                size: 20,
                                color: isSelected
                                    ? Color(selectedColor)
                                    : (hovered ? c.ink : c.ink2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              AppButton(
                child: Text(loc.quiz_cancel),
                onPressed: () => Navigator.pop(context),
              ),
              AppButton.primary(
                onPressed: submit,
                child: Text(loc.quiz_confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCategory() async {
    final loc = AppLocalizations.of(context);
    final result = await _showCategoryDialog(loc.quiz_category_add);

    if (result != null && result.name.trim().isNotEmpty) {
      final category = ref.read(quizProvider).addCategory(
            result.name.trim(),
            result.iconName,
            result.colorValue,
          );
      setState(() => _selectedCategoryId = category.id);
    }
  }

  Future<void> _editCategory(QuizCategory category) async {
    final loc = AppLocalizations.of(context);
    final result = await _showCategoryDialog(
      loc.quiz_category_edit,
      initialName: category.name,
      initialIcon: category.iconName,
      initialColor: category.colorValue,
    );

    if (result != null && result.name.trim().isNotEmpty) {
      ref.read(quizProvider).updateCategory(
            category.id,
            name: result.name.trim(),
            iconName: result.iconName,
            colorValue: result.colorValue,
          );
    }
  }

  Future<void> _deleteCategory(QuizCategory category) async {
    final loc = AppLocalizations.of(context);

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: Text(loc.quiz_category_delete_title),
        content: Text(loc.quiz_category_delete_message),
        constraints: const BoxConstraints(maxWidth: 368),
        actions: [
          AppButton(
            child: Text(loc.quiz_cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.danger(
            child: Text(loc.quiz_delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(quizProvider).removeCategory(category.id);
      if (_selectedCategoryId == category.id) {
        setState(() => _selectedCategoryId = null);
      }
    }
  }

  Future<void> _pickBgm() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'],
      allowMultiple: true,
    );
    if (result == null) return;
    for (final path in result.files.map((f) => f.path).whereType<String>()) {
      ref.read(quizProvider).addBgmPath(path);
    }
  }

  Future<String?> _pickSoundFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'],
    );
    return result?.files.single.path;
  }

  Widget _buildSfxRow({
    required String? path,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: AppButton(
            onPressed: onPick,
            icon: const PhosphorIcon(PhosphorIconsRegular.musicNote),
            child: Text(
              path == null ? loc.quiz_bgm_select : p.basename(path),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (path != null)
          AppIconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.trash),
            tone: AppIconButtonTone.danger,
            onPressed: onClear,
          ),
      ],
    );
  }

  Future<void> _showSoundDialog() {
    final loc = AppLocalizations.of(context);

    return showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        title: Text(loc.quiz_sound_settings),
        constraints: const BoxConstraints(maxWidth: 480),
        content: Consumer(
          builder: (context, ref, _) {
            final quiz = ref.watch(quizProvider);
            final paths = quiz.bgmPaths;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLabeled(
                  label: loc.quiz_bgm_label,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (paths.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(loc.quiz_bgm_empty),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: paths.length,
                            itemBuilder: (context, index) {
                              final path = paths[index];
                              return AppListRow(
                                leading: const PhosphorIcon(
                                    PhosphorIconsRegular.musicNote),
                                title: Text(
                                  p.basename(path),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: AppIconButton(
                                  icon: const PhosphorIcon(
                                      PhosphorIconsRegular.trash),
                                  tone: AppIconButtonTone.danger,
                                  onPressed: () => ref
                                      .read(quizProvider)
                                      .removeBgmPath(path),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      AppButton(
                        onPressed: _pickBgm,
                        icon: const PhosphorIcon(PhosphorIconsRegular.plus),
                        child: Text(loc.quiz_bgm_add),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppLabeled(
                  label: loc.quiz_sfx_correct,
                  child: _buildSfxRow(
                    path: quiz.correctSfxPath,
                    onPick: () async {
                      final path = await _pickSoundFile();
                      if (path == null) return;
                      ref.read(quizProvider).setCorrectSfxPath(path);
                    },
                    onClear: () =>
                        ref.read(quizProvider).setCorrectSfxPath(null),
                  ),
                ),
                const SizedBox(height: 12),
                AppLabeled(
                  label: loc.quiz_sfx_wrong,
                  child: _buildSfxRow(
                    path: quiz.wrongSfxPath,
                    onPick: () async {
                      final path = await _pickSoundFile();
                      if (path == null) return;
                      ref.read(quizProvider).setWrongSfxPath(path);
                    },
                    onClear: () => ref.read(quizProvider).setWrongSfxPath(null),
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

  void _addQuiz(String categoryId) {
    final quiz = ref.read(quizProvider).addQuiz(categoryId);
    setState(() => _autofocusQuizId = quiz.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final quiz = ref.watch(quizProvider);
    final categories = quiz.categories;

    final selected =
        categories.where((c) => c.id == _selectedCategoryId).firstOrNull ??
            categories.firstOrNull;

    return BackArrowView(
      controlColor: AppColors.of(context).ink,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(loc.quiz_settings, style: AppTextStyles.title),
                ),
                AppButton(
                  onPressed: _showSoundDialog,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  icon: const PhosphorIcon(PhosphorIconsRegular.musicNote),
                  child: Text(
                    quiz.bgmPaths.isEmpty
                        ? loc.quiz_sound_settings
                        : '${loc.quiz_sound_settings} (${quiz.bgmPaths.length})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton.primary(
                          onPressed: _addCategory,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          icon: const PhosphorIcon(PhosphorIconsRegular.plus),
                          child: Text(loc.quiz_category_add),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: categories.isEmpty
                              ? Center(
                                  child: Text(
                                    loc.quiz_category_empty,
                                    style: AppTextStyles.body,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: categories.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    return AppListRow(
                                      selected: category.id == selected?.id,
                                      onPressed: () => setState(() =>
                                          _selectedCategoryId = category.id),
                                      leading: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Color(category.colorValue),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          quizCategoryIconData(
                                              category.iconName),
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(category.name),
                                      subtitle: Text(
                                        '${category.quizzes.length} ${loc.quiz_count_suffix}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppIconButton(
                                            icon: const PhosphorIcon(
                                                PhosphorIconsRegular
                                                    .pencilSimple),
                                            onPressed: () =>
                                                _editCategory(category),
                                          ),
                                          AppIconButton(
                                            icon: const PhosphorIcon(
                                                PhosphorIconsRegular.trash),
                                            tone: AppIconButtonTone.danger,
                                            onPressed: () =>
                                                _deleteCategory(category),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: selected == null
                        ? Center(
                            child: Text(
                              loc.quiz_select_category,
                              style: AppTextStyles.body,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selected.name, style: AppTextStyles.section),
                              const SizedBox(height: 12),
                              Expanded(
                                child: selected.quizzes.isEmpty
                                    ? Center(
                                        child: Text(
                                          loc.quiz_empty,
                                          style: AppTextStyles.body,
                                        ),
                                      )
                                    : ListView.separated(
                                        controller: _scrollController,
                                        itemCount: selected.quizzes.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final q = selected.quizzes[index];
                                          return QuizEditorCard(
                                            key: ValueKey(q.id),
                                            index: index,
                                            quiz: q,
                                            autofocus: q.id == _autofocusQuizId,
                                            onChanged: (updated) => ref
                                                .read(quizProvider)
                                                .updateQuiz(
                                                    selected.id, updated),
                                            onDelete: () => ref
                                                .read(quizProvider)
                                                .removeQuiz(selected.id, q.id),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 12),
                              AppButton.primary(
                                onPressed: () => _addQuiz(selected.id),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 6),
                                icon: const PhosphorIcon(
                                    PhosphorIconsRegular.plus),
                                child: Text(loc.quiz_add),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
