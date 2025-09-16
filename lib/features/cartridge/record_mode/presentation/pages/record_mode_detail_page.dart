import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/application/record_mode_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/models/game_session_events.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class RecordModeDetailPage extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const RecordModeDetailPage({super.key, this.onClose});
  @override
  ConsumerState<RecordModeDetailPage> createState()=>_RecordModeDetailPageState();
}

class _RecordModeDetailPageState extends ConsumerState<RecordModeDetailPage>{
  List<String>? _lastDisallowedNames;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(recordModeAuthUserProvider);
    final user      = userAsync.value;
    final fTheme    = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    ref.listen(recordModeEventsProvider, (prev, next) {
      next.whenData((e) async {
        if (!mounted) return;

        if (e is DisallowedModsFound) {
          _lastDisallowedNames = e.names;
          return;
        }

        if (e is SessionFinished) {
          if (e.reason == EndReason.success) {
            final t = getTimeString(Duration(milliseconds: e.elapsedMs));
            await _showResultDialog(
              context,
              title: loc.record_mode_result_title_success,
              body: e.submitted
                  ? loc.record_mode_result_dody_submitted(t)
                  : loc.record_mode_result_dody_not_submitted(t),
              loc: loc,
            );
          } else if (e.reason == EndReason.disallowed) {
            final names = _lastDisallowedNames ?? const <String>[];
            final sample = names.isNotEmpty ? names.first : '-';
            final more = names.length > 1 ? (names.length - 1) : 0;
            await _showResultDialog(
              context,
              title: loc.record_mode_result_title_disallowed,
              body: loc.record_mode_result_body_disallowed(sample, more),
              loc: loc,
            );
          }
        }
      });
    });

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
                await ref.read(recordModeAuthServiceProvider).signOut();
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
                await ref.read(recordModeSessionProvider).startSession();
                if (!context.mounted) return;
                UiFeedback.info(
                  context,
                  title: loc.play_instance_toast_title,
                  content: loc.play_instance_toast_body,
                );
              } catch (_) {
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

  Future<void> _showResultDialog(
      BuildContext context, {
        required String title,
        required String body,
        required AppLocalizations loc,
      }) async {
    await showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            child: Text(loc.common_close),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
