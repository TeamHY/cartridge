import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';


Future<void> showAllowedModsDialog(
    BuildContext context,
    WidgetRef ref, {
      required UTTableController<AllowedModRow> controller,
      required List<AllowedModRow> rows,
    }) async {
  final uiCtl = ref.read(recordModeUiControllerProvider.notifier);
  final loc = AppLocalizations.of(context);

  await showDialog(
    context: context,
    builder: (ctx) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 980),
      title: Text(loc.allowed_dialog_title),
      content: SizedBox(
        width: 940,
        height: 560,
        child: AllowedModsTable(controller: controller, rows: rows),
      ),
      actions: [
        Button(
          child: Text(loc.common_refresh),
          onPressed: () async {
            await uiCtl.refreshAllowedPreset();
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop(); // 간단히 닫았다가 다시 열 수 있게
          },
        ),
        Button(child: Text(loc.common_close), onPressed: () => Navigator.of(ctx).pop()),
      ],
    ),
  );
}
