import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/controllers/home_controller.dart';
import 'package:cartridge/app/presentation/widgets/home/home_card.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';
import 'package:cartridge/features/isaac/save/isaac_save.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class IsaacHomeSection extends ConsumerWidget {
  const IsaacHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    final autoInfo = ref.watch(isaacAutoInfoProvider);
    final IsaacEdition? detectedEdition =
    autoInfo.maybeWhen(data: (info) => info.edition, orElse: () => null);

    Future<void> openProps() async =>
        openGameProperties(context, ref);
    Future<void> verify() async =>
        runIntegrityCheck(context, ref);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 감지 요약
          const IsaacInstallDetectCard(),
          Gaps.h12,
          // 액션 타일들
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _buildActionTile(
                context,
                loc.isaac_action_open_install_folder,
                FluentIcons.fabric_open_folder_horizontal,
                    () => openInstallFolder(context, ref),
              ),
              _buildActionTile(
                context,
                loc.isaac_action_open_save_folder,
                FluentIcons.fabric_open_folder_horizontal,
                    () => openSaveFolder(context, ref),
              ),
              _buildActionTile(
                context,
                loc.isaac_action_open_options_folder,
                FluentIcons.fabric_open_folder_horizontal,
                    () => openOptionsFolder(context, ref),
              ),
              _buildActionTile(
                context,
                loc.isaac_action_steam_game_options,
                FluentIcons.settings,
                openProps,
              ),
              _buildActionTile(
                context,
                loc.isaac_action_steam_verify_integrity,
                FluentIcons.shield,
                verify,
                accent: fTheme.accentColor,
              ),
              _buildActionTile(
                context,
                loc.isaac_action_eden_token,
                FluentIcons.pro_hockey,
                    () =>
                    openEdenTokenEditor(context, ref, detectedEdition: detectedEdition),
                accent: accent2Of(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// === 액션 타일 ===

Widget _buildActionTile(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? onPressed, {
      String? tooltip,
      AccentColor? accent,
    }) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
      return SizedBox(
        width: itemWidth,
        child: _ActionTile(
          label: label,
          icon: icon,
          onPressed: onPressed,
          tooltip: tooltip,
          accent: accent,
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AccentColor? accent;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final enabled = onPressed != null;

    final tile = HoverButton(
      onPressed: onPressed,
      builder: (context, states) {
        final hovered = states.isHovered && enabled;
        final pressed = states.isPressed && enabled;

        // 기본 배경: 제공된 accent가 있으면 내부에서 alpha blend, 없으면 카드 기본색
        final Color base = (accent != null)
            ? Color.alphaBlend(
                accent!.normal.withAlpha(
                  fTheme.brightness == Brightness.dark ? 84 : 48,
                ),
                fTheme.cardColor,
              )
            : fTheme.cardColor;
        final overlay = _tileOverlay(
          brightness: fTheme.brightness,
          hovered: hovered,
          pressed: pressed,
        );
        final bg = Color.alphaBlend(overlay, base);

        // hover 시 테두리도 살짝 강조
        final borderColor = hovered
            ? fTheme.resources.controlStrokeColorSecondary
            : fTheme.resources.controlStrokeColorDefault;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
            boxShadow: hovered
                ? [
              BoxShadow(
                color: fTheme.shadowColor.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: enabled ? null : fTheme.inactiveColor),
              Gaps.w8,
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: enabled ? null : TextStyle(color: fTheme.inactiveColor),
                ),
              ),
            ],
          ),
        );
      },
    );

    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}


Color _tileOverlay({
  required Brightness brightness,
  required bool hovered,
  required bool pressed,
}) {
  if (pressed) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(48)   // 다크: 더 밝게
        : Colors.black.withAlpha(36);  // 라이트: 더 어둡게
  }
  if (hovered) {
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(28)
        : Colors.black.withAlpha(18);
  }
  return Colors.transparent;
}