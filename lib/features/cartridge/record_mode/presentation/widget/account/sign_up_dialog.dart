import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

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
    } catch (e) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context);
        UiFeedback.error(context, loc.common_error, loc.auth_error_body);
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
    final noticeBg     = t.resources.cardBackgroundFillColorSecondary;
    final noticeStroke = t.resources.controlStrokeColorSecondary.withAlpha(32);

    return ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.add_friend, size: 18, color: accent),
          Gaps.w4,
          Text(loc.signup_dialog_title),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: noticeBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: noticeStroke, width: .8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(FluentIcons.info, size: 14),
                  ),
                  Gaps.w8,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.signup_notice_title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Gaps.h4,
                        Text(
                          loc.signup_notice_body,
                          style: TextStyle(
                            color: t.resources.textFillColorSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gaps.h12,
            InfoLabel(
              label: loc.signup_email_label,
              child: TextFormBox(
                controller: _emailController,
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.signup_email_hint : null,
              ),
            ),
            Gaps.h16,
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
            Gaps.h16,
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
