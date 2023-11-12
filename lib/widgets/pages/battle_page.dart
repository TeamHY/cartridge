import 'dart:convert';

import 'package:cartridge/models/mod.dart';
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

  String getInfoText() {
    final store = ref.watch(storeProvider);

    if (store.astroLocalVersion == null) {
      return '대결모드가 설치되지 않았습니다.';
    } else if (store.astroRemoteVersion == null) {
      return '최신 버전을 확인할 수 없습니다.';
    } else if (store.isAstroOutdated) {
      return '${store.astroLocalVersion} -> ${store.astroRemoteVersion}';
    } else {
      return '${store.astroLocalVersion}';
    }
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Astrobirth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    Text(
                      getInfoText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Pretendard',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    IconButton(
                      style: ButtonStyle(
                        border: ButtonState.all(
                          const BorderSide(width: 1, color: Colors.white),
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
                        final mods =
                            List<Mod>.from(json.map((e) => Mod.fromJson(e)));

                        if (store.isAstroOutdated && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return ContentDialog(
                                title: const Text('경고'),
                                content:
                                    const Text('원활한 업데이트를 위해 스팀이 강제 종료됩니다.'),
                                actions: [
                                  Button(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('취소'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      store.applyMods(
                                        mods,
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

                        store.applyMods(mods, isForceRerun: true);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: HyperlinkButton(
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
                            Uri.parse('https://tgd.kr/s/iwt2hw/72349813'))),
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
