import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class NicknameEditDialog extends ConsumerStatefulWidget {
  const NicknameEditDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NicknameEditDialogState();
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

  Future<void> onSignIn() async {
    final supabase = Supabase.instance.client;

    final nickname = _nicknameController.text;

    await Supabase.instance.client.from('users').upsert({
      'id': supabase.auth.currentSession!.user.id,
      'email': nickname,
    });
  }

  Future<void> onSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await onSignIn();
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, e.toString());
      }
      return;
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AppDialog(
      constraints: const BoxConstraints(maxWidth: 368),
      title: Text(loc.nickname_dialog_title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabeled(
              label: loc.nickname_label,
              child: AppTextField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.nickname_hint;
                  }

                  return null;
                },
                controller: _nicknameController,
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_cancel),
        ),
        AppButton.primary(
          onPressed: () => onSubmit(context),
          child: Text(loc.common_update),
        ),
      ],
    );
  }
}
