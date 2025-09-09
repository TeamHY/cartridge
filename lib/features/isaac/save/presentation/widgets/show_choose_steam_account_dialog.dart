import 'dart:io';

import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// 선택 다이얼로그 (Theme 가이드 반영)
Future<SteamAccountProfile?> showChooseSteamAccountDialog(
    BuildContext context,
    List<SteamAccountProfile> items,
    ) {
  final theme = FluentTheme.of(context);
  final accent = theme.accentColor.normal;
  final scrollCtrl = ScrollController();

  // theme.md: divider fallback은 시스템 텍스트 보조색을 살짝 희미하게
  Color divider(FluentThemeData t) =>
      t.dividerColor ?? (t.resources.textFillColorSecondary).withAlpha(64);

  return showDialog<SteamAccountProfile?>(
    context: context,
    builder: (ctx) => ContentDialog(
      // 헤더
      title: Row(
        children: [
          Icon(FluentIcons.folder_open, size: 18, color: accent),
          SizedBox(width: AppSpacing.xs),
          const Text('세이브 폴더 선택'),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
      // 본문
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: Scrollbar(
          controller: scrollCtrl,
          interactive: true,
          child: ListView.separated(
            controller: scrollCtrl,
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, i) => _AccountTile(
              profile: items[i],
              borderColor: divider(theme),
              onTap: () => Navigator.of(ctx).pop(items[i]),
            ),
          ),
        ),
      ),
      actions: [
        Button(
          child: const Text('취소'),
          onPressed: () => Navigator.of(ctx).pop(null),
        ),
      ],
    ),
  );
}

class _AccountTile extends StatefulWidget {
  final SteamAccountProfile profile;
  final VoidCallback onTap;
  final Color borderColor;

  const _AccountTile({
    required this.profile,
    required this.onTap,
    required this.borderColor,
  });

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  static const _r = 12.0; // theme.md: 카드/타일 공통 반지름
  static const _fast = Duration(milliseconds: 140);

  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = theme.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder<double>(
        duration: _fast,
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: _hovered ? 1 : 0),
        builder: (context, t, _) {
          final borderColor = Color.lerp(widget.borderColor, accent, 0.35 * t)!;
          final liftY = -2.0 * t + (_pressed ? 1.0 : 0.0);
          final shadowOpacity = (24 + 36 * t).round();

          return Transform.translate(
            offset: Offset(0, liftY),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_r),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withAlpha(shadowOpacity),
                    blurRadius: 10 + 8 * t,
                    offset: Offset(0, 4 + 2 * t),
                  ),
                ],
              ),
              child: Acrylic(
                tint: theme.micaBackgroundColor,
                luminosityAlpha: 0.0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(_r)),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTap: widget.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_r),
                      border: Border.all(color: borderColor),
                    ),
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(_r - 4),
                          child: (widget.profile.avatarPngPath != null)
                              ? Image.file(
                            File(widget.profile.avatarPngPath!),
                            width: 40, height: 40, fit: BoxFit.cover,
                          )
                              : Container(
                            width: 40, height: 40,
                            color: theme.resources.systemFillColorSolidNeutralBackground,
                            alignment: Alignment.center,
                            child: const Icon(FluentIcons.contact, size: 20),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            (widget.profile.personaName?.trim().isNotEmpty ?? false)
                                ? widget.profile.personaName!.trim()
                                : '(이름 미설정)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color.lerp(
                                theme.resources.textFillColorPrimary,
                                accent,
                                0.15 * t,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        AnimatedOpacity(
                          duration: _fast,
                          opacity: 0.6 + 0.4 * t,
                          child: Transform.translate(
                            offset: Offset(2 * t, 0),
                            child: Icon(
                              FluentIcons.chevron_right,
                              size: 10,
                              color: theme.resources.textFillColorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
