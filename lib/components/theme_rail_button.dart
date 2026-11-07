import 'package:cartridge/components/app_icon.dart';
import 'package:cartridge/components/nav_rail.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _buttonSize = 40.0;
const _menuGap = 12.0;
const _menuPadding = 4.0;

class ThemeRailButton extends ConsumerWidget {
  const ThemeRailButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final setting = ref.watch(settingProvider);
    final modes = [
      (ThemeMode.light, loc.setting_theme_light, AppIcons.sun),
      (ThemeMode.dark, loc.setting_theme_dark, AppIcons.moon),
      (ThemeMode.system, loc.setting_theme_system, AppIcons.monitor),
    ];
    final current = modes.firstWhere((mode) => mode.$1 == setting.themeMode);
    const menuHeight = _menuPadding * 2 + appControlHeight * 3;

    return MenuAnchor(
      alignmentOffset: const Offset(_menuGap, _buttonSize - menuHeight),
      style: const MenuStyle(
        alignment: AlignmentDirectional.topEnd,
        minimumSize: WidgetStatePropertyAll(Size(200, 0)),
      ),
      menuChildren: [
        for (final (mode, label, _) in modes)
          MenuItemButton(
            leadingIcon: SizedBox.square(
              dimension: 16,
              child: mode == setting.themeMode
                  ? const AppIcon(AppIcons.check, size: 16)
                  : null,
            ),
            onPressed: () {
              setting.themeMode = mode;
              setting.saveSetting();
            },
            child: Text(label),
          ),
      ],
      builder: (context, controller, _) {
        final button = AppPressable(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          semanticLabel: '${loc.setting_theme_label}: ${current.$2}',
          builder: (context, states) {
            final c = AppColors.of(context);
            final active =
                controller.isOpen || states.contains(WidgetState.hovered);

            return Container(
              width: _buttonSize,
              height: _buttonSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c.surface3 : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: AppIcon(
                current.$3,
                size: 20,
                color: active ? c.ink : c.ink2,
              ),
            );
          },
        );

        if (controller.isOpen) return button;

        return Tooltip(
          message: '${loc.setting_theme_label}: ${current.$2}',
          positionDelegate: besideRailTarget,
          child: button,
        );
      },
    );
  }
}
