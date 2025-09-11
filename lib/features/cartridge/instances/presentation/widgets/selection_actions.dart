import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class SelectionInlineActions extends StatelessWidget {
  const SelectionInlineActions({
    super.key,
    required this.onShare,
    required this.showFavAdd,
    required this.showFavRemove,
    required this.showEnable,
    required this.showDisable,
    required this.onFavAdd,
    required this.onFavRemove,
    required this.onEnable,
    required this.onDisable,
  });

  final VoidCallback onShare;
  final bool showFavAdd, showFavRemove, showEnable, showDisable;
  final VoidCallback onFavAdd, onFavRemove, onEnable, onDisable;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton(onPressed: onShare, child: Text(loc.common_clipboard)),
        if (showFavAdd) Button(onPressed: onFavAdd, child: Text(loc.common_add_favorite)),
        if (showFavRemove) Button(onPressed: onFavRemove, child: Text(loc.common_remove_favorite)),
        if (showEnable) Button(onPressed: onEnable, child: Text(loc.common_enable_mod)),
        if (showDisable) Button(onPressed: onDisable, child: Text(loc.common_disable_mod)),
      ],
    );
  }
}
