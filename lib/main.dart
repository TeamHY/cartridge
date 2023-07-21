import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roulette/roulette.dart';
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
      title: 'Cartridge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Cartridge'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

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

class _MyHomePageState extends State<MyHomePage> {
  List<Preset> _presets = [];

  List<Mod> _mods = [];

  bool isSync = false;
  bool isRerun = true;

  late TextEditingController _controller;

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

    if (isRerun) {
      await Process.run('taskkill', ['/im', 'isaac-ng.exe']);
      await Process.run(
          'C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth\\isaac-ng.exe',
          []);
    }
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
                    padding: const EdgeInsets.all(16.0),
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
                                      .map((mod) => Mod.fromJson(mod.toJson()))
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
                          onEdit: (oldPreset, newPreset) => setState(() {
                            oldPreset.name = newPreset.name;
                            oldPreset.mods = newPreset.mods;

                            savePresets();
                          }),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: _presets.isEmpty
                              ? null
                              : () => showDialog(
                                    context: context,
                                    builder: (context) {
                                      return RouletteDialog(
                                        presets: _presets,
                                        onApply: (Preset preset) {
                                          applyMods(preset.mods);
                                          _controller.text = preset.name;
                                        },
                                      );
                                    },
                                  ),
                          child: const Text("Roulette"),
                        ),
                      ],
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
                    padding: const EdgeInsets.all(16.0),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Rerun'),
                      Switch(
                        value: isRerun,
                        onChanged: (value) => setState(() => isRerun = value),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
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
      ),
    );
  }
}

class PresetItem extends StatelessWidget {
  const PresetItem({
    super.key,
    required this.preset,
    required this.onApply,
    required this.onDelete,
    required this.onEdit,
  });

  final Preset preset;

  final Function(Preset preset) onApply;

  final Function(Preset preset) onDelete;

  final Function(Preset oldPreset, Preset newPreset) onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: Text(preset.name)),
          InkWell(
            onTap: () => onApply(preset),
            child: const Icon(
              Icons.play_arrow,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return PresetDialog(
                  preset: preset,
                  onEdit: onEdit,
                );
              },
            ),
            child: const Icon(
              Icons.edit,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Delete Preset"),
                  content: const Text(
                      "Are you sure you want to delete this preset?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(preset);
                      },
                      child: const Text("Delete"),
                    ),
                  ],
                );
              },
            ),
            child: Icon(
              Icons.delete,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
          )
        ],
      ),
    );
  }
}

class PresetDialog extends StatefulWidget {
  const PresetDialog({
    super.key,
    required this.preset,
    required this.onEdit,
  });

  final Preset preset;
  final Function(Preset oldPreset, Preset newPreset) onEdit;

  @override
  State<PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends State<PresetDialog> {
  bool isChanged = false;
  late Preset newPreset;

  @override
  void initState() {
    super.initState();

    newPreset = Preset(name: widget.preset.name, mods: []);

    loadMods().then(
      (value) async => setState(
        () {
          newPreset.mods = value
              .map(
                (mod) => Mod(
                  name: mod.name,
                  path: mod.path,
                  isDisable: widget.preset.mods
                      .firstWhere(
                        (element) => element.name == mod.name,
                        orElse: () => Mod(
                          name: "Null",
                          path: "Null",
                          isDisable: true,
                        ),
                      )
                      .isDisable,
                ),
              )
              .toList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.preset.name),
      content: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: newPreset.mods
                    .map(
                      (mod) => Row(
                        children: [
                          Switch(
                            value: !mod.isDisable,
                            onChanged: (value) {
                              setState(() {
                                mod.isDisable = !value;
                                isChanged = true;
                              });
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: isChanged
              ? () {
                  widget.onEdit(widget.preset, newPreset);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Apply"),
        ),
      ],
    );
  }
}

class Arrow extends StatelessWidget {
  const Arrow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 36,
      child: CustomPaint(painter: _ArrowPainter()),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final _paint = Paint()
    ..color = Colors.deepOrange.shade500
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(0, 0)
      ..relativeLineTo(size.width / 2, size.height)
      ..relativeLineTo(size.width / 2, -size.height)
      ..close();
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouletteDialog extends StatefulWidget {
  const RouletteDialog(
      {super.key, required this.presets, required this.onApply});

  final List<Preset> presets;
  final Function(Preset preset) onApply;

  @override
  State<RouletteDialog> createState() => _RouletteDialogState();
}

class _RouletteDialogState extends State<RouletteDialog>
    with TickerProviderStateMixin {
  final Random random = Random();

  late RouletteController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();

    controller = RouletteController(
      group: RouletteGroup.uniform(
        widget.presets.length,
        colorBuilder: (index) => Colors.orange.shade200,
        textBuilder: (index) => widget.presets[index].name,
        textStyleBuilder: (index) => const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      vsync: this,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Roulette"),
      content: Stack(alignment: Alignment.topCenter, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Roulette(
            controller: controller,
            style: const RouletteStyle(centerStickSizePercent: 0),
          ),
        ),
        const Arrow()
      ]),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              index = random.nextInt(widget.presets.length);
            });

            controller.rollTo(index, offset: random.nextDouble()).then(
                  (value) => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(widget.presets[index].name),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        FilledButton(
                          onPressed: () {
                            widget.onApply(widget.presets[index]);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ),
                );
          },
          child: const Text("Roll"),
        )
      ],
    );
  }
}
