import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/theme/tokens/spacing.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class NicknameEditDialog extends ConsumerStatefulWidget {
  const NicknameEditDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends ConsumerState<NicknameEditDialog> {
  late TextEditingController _nicknameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final nickname = _nicknameController.text.trim();
      await ref.read(recordModeAuthServiceProvider).changeNickname(nickname);
    } catch (e) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context);
        UiFeedback.error(context, content: loc.auth_error_body);
      }
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final t   = FluentTheme.of(context);
    final accent = t.accentColor.normal;

    final userAsync = ref.watch(recordModeAuthUserProvider);
    final currentNickname = userAsync.value?.nickname ?? '';
    if (_nicknameController.text.isEmpty && currentNickname.isNotEmpty) {
      _nicknameController.text = currentNickname;
      _nicknameController.selection = TextSelection.collapsed(offset: _nicknameController.text.length);
    }

    return ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.edit, size: 18, color: accent),
          Gaps.w4,
          Text(loc.nickname_dialog_title),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: loc.nickname_label,
              child: TextFormBox(
                controller: _nicknameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.nickname_hint;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _onSubmit(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: () => _onSubmit(context),
          child: Text(loc.common_update),
        ),
      ],
    );
  }
}
