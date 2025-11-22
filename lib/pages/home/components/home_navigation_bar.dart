import 'package:cartridge/pages/record/record_page.dart';
import 'package:cartridge/pages/slot_machine/slot_machine_page.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeNavigationBar extends ConsumerWidget {
  const HomeNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

    return Row(
      children: [
        Button(
          onPressed: () => Navigator.push(
            context,
            FluentPageRoute(
              builder: (context) => const RecordPage(),
            ),
          ),
          child: Text(loc.home_button_record),
        ),
        const SizedBox(width: 4),
        Button(
          onPressed: () => Navigator.push(
            context,
            FluentPageRoute(
              builder: (context) => const SlotMachinePage(),
            ),
          ),
          child: Text(loc.home_button_slot_machine),
        ),
        const SizedBox(width: 4),
        Button(
          onPressed: () => store.applyPreset(
            null,
            isEnableMods: false,
            isDebugConsole: false,
          ),
          child: Text(loc.home_button_daily_run),
        ),
      ],
    );
  }
}
