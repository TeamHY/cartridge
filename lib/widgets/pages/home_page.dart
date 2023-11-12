import 'dart:convert';
import 'dart:io';

import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/layout.dart';
import 'package:cartridge/widgets/pages/battle_page.dart';
import 'package:cartridge/widgets/preset_item.dart';
import 'package:cartridge/widgets/roulette_dialog.dart';
import 'package:cartridge/widgets/setting_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late TextEditingController _controller;

  void checkAppVersion() async {
    final response = await http.get(Uri.parse(
      'https://api.github.com/repos/TeamHY/cartridge/releases/latest',
    ));

    if (response.statusCode != 200) {
      return;
    }

    final latestVersion = Version.parse(jsonDecode(response.body)['tag_name']);

    if (currentVersion.nextBreaking <= latestVersion && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('업데이트'),
            content: const Text('너무 오래된 버전입니다. 새로운 버전을 사용해 주세요.'),
            actions: [
              FilledButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(
                      'https://github.com/TeamHY/cartridge/releases/latest'));
                  exit(0);
                },
                child: const Text('확인'),
              )
            ],
          );
        },
      );
    } else if (currentVersion < latestVersion && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('업데이트'),
            content: const Text('새로운 버전을 다운로드 받으시겠습니까?'),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  launchUrl(Uri.parse(
                      'https://github.com/TeamHY/cartridge/releases/latest'));
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              )
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();

    checkAppVersion();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);

    return Layout(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: material.Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Flexible(
                            child: TextBox(
                              controller: _controller,
                              placeholder: '새 프리셋',
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(FluentIcons.add),
                            onPressed: () {
                              setState(() {
                                store.presets.add(
                                  Preset(
                                    name: _controller.value.text != ''
                                        ? _controller.value.text
                                        : '새 프리셋',
                                    mods: store.currentMods
                                        .map(
                                            (mod) => Mod.fromJson(mod.toJson()))
                                        .toList(),
                                  ),
                                );
                                store.savePresets();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: store.presets.length,
                        itemBuilder: (context, index) =>
                            ReorderableDragStartListener(
                          key: ValueKey(store.presets[index]),
                          index: index,
                          child: PresetItem(
                            preset: store.presets[index],
                            onApply: (Preset preset) {
                              store.applyMods(preset.mods);
                              _controller.text = preset.name;
                            },
                            onDelete: (Preset preset) {
                              setState(() {
                                store.presets.remove(preset);
                                store.savePresets();
                              });
                            },
                            onEdit: (oldPreset, newPreset) => setState(() {
                              oldPreset.name = newPreset.name;
                              oldPreset.mods = newPreset.mods;

                              store.savePresets();
                            }),
                          ),
                        ),
                        onReorder: ((oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }

                            final item = store.presets.removeAt(oldIndex);
                            store.presets.insert(newIndex, item);
                          });
                        }),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 248, 252),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Button(
                              onPressed: () => Navigator.push(
                                context,
                                FluentPageRoute(
                                  builder: (context) => const BattlePage(),
                                ),
                              ),
                              child: const Text('대결 모드'),
                            ),
                            const SizedBox(width: 4),
                            Button(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) {
                                  return RouletteDialog(
                                    presets: store.presets,
                                    onApply: (Preset preset) {
                                      store.applyMods(preset.mods);
                                      _controller.text = preset.name;
                                    },
                                  );
                                },
                              ),
                              child: const Text('돌림판'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FluentTheme.of(context).cardColor,
                border:
                    Border.all(color: Colors.black.withOpacity(0.1), width: 1),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: store.currentMods
                            .map(
                              (mod) => SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ToggleSwitch(
                                    checked: !mod.isDisable,
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          mod.isDisable = !value;
                                          store.isSync = false;
                                        },
                                      );
                                    },
                                    content: Text(mod.name),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Checkbox(
                            content: const Text('자동 재시작'),
                            checked: store.isRerun,
                            onChanged: (value) => setState(() {
                              store.isRerun = value!;
                            }),
                          ),
                          FilledButton(
                            onPressed: store.isSync
                                ? null
                                : () => store.applyMods(store.currentMods),
                            child: const Text("적용"),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
