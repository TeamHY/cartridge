// lib/app/presentation/auth/sign_in_dialog.dart
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/theme/tokens/spacing.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await ref.read(recordModeAuthServiceProvider).signInWithPassword(email, password);
    } catch (_) {
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

    return ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.signin, size: 18, color: accent),
          Gaps.w4,
          Text(loc.signin_dialog_title),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: loc.signin_email_label,
              child: TextFormBox(
                controller: _emailController,
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.signin_email_hint : null,
              ),
            ),
            const SizedBox(height: 16.0),
            InfoLabel(
              label: loc.signin_password_label,
              child: PasswordFormBox(
                controller: _passwordController,
                validator: (v) => (v == null || v.isEmpty) ? loc.signin_password_hint : null,
                onFieldSubmitted: (_) => _onSubmit(context),
              ),
            ),
            const SizedBox(height: 16.0),

            Divider(style: const DividerThemeData(horizontalMargin: EdgeInsets.zero)),

            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.signin_no_account,
                    style: TextStyle(color: t.resources.textFillColorSecondary),
                  ),
                ),
                HyperlinkButton(
                  onPressed: () {
                    // 1) 지금 떠있는 로그인 다이얼로그 닫기 (루트 네비게이터 기준)
                    final rootNav = Navigator.of(context, rootNavigator: true);
                    rootNav.pop();

                    // 2) 다음 프레임에 회원가입 다이얼로그 열기
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: rootNav.context, // 루트 컨텍스트 사용 → 안전
                        builder: (_) => const SignUpDialog(),
                      );
                    });
                  },
                  child: Text(loc.record_signup),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Button(onPressed: () => Navigator.pop(context), child: Text(loc.common_cancel)),
        FilledButton(onPressed: () => _onSubmit(context), child: Text(loc.signin_submit)),
      ],
    );
  }
}
