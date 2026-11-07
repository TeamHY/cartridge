import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
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

    return AppDialog(
      constraints: const BoxConstraints(maxWidth: 368),
      title: Text(loc.signup_dialog_title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabeled(
              label: loc.signup_email_label,
              child: AppTextField(
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
            AppLabeled(
              label: loc.signup_password_label,
              child: AppTextField(
                obscureText: true,
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
            AppLabeled(
              label: loc.signup_password_confirm_label,
              child: AppTextField(
                obscureText: true,
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
        AppButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_cancel),
        ),
        AppButton.primary(
          onPressed: () => onSubmit(context),
          child: Text(loc.signup_submit),
        ),
      ],
    );
  }
}
