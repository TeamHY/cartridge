import 'dart:convert';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Astrobirth',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          QuickAction(),
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
                                    const Text(
                                      '현재 버전',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        fontFamily: 'Pretendard',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      store.astroLocalVersion ?? '설치되지 않음',
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
                                    const Text(
                                      '최신 버전',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        fontFamily: 'Pretendard',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      store.astroRemoteVersion ?? '확인되지 않음',
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
                                          title: const Text('오류'),
                                          content: Text(response.body),
                                          actions: [
                                            FilledButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('닫기'),
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
                                        title: const Text('경고'),
                                        content: const Text(
                                            '원활한 업데이트를 위해 스팀이 강제 종료됩니다.'),
                                        actions: [
                                          Button(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('취소'),
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
                                            child: const Text('확인'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HyperlinkButton(
          child: const Text(
            '수동 업데이트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w200,
              fontFamily: 'Pretendard',
            ),
          ),
          onPressed: () => launchUrl(
            Uri.parse(
              'https://cafe.naver.com/iwt2hw/128',
            ),
          ),
        ),
        HyperlinkButton(
          child: const Text(
            '패치노트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w200,
              fontFamily: 'Pretendard',
            ),
          ),
          onPressed: () => launchUrl(
            Uri.parse(
              'https://steamcommunity.com/sharedfiles/filedetails/changelog/2492350811',
            ),
          ),
        ),
      ],
    );
  }
}
