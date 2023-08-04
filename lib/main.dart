import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/setting_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roulette/roulette.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(600, 300),
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Cartridge',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: NavigationPaneTheme(
            data: const NavigationPaneThemeData(
              backgroundColor: Color.fromARGB(255, 245, 248, 252),
            ),
            child: child!,
          ),
        );
      },
      home: const MyHomePage(title: 'Cartridge'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

Future<List<Mod>> loadMods(String path) async {
  final mods = <Mod>[];

  final directory = Directory('$path\\mods');

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

  mods.sort((a, b) => a.name.compareTo(b.name));

  return mods;
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  List<Preset> _presets = [];

  List<Mod> _mods = [];

  bool isSync = false;
  bool isRerun = true;

  late TextEditingController _controller;

  void reloadMods() {
    final path = ref.read(settingProvider).isaacPath;

    loadMods(path).then(
      (value) => setState(
        () {
          _mods = value;
          isSync = true;
        },
      ),
    );
  }

  void applyMods(List<Mod> mods) async {
    final path = ref.read(settingProvider).isaacPath;

    final currentMods = await loadMods(path);

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
      await Process.run('$path\\isaac-ng.exe', []);
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

    Future.delayed(const Duration(milliseconds: 100), () {
      ref.read(settingProvider.notifier).loadSetting();

      reloadMods();
      loadPresets();
    });
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
        title: DragToMoveArea(
          child: Row(children: [
            Text(widget.title),
            const SizedBox(width: 8.0),
            MediaQuery.of(context).size.width <= 800
                ? const QuickBar()
                : Container(),
          ]),
        ),
        actions: Stack(
          children: [
            MediaQuery.of(context).size.width > 800
                ? const Center(child: QuickBar())
                : Container(),
            Row(
              children: [
                Expanded(child: Container()),
                IconButton(
                  icon: const Icon(FluentIcons.refresh, size: 20),
                  onPressed: () => reloadMods(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(FluentIcons.settings, size: 20),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const SettingDialog(),
                  ),
                ),
                const SizedBox(width: 4),
                const SizedBox(
                  width: 138,
                  height: 50,
                  child: WindowCaption(
                    // brightness: theme.brightness,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: material.Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Container(
                      color: Colors.blue.lightest,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "대결",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
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
                                          title: const Text("오류"),
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

                                applyMods(List<Mod>.from(
                                    json.map((e) => Mod.fromJson(e))));
                              },
                              icon: const Icon(
                                color: Colors.white,
                                FluentIcons.play,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        children: _mods
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
                                          isSync = false;
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
                            checked: isRerun,
                            onChanged: (value) => setState(() {
                              isRerun = value!;
                            }),
                          ),
                          FilledButton(
                            onPressed: isSync ? null : () => applyMods(_mods),
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

class QuickBar extends StatelessWidget {
  const QuickBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
            onPressed: () async {
              await launchUrl(
                  Uri.parse('https://www.youtube.com/@HeonYeong_Isaac'));
              await launchUrl(Uri.parse('https://www.twitch.tv/iwt2hw'));
            },
            child: const Text('생방송')),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse('https://tgd.kr/s/iwt2hw/70142711')),
            child: const Text('오픈채팅')),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse('https://tgd.kr/s/iwt2hw/56745938')),
            child: const Text('대결모드')),
        const SizedBox(width: 4),
        Button(
            onPressed: () => showDialog(
                  context: context,
                  builder: (context) => ContentDialog(
                    title: const Text('후원'),
                    content: SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("아래 QR코드를 인식하시면 후원이 가능합니다.",
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Image.network(
                              'https://raw.githubusercontent.com/TeamHY/cartridge/main/assets/images/donation_qr.png'),
                          const SizedBox(height: 8),
                          Image.asset(
                              'assets/images/payment_icon_yellow_small.png'),
                        ],
                      ),
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
            child: const Text('후원')),
      ],
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
              color: Colors.red.dark,
            ),
          )
        ],
      ),
    );
  }
}

class PresetDialog extends ConsumerStatefulWidget {
  const PresetDialog({
    super.key,
    required this.preset,
    required this.onEdit,
  });

  final Preset preset;
  final Function(Preset oldPreset, Preset newPreset) onEdit;

  @override
  ConsumerState<PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends ConsumerState<PresetDialog> {
  bool isChanged = false;
  late Preset newPreset;

  @override
  void initState() {
    super.initState();

    newPreset = Preset(name: widget.preset.name, mods: []);

    final path = ref.read(settingProvider).isaacPath;

    loadMods(path).then(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ToggleSwitch(
                              checked: !mod.isDisable,
                              onChanged: (value) {
                                setState(() {
                                  mod.isDisable = !value;
                                  isChanged = true;
                                });
                              },
                              content: Text(mod.name),
                            ),
                          ),
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
          child: const Text("취소"),
        ),
        FilledButton(
          onPressed: isChanged
              ? () {
                  widget.onEdit(widget.preset, newPreset);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("적용"),
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
          fontFamily: 'Pretendard',
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
            style: const RouletteStyle(
              centerStickSizePercent: 0,
            ),
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
