import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/controllers/home_controller.dart';
import 'package:cartridge/app/presentation/widgets/home/game_play_split_button.dart';
import 'package:cartridge/app/presentation/widgets/home/ut_split_button.dart';
import 'package:cartridge/app/presentation/widgets/home/vanilla_play_split_button.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/theme/theme.dart';

class QuickLaunchInline extends ConsumerWidget {
  const QuickLaunchInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FluentTheme.of(context);
    final instancesAsync = ref.watch(instancesControllerProvider);
    final sem = ref.watch(themeSemanticsProvider);

    Widget vanillaButtons(Color color) {
      final optionsAsync = ref.watch(optionPresetsControllerProvider);
      return optionsAsync.when(
        loading: () => UtSplitButton.single(
          mainButtonText: '바닐라 플레이',
          secondaryText: '프리셋 로딩 중…',
          buttonColor: fTheme.accentColor,
          onPressed: null,
          enabled: false,
        ),
        error: (e, st) => UtSplitButton.single(
          mainButtonText: '바닐라 플레이',
          secondaryText: '오류',
          buttonColor: fTheme.accentColor,
          onPressed: null,
          enabled: false,
        ),
        data: (List<OptionPresetView> list) {
          return VanillaPlaySplitButton(optionPresets: list, buttonColor: color);
        },
      );
    }

    return instancesAsync.when(
      loading: () => const SizedBox(height: 36, child: ProgressBar()),
      error: (e, _) => Text('인스턴스 로딩 실패: $e'),
      data: (list) {
        final recentId = ref.watch(recentInstanceIdProvider);
        final InstanceView? recent = () {
          final byId = (recentId == null) ? null : list.firstWhere((v) => v.id == recentId, orElse: () => InstanceView.empty);
          if (byId != null && byId.id.isNotEmpty) return byId;
          if (list.isEmpty) return null;
          return list.first; // fallback: first
        }();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // Changed from Column to Row
              children: [
                // Split button: left run, right menu
                if (recent != null) ...[
                  Expanded(
                    child: GamePlaySplitButton(
                      instances: list,
                      buttonColor: fTheme.accentColor, // Updated color to use theme
                    ),
                  ),
                  Gaps.w8,
                ] else ...[
                  Expanded(
                    child: UtSplitButton.single(
                      mainButtonText: '인스턴스 플레이',
                      secondaryText: '인스턴스 없음',
                      buttonColor: fTheme.accentColor,
                      onPressed: null,
                      enabled: false,
                    ),
                  ),
                  Gaps.w8,
                ],

                // Vanilla run buttons
                Expanded(
                  child: vanillaButtons(sem.neutral.fg), // Updated color to use theme
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}