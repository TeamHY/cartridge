import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/app_scaffold.dart';
import 'package:cartridge/features/cartridge/content/content_page.dart';
import 'package:cartridge/app/presentation/pages/home_page.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

final appNavigationIndexProvider = StateProvider<int>((ref) => 0);

class AppNavigation extends ConsumerStatefulWidget {
  const AppNavigation({super.key});
  @override
  ConsumerState<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends ConsumerState<AppNavigation> {

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(appNavigationIndexProvider);
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    List<NavigationPaneItem> items() => [
      _paneItem(
        icon: FluentIcons.home,
        title: loc.navigation_home,
        body: const HomePage(),
        context: context,
      ),

      // open 모드 ‘전환 프레임’에만 PaneItem로 대체해 overflow 회피
      _paneItemExpander(
        context: context,
        icon: FluentIcons.server,
        title: loc.navigation_instance,
        body: const InstancePage(),
        children: <NavigationPaneItem>[
          // 모드 프리셋 화면
          _paneItem(
            icon: FluentIcons.puzzle,
            title: loc.navigation_mod_preset,
            body: const ModPresetsTab(),
            context: context,
          ),
          // 옵션 프리셋 화면
          _paneItem(
            icon: FluentIcons.toolbox,
            title: loc.navigation_option_preset,
            body: const OptionPresetsTab(),
            context: context,
          ),
        ],
      ),

      PaneItemSeparator(),
      _paneItem(
        icon: FluentIcons.all_apps,
        title: loc.navigation_content,
        body: const ContentPage(),
        context: context,
      ),
      _paneItem(
        icon: FluentIcons.game,
        title: loc.navigation_slot_machine,
        body: const SlotMachinePage(),
        context: context,
      ),
      PaneItemSeparator(),
      _paneItem(
        icon: FluentIcons.settings,
        title: loc.navigation_settings,
        body: const SettingsPage(),
        context: context,
      ),
    ];

    return NavigationView(
      appBar: buildNavigationAppBar(context, ref),
      contentShape: const RoundedRectangleBorder(
        side: BorderSide.none,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
      ),
      paneBodyBuilder: (item, body) => Container(
        color: fTheme.cardColor, padding: EdgeInsets.zero,
        child: body ?? const SizedBox.shrink(),
      ),
      pane: NavigationPane(
        selected: index,
        onChanged: (i) => ref.read(appNavigationIndexProvider.notifier).state = i,
        size: const NavigationPaneSize(openWidth: AppSpacing.navigationPaneSize),
        indicator: null,
        items: items(),
      ),
    );
  }

  static Icon _icon(BuildContext context, IconData data) {
    final fTheme = FluentTheme.of(context);
    return Icon(data, size: 18.0, color: fTheme.accentColor.normal);
  }

  static WidgetStateProperty<Color> _selectedTile(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final alpha = fTheme.brightness == Brightness.light ? 36 : 52;
    return WidgetStatePropertyAll(fTheme.accentColor.normal.withAlpha(alpha));
  }

  static PaneItem _paneItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget body,
  }) {
    return PaneItem(
      icon: _icon(context, icon),
      title: Text(title, style: AppTypography.navigationPane),
      body: body,
      selectedTileColor: _selectedTile(context),
    );
  }

  PaneItemExpander _paneItemExpander({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget body,
    required List<NavigationPaneItem> children,
  }) {
    return PaneItemExpander(
      icon: _icon(context, icon),
      title: Text(title, style: AppTypography.navigationPane),
      body: body,
      items: children,
      selectedTileColor: _selectedTile(context),
    );
  }
}
