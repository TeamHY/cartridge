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

    Widget accountTiny() {
      if (user?.nickname == null) {
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            HyperlinkButton(onPressed: () => showDialog(context: context, builder: (_) => const SignInDialog()), child: const Text('로그인')),
            Text('/', style: TextStyle(color: Colors.grey[120])),
            HyperlinkButton(onPressed: () => showDialog(context: context, builder: (_) => const SignUpDialog()), child: const Text('회원가입')),
          ],
        );
      }
      return _AccountFlyoutSmall(
        displayName: user!.nickname,
        isAdmin: user.isAdmin,
        onEditNickname: () => showDialog(context: context, builder: (_) => const NicknameEditDialog()),
        onSignOut: () async {
          try {
            await ref.read(recordModeAuthProvider).signOut();
            if (!context.mounted) return;
            UiFeedback.success(context, '로그아웃', '정상적으로 로그아웃되었습니다.');
          } catch (e) {
            UiFeedback.error(context, '로그아웃 실패', e.toString());
          }
        },
      );
    }

    return ScaffoldPage(
      header: ContentHeaderBar.backText(
        onBack: widget.onClose,
        title: '시참대회',
        actions: [
          accountTiny(),
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
                SizedBox(width: 6),
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
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountFlyoutSmall extends StatefulWidget {
  const _AccountFlyoutSmall({
    required this.displayName,
    required this.isAdmin,
    this.onEditNickname,
    this.onSignOut,
  });

  final String displayName;
  final bool isAdmin;
  final VoidCallback? onEditNickname;
  final Future<void> Function()? onSignOut;

  @override
  State<_AccountFlyoutSmall> createState() => _AccountFlyoutSmallState();
}

class _AccountFlyoutSmallState extends State<_AccountFlyoutSmall> {
  final _flyout = FlyoutController();
  @override
  void dispose() { _flyout.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyout,
      child: Button(
        onPressed: () => _flyout.showFlyout(
          barrierDismissible: true,
          builder: (ctx) => MenuFlyout(items: [
            MenuFlyoutItem(leading: const Icon(FluentIcons.edit), text: const Text('닉네임 변경'), onPressed: widget.onEditNickname),
            const MenuFlyoutSeparator(),
            MenuFlyoutItem(leading: const Icon(FluentIcons.sign_out), text: const Text('로그아웃'),
                onPressed: () async => await widget.onSignOut?.call()),
          ]),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(widget.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 6),
            InfoBadge(color: Colors.green, source: const Text('운영자')),
          ],
          const SizedBox(width: 6),
          const Icon(FluentIcons.chevron_down, size: 12),
        ]),
      ),
    );
  }
}
