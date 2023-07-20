import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isaac_mod_preset/models/mod.dart';
import 'package:isaac_mod_preset/models/preset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Isaac Mod Preset'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Preset> _presets = [];

  List<Mod> _mods = [];

  bool isSync = false;

  late TextEditingController _controller;

  Future<List<Mod>> loadMods() async {
    final mods = <Mod>[];

    final directory = Directory(
        'C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth\\mods');

    for (var modDirectory in directory.listSync()) {
      final metadataFile = File('${modDirectory.path}\\metadata.xml');

      if (await metadataFile.exists()) {
        final document = XmlDocument.parse(await metadataFile.readAsString());

        final disableFile = File('${modDirectory.path}\\disable.it');

        final isDisable = await disableFile.exists();

        mods.add(
          Mod(
            name: document.xpath("/metadata/name").first.innerText,
            path: modDirectory.path,
            isDisable: isDisable,
          ),
        );
      }
    }

    return mods;
  }

  void reloadMods() {
    loadMods().then(
      (value) => setState(
        () {
          _mods = value;
          isSync = true;
        },
      ),
    );
  }

  void applyMods(List<Mod> mods) async {
    final currentMods = await loadMods();

    for (var mod in currentMods) {
      final isDisable = mods
          .firstWhere(
            (element) => element.name == mod.name,
            orElse: () => Mod(
              name: "Null",
              path: "Null",
              isDisable: true,
            ),
          )
          .isDisable;

      try {
        if (isDisable) {
          final disableFile = File('${mod.path}\\disable.it');

          disableFile.createSync();
        } else {
          final disableFile = File('${mod.path}\\disable.it');

          disableFile.deleteSync();
        }
      } catch (e) {
        //
      }
    }

    reloadMods();

    await Process.run('taskkill', ['/im', 'isaac-ng.exe']);
    await Process.run(
        'C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth\\isaac-ng.exe',
        []);
  }

  void loadPresets() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final file = File('${appDocumentsDir.path}\\presets.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as List<dynamic>;

    _presets = json.map((e) => Preset.fromJson(e)).toList();
  }

  void savePresets() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final file = File('${appDocumentsDir.path}\\presets.json');

    file.writeAsString(jsonEncode(_presets));
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();

    reloadMods();
    loadPresets();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Flexible(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _presets.add(
                                  Preset(
                                    name: _controller.value.text != ''
                                        ? _controller.value.text
                                        : 'New Preset',
                                    mods: _mods
                                        .map(
                                            (mod) => Mod.fromJson(mod.toJson()))
                                        .toList(),
                                  ),
                                );
                                savePresets();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: _presets.length,
                        itemBuilder: (context, index) =>
                            ReorderableDragStartListener(
                          key: ValueKey(_presets[index]),
                          index: index,
                          child: PresetItem(
                            preset: _presets[index],
                            onApply: (Preset preset) {
                              applyMods(preset.mods);
                              _controller.text = preset.name;
                            },
                            onDelete: (Preset preset) {
                              setState(() {
                                _presets.remove(preset);
                                savePresets();
                              });
                            },
                          ),
                        ),
                        onReorder: ((oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }

                            final item = _presets.removeAt(oldIndex);
                            _presets.insert(newIndex, item);
                          });
                        }),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _mods
                            .map(
                              (mod) => Row(
                                children: [
                                  Switch(
                                    value: !mod.isDisable,
                                    onChanged: (value) {
                                      setState(
                                        () {
                                          mod.isDisable = !value;
                                          isSync = false;
                                        },
                                      );
                                    },
                                  ),
                                  Text(mod.name),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => reloadMods(),
                          child: const Text("Reload"),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: isSync ? null : () => applyMods(_mods),
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }
}

class PresetItem extends StatelessWidget {
  const PresetItem({
    super.key,
    required this.preset,
    required this.onApply,
    required this.onDelete,
  });

  final Preset preset;

  final Function(Preset preset) onApply;

  final Function(Preset preset) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: Text(preset.name)),
          IconButton.outlined(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => onApply(preset),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            color: Theme.of(context).colorScheme.error,
            icon: const Icon(Icons.delete),
            onPressed: () => onDelete(preset),
          )
        ],
      ),
    );
  }
}
