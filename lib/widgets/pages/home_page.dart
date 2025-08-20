import 'dart:convert';
import 'dart:io';

import 'package:cartridge/main.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/layout.dart';
import 'package:cartridge/widgets/pages/record_page.dart';
import 'package:cartridge/widgets/pages/slot_machine_page.dart';
import 'package:cartridge/widgets/preset_item.dart';
import 'package:cartridge/widgets/preset_edit_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/constants/urls.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late TextEditingController _presetNameController;
  late TextEditingController _searchController;
  late TextEditingController _editPresetNameController;
  Preset? _selectedPreset;
  bool _isPresetEditing = false;

  void checkAppVersion() async {
    final response = await http.get(Uri.parse(AppUrls.githubApiLatestRelease));

    if (response.statusCode != 200) {
      return;
    }
    final loc = AppLocalizations.of(context);

    final latestVersion = Version.parse(jsonDecode(response.body)['tag_name']);

    if (currentVersion.nextMinor <= latestVersion && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: Text(loc.home_dialog_update_title),
            content: Text(loc.home_dialog_update_required),
            actions: [
              FilledButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(AppUrls.githubLatestRelease));
                  exit(0);
                },
                child: Text(loc.common_confirm),
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
            title: Text(loc.home_dialog_update_title),
            content: Text(loc.home_dialog_update_optional),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.common_cancel),
              ),
              FilledButton(
                onPressed: () {
                  launchUrl(Uri.parse(AppUrls.githubLatestRelease));
                  Navigator.pop(context);
                },
                child: Text(loc.common_confirm),
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
    _editPresetNameController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });

    checkAppVersion();
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    _searchController.dispose();
    _editPresetNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

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
                    Expanded(
                      child: store.presets.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FluentIcons.playlist_music,
                                      size: 48,
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '저장된 프리셋이 없어요',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Colors.grey.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '아래에서 새로운 프리셋을\n생성할 수 있어요',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Colors.grey.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              itemCount: store.presets.length,
                              itemBuilder: (context, index) =>
                                  ReorderableDragStartListener(
                                key: ValueKey(store.presets[index]),
                                index: index,
                                child: PresetItem(
                                  preset: store.presets[index],
                                  isSelected:
                                      _selectedPreset == store.presets[index],
                                  onTap: () => setState(() {
                                    _selectedPreset = store.presets[index];
                                    _editPresetNameController.text =
                                        store.presets[index].name;
                                    _isPresetEditing = true;
                                  }),
                                  onApply: (Preset preset) async {
                                    store.selectOptionPreset(
                                        preset.optionPresetId);
                                    store.applyPreset(preset);

                                    _presetNameController.text = preset.name;
                                  },
                                  onDelete: (Preset preset) {
                                    setState(() {
                                      store.presets.remove(preset);
                                      store.savePresets();
                                      if (_selectedPreset?.name ==
                                          preset.name) {
                                        _selectedPreset = null;
                                        _isPresetEditing = false;
                                      }
                                    });
                                  },
                                  onEdit: (preset) => setState(() {
                                    _selectedPreset = preset;
                                    _editPresetNameController.text =
                                        preset.name;
                                    _isPresetEditing = true;
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Flexible(
                            child: TextBox(
                              controller: _presetNameController,
                              placeholder: loc.home_preset_placeholder,
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
                                        : loc.home_preset_placeholder,
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
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 248, 252),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                  builder: (context) => const RecordPage(),
                                ),
                              ),
                              child: Text(loc.home_button_record),
                            ),
                            const SizedBox(width: 4),
                            Button(
                              onPressed: () => Navigator.push(
                                context,
                                FluentPageRoute(
                                  builder: (context) => const SlotMachinePage(),
                                ),
                              ),
                              child: Text(loc.home_button_slot_machine),
                            ),
                            const SizedBox(width: 4),
                            Button(
                              onPressed: () => store.applyPreset(
                                null,
                                isEnableMods: false,
                                isDebugConsole: false,
                              ),
                              child: Text(loc.home_button_daily_run),
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
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1), width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                ),
              ),
              child: _isPresetEditing && _selectedPreset != null
                  ? PresetEditView(
                      selectedPreset: _selectedPreset!,
                      editPresetNameController: _editPresetNameController,
                      searchController: _searchController,
                      onCancel: () => setState(() {
                        _isPresetEditing = false;
                        _selectedPreset = null;
                      }),
                      onSave: (mods) {
                        _selectedPreset!.mods = mods;
                        store.savePresets();
                        setState(() {
                          _isPresetEditing = false;
                        });
                      },
                    )
                  : _buildNormalView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalView() {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              '프리셋을 선택해주세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextBox(
            controller: _searchController,
            placeholder: loc.common_search_placeholder,
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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 60,
          ),
          // child: Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Checkbox(
          //         content: Text(loc.home_checkbox_rerun),
          //         checked: store.isRerun,
          //         onChanged: (value) => setState(() {
          //           store.isRerun = value!;
          //         }),
          //       ),
          //       Row(
          //         spacing: 8,
          //         children: [
          //           FilledButton(
          //             onPressed: store.isSync
          //                 ? null
          //                 : () async {
          //                     await store.saveMods(store.currentMods);
          //                     setState(() {
          //                       store.isSync = true;
          //                     });
          //                   },
          //             child: Text(loc.common_save),
          //           ),
          //           FilledButton(
          //             onPressed: () async {
          //               store.applyPreset(Preset(
          //                 name: '',
          //                 optionPresetId: store.selectOptionPresetId,
          //                 mods: store.currentMods,
          //               ));
          //             },
          //             child: const Text("시작"),
          //           ),
          //         ],
          //       )
          //     ],
          //   ),
          // ),
        )
      ],
    );
  }
}
