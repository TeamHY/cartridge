import 'package:cartridge/main.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> {
  bool _isChanged = false;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  Future<void> onSignIn() async {
    final supabase = Supabase.instance.client;

    final email = _emailController.text;
    final password = _passwordController.text;

    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('로그인'),
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

                  return null;
                },
                controller: _passwordController,
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            onSignIn();
            Navigator.pop(context);
          },
          child: const Text('로그인'),
        ),
      ],
    );
  }
}
