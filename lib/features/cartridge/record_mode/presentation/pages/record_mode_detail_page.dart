import 'package:cartridge/features/cartridge/record_mode/presentation/widget/account/account_tiny.dart';
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
        title: '시참대회',
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
                UiFeedback.success(context, loc.account_signed_out_title, loc.account_signed_out_body);
              } catch (_) {
                UiFeedback.error(context, loc.common_error, loc.account_sign_out_failed);
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
                UiFeedback.info(context, '실행', '게임 실행을 시작합니다.');
              } catch (e) {
                UiFeedback.error(context, '실행 실패', e.toString());
              }
            } : null,
            child: const Row(
              children: [
                Icon(FluentIcons.play_solid),
                Gaps.w6,
                Text('게임 실행'),
              ],
            ),
          ),
        ],
      ),
      content: ContentShell(
        child: LayoutBuilder(
          builder: (_, c) {
            return Column(
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
            );
          },
        ),
      ),
    );
  }
}
