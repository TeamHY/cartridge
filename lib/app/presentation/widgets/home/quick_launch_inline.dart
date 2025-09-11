import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/controllers/home_controller.dart';
import 'package:cartridge/app/presentation/widgets/home/game_play_split_button.dart';
import 'package:cartridge/app/presentation/widgets/home/ut_split_button.dart';
import 'package:cartridge/app/presentation/widgets/home/vanilla_play_split_button.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class QuickLaunchInline extends ConsumerWidget {
  const QuickLaunchInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final accent2 = accent2Of(context, ref);

    Widget vanillaButtons(Color color) {
      final optionsAsync = ref.watch(optionPresetsControllerProvider);
      return optionsAsync.when(
        loading: () => UtSplitButton.single(
          mainButtonText: loc.vanilla_play_button_title,
          secondaryText: loc.common_loading,
          buttonColor: fTheme.accentColor,
          onPressed: null,
          enabled: false,
        ),
        error: (_, __) => UtSplitButton.single(
          mainButtonText: loc.vanilla_play_button_title,
          secondaryText: loc.vanilla_play_check_failed,
          buttonColor: fTheme.accentColor,
          onPressed: null,
          enabled: false,
        ),
        data: (list) => VanillaPlaySplitButton(
          optionPresets: list,
          buttonColor: color,
        ),
      );
    }

    final instancesAsync = ref.watch(instancesControllerProvider);

    return instancesAsync.when(
      loading: () => Row(
        children: [
          Expanded(
            child: UtSplitButton.single(
              mainButtonText: loc.play_instance_button_title,
              secondaryText: loc.common_loading,
              buttonColor: fTheme.accentColor,
              onPressed: null,
              enabled: false,
            ),
          ),
          Gaps.w8,
          Expanded(child: vanillaButtons(accent2.normal)),
        ],
      ),

      error: (_, __) => Row(
        children: [
          Expanded(
            child: UtSplitButton.single(
              mainButtonText: loc.play_instance_button_title,
              secondaryText: loc.quick_launch_instances_failed,
              buttonColor: fTheme.accentColor,
              onPressed: null,
              enabled: false,
            ),
          ),
          Gaps.w8,
          Expanded(child: vanillaButtons(accent2.normal)),
        ],
      ),

      data: (list) {
        final recentId = ref.watch(recentInstanceIdProvider);
        final InstanceView? recent = () {
          final byId = (recentId == null)
              ? null
              : list.firstWhere(
                (v) => v.id == recentId,
            orElse: () => InstanceView.empty,
          );
          if (byId != null && byId.id.isNotEmpty) return byId;
          if (list.isEmpty) return null;
          return list.first;
        }();

        return Row(
          children: [
            if (recent != null) ...[
              Expanded(
                child: GamePlaySplitButton(
                  instances: list,
                  buttonColor: fTheme.accentColor,
                ),
              ),
            ] else ...[
              Expanded(
                child: UtSplitButton.single(
                  mainButtonText: loc.play_instance_button_title,
                  secondaryText: loc.quick_launch_no_instances,
                  buttonColor: fTheme.accentColor,
                  onPressed: null,
                  enabled: false,
                ),
              ),
            ],
            Gaps.w8,
            Expanded(child: vanillaButtons(accent2.normal)),
          ],
        );
      },
    );
  }
}
