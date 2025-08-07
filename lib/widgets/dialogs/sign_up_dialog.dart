import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cartridge/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);

    return ContentDialog(
      title: Text(loc.signup_dialog_title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: loc.signup_email_label,
              child: TextFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.signup_email_hint;
                  }

                  return null;
                },
                controller: _emailController,
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: loc.signup_password_label,
              child: PasswordFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.signup_password_hint;
                  }

                  if (value.length < 6) {
                    return loc.signup_password_min_length;
                  }

                  return null;
                },
                controller: _passwordController,
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: loc.signup_password_confirm_label,
              child: PasswordFormBox(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.signup_password_hint;
                  }

                  if (value != _passwordController.text) {
                    return loc.signup_password_mismatch;
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
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: () => onSubmit(context),
          child: Text(loc.signup_submit),
        ),
      ],
    );
  }
}
