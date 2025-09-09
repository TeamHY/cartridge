import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/app_scaffold.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/widgets/dialogs/setting_dialog.dart';
import 'package:cartridge/widgets/pages/home_page.dart';
import 'package:cartridge/widgets/pages/record_page.dart';
import 'package:cartridge/widgets/pages/slot_machine_page.dart';

final appNavigationIndexProvider = StateProvider<int>((ref) => 0);

class AppNavigation extends ConsumerWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(appNavigationIndexProvider);
    final loc = AppLocalizations.of(context);
    final store = ref.watch(storeProvider);
    final fTheme = FluentTheme.of(context);

    Future<void> openRecordPage() async {
      await Navigator.of(context).push(
        FluentPageRoute(builder: (_) => const RecordPage()),
      ); // ⬅ 전체 화면 전환
    }

    Future<void> openSlotMachine() async {
      await Navigator.of(context).push(
        FluentPageRoute(builder: (_) => const SlotMachinePage()),
      ); // ⬅ 전체 화면 전환
    }

    final items = <NavigationPaneItem>[
      // 홈 화면
      _paneItem(
        context: context,
        icon: FluentIcons.home,
        title: loc.home_button_preset,
        body: const material.Material(
          color: Colors.transparent,
          child: HomePage(),
        ),
      ),
      PaneItemSeparator(),
      // 컨텐츠(기록모드, 대결모드 등등 추가 컨텐츠)
      _paneAction(
        context: context,
        icon: FluentIcons.game,
        title: loc.home_button_record,
        onTap: openRecordPage,
      ),
      // 슬롯 머신(미니 게임)
      _paneAction(
        context: context,
        icon: FluentIcons.game,
        title: loc.home_button_slot_machine,
        onTap: openSlotMachine,
      ),
      // 데일리런 실행 버튼
      _paneAction(
        context: context,
        icon: FluentIcons.game,
        title: loc.home_button_daily_run,
        onTap: () => store.applyPreset(
          null,
          isEnableMods: false,
          isDebugConsole: false,
        ),
      ),
      PaneItemSeparator(),
      // 세팅 화면
      _paneAction(
        context: context,
        icon: FluentIcons.settings,
        title: loc.home_button_setting,
        onTap: () {
          showDialog(context: context, builder: (_) => const SettingDialog());
        },
      ),
    ];

    return NavigationView(
      appBar: buildNavigationAppBar(context, ref),
      contentShape: const RoundedRectangleBorder(
        side: BorderSide.none,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
      ),
      paneBodyBuilder: (item, body) {
        return Container(
          color: fTheme.cardColor,
          padding: EdgeInsets.zero,
          child: body ?? const SizedBox.shrink(),
        );
      },
      pane: NavigationPane(
        selected: index,
        onChanged: (i) => ref.read(appNavigationIndexProvider.notifier).state = i,
        displayMode: PaneDisplayMode.auto,
        size: const NavigationPaneSize(openWidth: AppSpacing.navigationPaneSize),
        indicator: null,
        items: items,
      ),
    );
  }

  static Icon _icon(BuildContext context, IconData data) {
    final t = FluentTheme.of(context);
    return Icon(data, size: 18.0, color: t.accentColor.normal);
  }

  static WidgetStateProperty<Color> _selectedTile(BuildContext context) {
    final t = FluentTheme.of(context);
    final alpha = t.brightness == Brightness.light ? 36 : 52;
    return WidgetStatePropertyAll(t.accentColor.normal.withAlpha(alpha));
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

  static PaneItemAction _paneAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return PaneItemAction(
      icon: _icon(context, icon),
      title: Text(title, style: AppTypography.navigationPane),
      onTap: onTap,
    );
  }

  // ignore: unused_element TODO 추후 확장용
  PaneItem _paneItemExpander({
    required IconData icon,
    required String title,
    required BuildContext context,
    required Widget body,
    required List<NavigationPaneItem> items,
  }) {
    final fTheme = FluentTheme.of(context);

    return PaneItemExpander(
      icon: Icon(
        icon,
        size: 18.0,
        color: fTheme.accentColor.normal,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: body,
      selectedTileColor: WidgetStateProperty.resolveWith((states) {
        final isLight = fTheme.brightness == Brightness.light;
        final base = fTheme.accentColor.normal;
        final alpha = isLight ? 36 : 52;
        return base.withAlpha(alpha);
      }),
      items: items,
    );
  }
}
