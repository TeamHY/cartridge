import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';

import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/theme/theme.dart';

/// 간단 상태 입력 방식:
/// - items == null && error == null   => 로딩
/// - error != null                    => 에러
/// - items!.isEmpty                   => 빈 목록
/// - 그 외                            => 목록 표시
Future<SteamAccountProfile?> showChooseSteamAccountDialog(
    BuildContext context, {
      List<SteamAccountProfile>? items,
      Object? error,
      VoidCallback? onRetry,
    }) {
  final fTheme = FluentTheme.of(context);
  final loc = AppLocalizations.of(context);
  final scrollCtrl = ScrollController();
  final accent = fTheme.accentColor.normal;
  final stroke = fTheme.dividerColor;

  Widget body;
  if (error != null) {
    body = _MessageCard(
      icon: FluentIcons.error,
      title: loc.common_error,
      subtitle: loc.choose_steam_error_hint,
      primary: onRetry == null ? null : _MessageAction(label: loc.common_retry, onPressed: onRetry),
    );
  } else if (items == null) {
    body = _SkeletonList();
  } else if (items.isEmpty) {
    // 빈 상태
    body = _MessageCard(
      icon: FluentIcons.contact,
      title: loc.choose_steam_empty_title,
      subtitle: loc.choose_steam_empty_desc,
    );
  } else {
    // 계정 목록
    body = Scrollbar(
      controller: scrollCtrl,
      interactive: true,
      child: ListView.separated(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => Gaps.h8,
        itemBuilder: (ctx, i) => _AccountTile(
          profile: items[i],
          onTap: () => Navigator.of(ctx).pop(items[i]),
          stroke: stroke,
        ),
      ),
    );
  }

  return showDialog<SteamAccountProfile?>(
    context: context,
    builder: (ctx) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 460),
      title: Row(
        children: [
          Icon(FluentIcons.fabric_open_folder_horizontal, size: 18, color: accent),
          Gaps.w8,
          Text(loc.choose_steam_title),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 460),
        child: body,
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text(loc.common_cancel),
        ),
      ],
    ),
  );
}

/// 계정 타일(프로젝트 테마 스킨)
class _AccountTile extends StatefulWidget {
  final SteamAccountProfile profile;
  final VoidCallback onTap;
  final Color stroke;

  const _AccountTile({
    required this.profile,
    required this.onTap,
    required this.stroke,
  });

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  static const _fast = Duration(milliseconds: 120);
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    Color overlay(bool hovered, bool pressed) {
      final b = fTheme.brightness;
      if (pressed) return b == Brightness.dark ? Colors.white.withAlpha(48) : Colors.black.withAlpha(36);
      if (hovered) return b == Brightness.dark ? Colors.white.withAlpha(28) : Colors.black.withAlpha(18);
      return Colors.transparent;
    }

    final name = (widget.profile.personaName?.trim().isNotEmpty ?? false)
        ? widget.profile.personaName!.trim()
        : AppLocalizations.of(context).choose_steam_name_unset;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp:   (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _fast,
          transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Color.alphaBlend(overlay(_hovered, _pressed), fTheme.cardColor),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: _hovered ? fTheme.resources.controlStrokeColorSecondary : widget.stroke),
            boxShadow: _hovered
                ? [
              BoxShadow(
                color: fTheme.shadowColor.withAlpha(fTheme.brightness == Brightness.dark ? 54 : 28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: (widget.profile.avatarPngPath != null)
                    ? Image.file(
                  File(widget.profile.avatarPngPath!),
                  width: 40, height: 40, fit: BoxFit.cover,
                )
                    : Container(
                  width: 40, height: 40,
                  color: fTheme.resources.subtleFillColorTertiary,
                  alignment: Alignment.center,
                  child: Icon(FluentIcons.contact, size: 20, color: fTheme.inactiveColor),
                ),
              ),
              Gaps.w8,
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fTheme.typography.bodyStrong?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Gaps.w4,
              Icon(FluentIcons.chevron_right_small, size: 12, color: fTheme.resources.textFillColorPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로딩 스켈레톤
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      children: List.generate(4, (i) => i).map((_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: theme.resources.subtleFillColorTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                Gaps.w8,
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.resources.subtleFillColorSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 메시지 카드(빈/에러 공용)
class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final _MessageAction? primary;

  const _MessageCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: theme.inactiveColor),
            Gaps.h8,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.bodyStrong?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              Gaps.h6,
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.typography.caption,
              ),
            ],
            if (primary != null) ...[
              Gaps.h12,
              Button(onPressed: primary!.onPressed, child: Text(primary!.label)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageAction {
  final String label;
  final VoidCallback onPressed;
  const _MessageAction({required this.label, required this.onPressed});
}
