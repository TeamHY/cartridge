import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/theme/theme.dart';

class RecordModeDetailPage extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const RecordModeDetailPage({super.key, this.onClose});
  @override
  ConsumerState<RecordModeDetailPage> createState()=>_RecordModeDetailPageState();
}

class _RecordModeDetailPageState extends ConsumerState<RecordModeDetailPage>{
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(recordModeAuthUserProvider);
    final user      = userAsync.value;
    final fTheme    = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);

    return ScaffoldPage(
      header: ContentHeaderBar.backText(
        onBack: widget.onClose,
        title: loc.record_mode_title,
        actions: [
          AccountTiny(
            displayName: user?.nickname,
            isAdmin: user?.isAdmin ?? false,
            loading: userAsync.isLoading,
            error: userAsync.hasError,
            onSignIn: () => showDialog(context: context, builder: (_) => const SignInDialog()),
            onEditNickname: () => showDialog(context: context, builder: (_) => const NicknameEditDialog()),
            onSignOut: () async {
              try {
                await ref.read(recordModeAuthProvider).signOut();
                if (!context.mounted) return;
                UiFeedback.success(context, title: loc.account_signed_out_title, content: loc.account_signed_out_body);
              } catch (_) {
                UiFeedback.error(context, content: loc.account_sign_out_failed);
              }
            },
          ),
          Gaps.w12,
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                user != null ? fTheme.accentColor : Colors.grey[80],
              ),
            ),
            onPressed: user != null ? () async {
              try {
                await ref.read(recordModeSessionProvider).start();
                if (!context.mounted) return;
                UiFeedback.info(
                  context,
                  title: loc.play_instance_toast_title,
                  content: loc.play_instance_toast_body,
                );
              } catch (e) {
                UiFeedback.error(context, content: loc.instance_play_failed_body);
              }
            } : null,
            child: Row(
              children: [
                Icon(FluentIcons.play_solid),
                Gaps.w6,
                Text(loc.play_instance_button_title),
              ],
            ),
          ),
        ],
      ),
      content: ContentShell(
        child: Column(
          children: [
            DesktopGrid(
              maxContentWidth: AppBreakpoints.lg + 1,
              colsLg: 2,
              colsMd: 2,
              colsSm: 1,
              items: const [
                GridItem(child: RecordModeLeftPanel()),
                GridItem(child: RecordModeRightPanel()),
              ],
            ),
            Gaps.h16,
          ],
        ),
      ),
    );
  }
}
