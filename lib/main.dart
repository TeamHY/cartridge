import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
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
    return FluentApp(
      title: 'Cartridge',
      theme: FluentThemeData(
        fontFamily: 'Pretendard',
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

  if (!await directory.exists()) {
    return mods;
  }

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
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(widget.title),
        ),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.refresh),
              onPressed: () => reloadMods(),
            ),
            IconButton(
              icon: const Icon(FluentIcons.settings),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => ContentDialog(
                  title: const Text('설정'),
                  content: Column(
                    children: [
                      Row(
                        children: [],
                      ),
                    ],
                  ),
                  actions: [
                    Button(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        color: FluentTheme.of(context).menuColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: ScaffoldPage(
                header: const Text(
                  '프리셋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Flexible(
                            child: TextBox(
                              controller: _controller,
                              placeholder: '프리셋 이름',
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(FluentIcons.add),
                            onPressed: () {
                              setState(() {
                                _presets.add(
                                  Preset(
                                    name: _controller.value.text != ''
                                        ? _controller.value.text
                                        : '새 프리셋',
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
                    Container(
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context).menuColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Padding(
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
                              child: const Text('돌림판'),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: FluentTheme.of(context).cardColor,
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
                                    ToggleSwitch(
                                      checked: !mod.isDisable,
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
                          ToggleSwitch(
                            checked: isRerun,
                            onChanged: (value) =>
                                setState(() => isRerun = value),
                            content: const Text('자동 재시작'),
                          ),
                          Expanded(child: Container()),
                          HyperlinkButton(
                            onPressed: () => reloadMods(),
                            child: const Text("새로고침"),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: isSync ? null : () => applyMods(_mods),
                            child: const Text("적용"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
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
          IconButton(
            onPressed: () => onApply(preset),
            icon: const Icon(
              FluentIcons.play,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) {
                return PresetDialog(
                  preset: preset,
                  onEdit: onEdit,
                );
              },
            ),
            icon: const Icon(
              FluentIcons.edit,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) {
                return ContentDialog(
                  title: const Text("프리셋 삭제"),
                  content: const Text('프리셋을 삭제하면 복구할 수 없습니다. 정말 삭제하시겠습니까?'),
                  actions: [
                    Button(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            ButtonState.all<Color>(Colors.red.dark),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(preset);
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                );
              },
            ),
            icon: Icon(
              FluentIcons.delete,
              size: 16,
              color: Colors.red.dark,
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
    return ContentDialog(
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
                          ToggleButton(
                            checked: !mod.isDisable,
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
        Button(
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
    ..color = Colors.orange.light
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
        colorBuilder: (index) => Colors.blue.lightest,
        textBuilder: (index) => widget.presets[index].name,
        textStyleBuilder: (index) => const TextStyle(
          color: Colors.black,
          fontSize: 16,
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
    return ContentDialog(
      title: const Text("돌림판"),
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
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("취소"),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              index = random.nextInt(widget.presets.length);
            });

            controller.rollTo(index, offset: random.nextDouble()).then(
                  (value) => showDialog(
                    context: context,
                    builder: (context) => ContentDialog(
                      title: Text(widget.presets[index].name),
                      content: const Text("이 프리셋을 적용하시겠습니까?"),
                      actions: [
                        Button(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("취소"),
                        ),
                        FilledButton(
                          onPressed: () {
                            widget.onApply(widget.presets[index]);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("적용"),
                        ),
                      ],
                    ),
                  ),
                );
          },
          child: const Text("추첨"),
        )
      ],
    );
  }
}
