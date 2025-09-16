import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/l10n/app_localizations.dart';


Future<void> showAllowedModsDialog(
    BuildContext context,
    WidgetRef ref, {
      required UTTableController<AllowedModRow> controller,
    }) async {
  final uiCtl = ref.read(recordModeUiControllerProvider.notifier);
  final loc = AppLocalizations.of(context);

  await showDialog(
    context: context,
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final ui = ref.watch(recordModeUiControllerProvider);
          final rows = ui.preset?.items ?? const <AllowedModRow>[];

          return ContentDialog(
            title: Text(loc.allowed_dialog_title),
            constraints: const BoxConstraints(maxWidth: 780, maxHeight: 640),
            content: SizedBox(
              width: double.infinity,
              child: AllowedModsTable(controller: controller, rows: rows),
            ),
            actions: [
              Button(
                child: Text(loc.common_refresh),
                onPressed: () async {
                  await uiCtl.refreshAllowedPreset();
                  if (!ctx.mounted) return;
                  UiFeedback.info(ctx, title: loc.common_refresh, content: loc.allowed_mod_refresh);
                },
              ),
              Button(child: Text(loc.common_close),
                  onPressed: () => Navigator.of(ctx).pop()),
            ],
          );
        },
      );
    },
  );
}
