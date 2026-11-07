import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> {
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
      title: Text(loc.signin_dialog_title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabeled(
              label: loc.signin_email_label,
              child: AppTextField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.signin_email_hint;
                  }

                  return null;
                },
                controller: _emailController,
              ),
            ),
            const SizedBox(height: 16.0),
            AppLabeled(
              label: loc.signin_password_label,
              child: AppTextField(
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.signin_password_hint;
                  }

                  return null;
                },
                controller: _passwordController,
                onSubmitted: (_) => onSubmit(context),
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
          child: Text(loc.signin_submit),
        ),
      ],
    );
  }
}
