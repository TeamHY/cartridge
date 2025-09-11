import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
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
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await ref.read(recordModeAuthProvider).signUpWithPassword(email, password);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) showErrorDialog(context, e.toString());
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
                controller: _emailController,
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.signup_email_hint : null,
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: loc.signup_password_label,
              child: PasswordFormBox(
                controller: _passwordController,
                validator: (v) {
                  if (v == null || v.isEmpty) return loc.signup_password_hint;
                  if (v.length < 6) return loc.signup_password_min_length;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: loc.signup_password_confirm_label,
              child: PasswordFormBox(
                controller: _passwordConfirmController,
                validator: (v) {
                  if (v == null || v.isEmpty) return loc.signup_password_hint;
                  if (v != _passwordController.text) return loc.signup_password_mismatch;
                  return null;
                },
                onFieldSubmitted: (_) => _onSubmit(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(onPressed: () => Navigator.pop(context), child: Text(loc.common_cancel)),
        FilledButton(onPressed: () => _onSubmit(context), child: Text(loc.signup_submit)),
      ],
    );
  }
}
