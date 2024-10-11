import 'dart:convert';
import 'dart:io';

import 'package:cartridge/main.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/layout.dart';
import 'package:cartridge/widgets/option_preset_button.dart';
import 'package:cartridge/widgets/dialogs/option_preset_dialog.dart';
import 'package:cartridge/widgets/pages/battle_page.dart';
import 'package:cartridge/widgets/pages/slot_machine_page.dart';
import 'package:cartridge/widgets/preset_item.dart';
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
  late TextEditingController _presetNameController;
  late TextEditingController _searchController;

  void checkAppVersion() async {
    final response = await http.get(Uri.parse(
      'https://api.github.com/repos/TeamHY/cartridge/releases/latest',
    ));

    if (response.statusCode != 200) {
      return;
    }

    final latestVersion = Version.parse(jsonDecode(response.body)['tag_name']);

    if (currentVersion.nextMinor <= latestVersion && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('업데이트'),
            content: const Text('이 버전은 사용할 수 없습니다. 새로운 버전을 사용해 주세요.'),
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

    _presetNameController = TextEditingController();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });

    checkAppVersion();
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final currentMods = List<Mod>.from(store.currentMods)
        .where(
          (mod) =>
              mod.name.toLowerCase().replaceAll(RegExp('\\s'), "").contains(
                    _searchController.text
                        .toLowerCase()
                        .replaceAll(RegExp('\\s'), ""),
                  ),
        )
        .toList();

    currentMods.sort((a, b) {
      if (store.favorites.contains(a.name) &&
          !store.favorites.contains(b.name)) {
        return -1;
      } else if (!store.favorites.contains(a.name) &&
          store.favorites.contains(b.name)) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });

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
                              controller: _presetNameController,
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
                                    name: _presetNameController.value.text != ''
                                        ? _presetNameController.value.text
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
                            onApply: (Preset preset) async {
                              store.selectOptionPreset(preset.optionPresetId);
                              store.applyPreset(preset);

                              _presetNameController.text = preset.name;
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
                              oldPreset.optionPresetId =
                                  newPreset.optionPresetId;

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
                              onPressed: () => Navigator.push(
                                context,
                                FluentPageRoute(
                                  builder: (context) => const SlotMachinePage(),
                                ),
                              ),
                              child: const Text('슬롯 머신'),
                            ),
                            const SizedBox(width: 4),
                            Button(
                              onPressed: () => store.applyPreset(
                                null,
                                isEnableMods: false,
                              ),
                              child: const Text('데일리 런'),
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
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...store.optionPresets.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OptionPresetButton(
                                id: option.id,
                                checked:
                                    option.id == store.selectOptionPresetId,
                                onChanged: (value) {
                                  if (!value) {
                                    store.selectOptionPreset(
                                      null,
                                    );
                                    return;
                                  }

                                  store.isSync = false;
                                  store.selectOptionPreset(
                                    option.id,
                                  );
                                },
                                onEdited: (id) => showDialog(
                                  context: context,
                                  builder: (context) => OptionPresetDialog(
                                    id: id,
                                  ),
                                ),
                                onDeleted: (id) => showDialog(
                                  context: context,
                                  builder: (context) {
                                    return ContentDialog(
                                      title: const Text("프리셋 삭제"),
                                      content: const Text(
                                        "프리셋을 삭제하면 복구할 수 없습니다. 정말 삭제하시겠습니까?",
                                      ),
                                      actions: [
                                        Button(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("취소"),
                                        ),
                                        FilledButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                ButtonState.all<Color>(
                                                    Colors.red.dark),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            store.removeOptionPreset(id);
                                          },
                                          child: const Text('삭제'),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                content: option.name,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(FluentIcons.add),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const OptionPresetDialog(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: currentMods
                            .map(
                              (mod) => SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      ToggleSwitch(
                                        checked: !mod.isDisable,
                                        onChanged: (value) {
                                          setState(
                                            () {
                                              mod.isDisable = !value;
                                              store.isSync = false;
                                            },
                                          );
                                        },
                                        content: Text(
                                          mod.name,
                                          style: TextStyle(
                                            color: store.favorites
                                                    .contains(mod.name)
                                                ? Colors.blue
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            FluentIcons.folder_horizontal),
                                        onPressed: () => Process.run(
                                          'explorer "${mod.path.replaceAll(RegExp('/'), "\\")}"',
                                          [],
                                        ),
                                      ),
                                      ToggleButton(
                                        checked:
                                            store.favorites.contains(mod.name),
                                        onChanged: (value) {
                                          if (value) {
                                            store.addFavorite(mod.name);
                                          } else {
                                            store.removeFavorite(mod.name);
                                          }

                                          store.savePresets();
                                        },
                                        style: const ToggleButtonThemeData(
                                          checkedButtonStyle: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.transparent),
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsets.all(8),
                                            ),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(),
                                            ),
                                          ),
                                          uncheckedButtonStyle: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.transparent),
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsets.all(8),
                                            ),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(),
                                            ),
                                          ),
                                        ),
                                        child: store.favorites
                                                .contains(mod.name)
                                            ? const Icon(
                                                FluentIcons.favorite_star_fill)
                                            : const Icon(
                                                FluentIcons.favorite_star),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextBox(
                      controller: _searchController,
                      placeholder: '검색',
                      suffix: IgnorePointer(
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(FluentIcons.search),
                        ),
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
                                : () async {
                                    store.applyPreset(Preset(
                                      name: '',
                                      optionPresetId:
                                          store.selectOptionPresetId,
                                      mods: store.currentMods,
                                    ));
                                  },
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
