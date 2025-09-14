// lib/app/presentation/widgets/account/account_tiny.dart
import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class AccountTiny extends ConsumerWidget {
  const AccountTiny({
    super.key,
    this.displayName,
    this.isAdmin = false,
    this.loading = false,
    this.error = false,
    this.onSignIn,
    this.onEditNickname,
    this.onSignOut,
    this.maxNameWidth = 160,
  });

  final String? displayName;
  final bool isAdmin;
  final bool loading;
  final bool error;

  final VoidCallback? onSignIn;
  final VoidCallback? onEditNickname;
  final Future<void> Function()? onSignOut;

  final double maxNameWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    if (loading || error) {
      return Button(
        onPressed: null,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FluentIcons.contact, size: 14),
          const SizedBox(width: 6),
          Text(loc.account_button_label),
        ]),
      );
    }

    // 비로그인: 단일 로그인 버튼
    if (displayName == null || displayName!.trim().isEmpty) {
      return Button(
        onPressed: onSignIn,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FluentIcons.signin, size: 14),
          const SizedBox(width: 6),
          Text(loc.account_sign_in),
        ]),
      );
    }

    // 로그인 상태: 아바타 + 닉네임 + 드롭다운
    final name = displayName!.trim();
    final initial = name.characters.first.toUpperCase();

    return _ProfileFlyoutButton(
      name: name,
      initial: initial,
      isAdmin: isAdmin,
      adminBadgeColor: FluentTheme.of(context).accentColor,
      onEditNickname: onEditNickname,
      onSignOut: onSignOut,
      maxNameWidth: maxNameWidth,
    );
  }
}

class _ProfileFlyoutButton extends StatefulWidget {
  const _ProfileFlyoutButton({
    required this.name,
    required this.initial,
    required this.isAdmin,
    required this.adminBadgeColor,
    required this.onEditNickname,
    required this.onSignOut,
    required this.maxNameWidth,
  });

  final String name;
  final String initial;
  final bool isAdmin;
  final Color adminBadgeColor;
  final VoidCallback? onEditNickname;
  final Future<void> Function()? onSignOut;
  final double maxNameWidth;

  @override
  State<_ProfileFlyoutButton> createState() => _ProfileFlyoutButtonState();
}

class _ProfileFlyoutButtonState extends State<_ProfileFlyoutButton> {
  final _flyout = FlyoutController();
  @override
  void dispose() { _flyout.dispose(); super.dispose(); }
  void _closeFlyoutThen(FutureOr<void> Function() action) {

    _flyout.close(); // or: _flyout.hide();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await action();
    });

  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final t   = FluentTheme.of(context);

    final avatarBg = t.accentColor.normal.withAlpha(48);
    final avatarFg = t.accentColor.darker;

    return FlyoutTarget(
      controller: _flyout,
      child: Button(
        onPressed: () => _flyout.showFlyout(
          barrierDismissible: true,
          placementMode: FlyoutPlacementMode.bottomRight,
          builder: (ctx) => MenuFlyout(
            color: t.scaffoldBackgroundColor,
            items: [
              MenuFlyoutItem(
                leading: const Icon(FluentIcons.edit),
                text: Text(loc.account_change_nickname),
                onPressed: () {
                  _closeFlyoutThen(() async {
                    widget.onEditNickname?.call();
                  });
                },
              ),
              const MenuFlyoutSeparator(),
              MenuFlyoutItem(
                leading: const Icon(FluentIcons.sign_out),
                text: Text(loc.account_sign_out),
                onPressed: () async => await widget.onSignOut?.call(),
              ),
            ],
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (widget.isAdmin)
            Container(
              height: 20,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: AppShapes.pill,
              ),
              alignment: Alignment.center,
              child: Text(AppLocalizations.of(context).account_admin_badge,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: avatarFg, height: 1),
              ),
            ),
          // 아바타(이니셜)
          if (!widget.isAdmin)
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(widget.initial,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: avatarFg, height: 1),
              ),
            ),
          const SizedBox(width: 8),
          // 닉네임(ellipsis + 툴팁)
          Tooltip(
            message: widget.name,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxNameWidth),
              child: Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(FluentIcons.chevron_down, size: 12),
        ]),
      ),
    );
  }
}
