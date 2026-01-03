import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class ModGroupSelectorDialog extends ConsumerWidget {
  const ModGroupSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final groups = store.groups;

    return ContentDialog(
      title: Text(AppLocalizations.of(context).select_mod_group),
      content: SizedBox(
        width: 400,
        height: 400,
        child: groups.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context).no_mod_groups),
              )
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final groupName = groups.keys.elementAt(index);
                  final modCount = groups[groupName]?.length ?? 0;

                  return ListTile.selectable(
                    title: Text(groupName),
                    subtitle: Text('$modCount mods'),
                    onPressed: () => Navigator.of(context).pop(groupName),
                  );
                },
              ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).common_cancel),
        ),
      ],
    );
  }
}
