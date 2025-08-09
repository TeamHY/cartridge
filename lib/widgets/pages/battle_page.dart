import 'dart:convert';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/constants/urls.dart';

class BattlePage extends ConsumerStatefulWidget {
  const BattlePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BattlePageState();
}

class _BattlePageState extends ConsumerState<BattlePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    ref.read(storeProvider.notifier).checkAstroVersion();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    ref.read(storeProvider.notifier).checkAstroVersion();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final store = ref.watch(storeProvider);
    final baseColor =
        store.isAstroOutdated ? Colors.red.light : Colors.blue.lightest;

    return NavigationView(
      content: DragToMoveArea(
        child: Stack(
          children: [
            Container(
              color: baseColor,
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            loc.battle_title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const QuickAction(),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      loc.battle_current_version,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        fontFamily: 'Pretendard',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      store.astroLocalVersion ?? loc.battle_not_installed,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Pretendard',
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      loc.battle_latest_version,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        fontFamily: 'Pretendard',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      store.astroRemoteVersion ?? loc.battle_unknown_version,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Pretendard',
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            IconButton(
                              style: const ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side: BorderSide(
                                        width: 1, color: Colors.white),
                                  ),
                                ),
                              ),
                              icon: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  FluentIcons.play_solid,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              iconButtonMode: IconButtonMode.large,
                              onPressed: () async {
                                final response = await http.get(Uri.https(
                                    'raw.githubusercontent.com',
                                    'TeamHY/cartridge/main/assets/battle_presets.json'));

                                if (response.statusCode != 200) {
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return ContentDialog(
                                          title: Text(loc.common_error),
                                          content: Text(response.body),
                                          actions: [
                                            FilledButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(loc.common_close),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }

                                  return;
                                }

                                final json = jsonDecode(response.body)
                                    .cast<Map<String, dynamic>>();
                                final mods = List<Mod>.from(
                                    json.map((e) => Mod.fromJson(e)));

                                if (store.isAstroOutdated && context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return ContentDialog(
                                        title: Text(loc.battle_warning_title),
                                        content: Text(loc.battle_warning_message),
                                        actions: [
                                          Button(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(loc.common_cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              store.applyPreset(
                                                Preset(name: '', mods: mods),
                                                isForceRerun: true,
                                                isForceUpdate: true,
                                              );
                                              Navigator.pop(context);
                                            },
                                            child: Text(loc.common_confirm),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  return;
                                }

                                store.applyPreset(Preset(name: '', mods: mods),
                                    isForceRerun: true);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  iconButtonMode: IconButtonMode.large,
                  icon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      FluentIcons.back,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 138,
                  height: 50,
                  child: WindowCaption(
                    brightness: Brightness.dark,
                    backgroundColor: Colors.transparent,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HyperlinkButton(
          child: Text(
            loc.battle_manual_update,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w200,
              fontFamily: 'Pretendard',
            ),
          ),
          onPressed: () => launchUrl(
            Uri.parse(AppUrls.manualUpdatePost),
          ),
        ),
        HyperlinkButton(
          child: Text(
            loc.battle_patch_notes,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w200,
              fontFamily: 'Pretendard',
            ),
          ),
          onPressed: () => launchUrl(
            Uri.parse(AppUrls.steamAstrobirthPatchNotes),
          ),
        ),
      ],
    );
  }
}
