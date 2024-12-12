import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpDialog extends ConsumerStatefulWidget {
  const SignUpDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends ConsumerState<SignUpDialog> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _passwordConfirmController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  Future<void> onSignUp() async {
    final supabase = Supabase.instance.client;

    final email = _emailController.text;
    final password = _passwordController.text;

    await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> onSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await onSignUp();
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
      title: const Text('회원가입'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: '이메일',
              child: TextFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }

                  return null;
                },
                controller: _emailController,
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: '비밀번호',
              child: PasswordFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }

                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다.';
                  }

                  return null;
                },
                controller: _passwordController,
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: '비밀번호 확인',
              child: PasswordFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }

                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }

                  return null;
                },
                controller: _passwordConfirmController,
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
          child: const Text('회원가입'),
        ),
      ],
    );
  }
}
