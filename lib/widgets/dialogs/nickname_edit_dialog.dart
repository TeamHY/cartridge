import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return ContentDialog(
      title: const Text('닉네임 변경'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: '닉네임',
              child: TextFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임임을 입력해주세요.';
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
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => onSubmit(context),
          child: const Text('변경'),
        ),
      ],
    );
  }
}
