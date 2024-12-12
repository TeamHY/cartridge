import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/daily_challenge.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/utils/isaac_log_file.dart';
import 'package:cartridge/utils/format_util.dart';
import 'package:cartridge/utils/process_util.dart';
import 'package:cartridge/utils/recorder_mod.dart';
import 'package:cartridge/widgets/back_arrow_view.dart';
import 'package:cartridge/widgets/daily_challenge_ranking.dart';
import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:cartridge/widgets/dialogs/sign_in_dialog.dart';
import 'package:cartridge/widgets/dialogs/sign_up_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

class RecorderState {
  RecorderState({
    this.character = 0,
    this.seed = '',
    this.isBossKilled = false,
  });

  int character;
  String seed;
  bool isBossKilled;
  Map<String, dynamic> data = {};
}

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> with WindowListener {
  final _stopwatch = Stopwatch();
  final _supabase = Supabase.instance.client;

  late Timer _timer;
  late StreamSubscription<AuthState> _authSubscription;
  late IsaacLogFile _logFile;

  DailyChallenge? _todayChallenge;
  RecorderState? _recorder = RecorderState();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    ref.read(storeProvider.notifier).checkAstroVersion();

    _timer = Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
      setState(() {
        if (_stopwatch.isRunning) {}
      });
    });

    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      setState(() {});
    });

    _logFile = IsaacLogFile(
      '$isaacDocumentPath\\log.txt',
      onMessage: onMessage,
    );

    refreshChallenge();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);

    _timer.cancel();
    _authSubscription.cancel();
    _logFile.dispose();

    super.dispose();
  }

  @override
  void onWindowFocus() {
    ref.read(storeProvider.notifier).checkAstroVersion();
  }

  void postRecord(int time) async {
    if (_recorder == null) {
      return;
    }

    await _supabase.functions.invoke('daily-record', body: {
      'time': time,
      'seed': _recorder!.seed,
      'character': _recorder!.character,
      'data': _recorder!.data
    });

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: const Text('기록 완료'),
            content: Text(
              FormatUtil.getTimeString(Duration(milliseconds: time)),
            ),
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
  }

  Future<Preset> getRecordPreset() async {
    final response =
        await http.get(Uri.parse(dotenv.env['RECORD_PRESET_URL'] ?? ''));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final json = jsonDecode(response.body).cast<Map<String, dynamic>>();
    final mods = List<Mod>.from(json.map((e) => Mod.fromJson(e)));

    return Preset(name: 'record', mods: mods);
  }

  void onLoad() async {
    if (!(await checkRecordPreset())) {
      ProcessUtil.killIsaac();

      if (context.mounted) {
        showErrorDialog(context, '허가되지 않은 모드가 감지되었습니다. 게임을 종료합니다.');
      }
    }

    final setting = ref.read(settingProvider);

    final recorderDirectory =
        Directory('${setting.isaacPath}\\mods\\cartridge-recorder');

    if (recorderDirectory.existsSync()) {
      recorderDirectory.deleteSync(recursive: true);
    }
  }

  void resetRecorder() {
    _stopwatch.stop();
    _stopwatch.reset();
    _recorder = null;
  }

  Future<bool> checkRecordPreset() async {
    final store = ref.read(storeProvider);
    final preset = await getRecordPreset();

    final currentMods = (await store.loadMods())
        .where((mod) => !mod.isDisable)
        .map((mod) => mod.name)
        .toSet();
    final presetMods = preset.mods
        .where((mod) => !mod.isDisable)
        .map((mod) => mod.name)
        .toSet();

    return presetMods.containsAll(currentMods);
  }

  void onMessage(String type, List<String> data) {
    if (type == 'LOAD') {
      onLoad();
    } else if (type == 'RESET') {
      resetRecorder();
    } else if (type == 'START') {
      resetRecorder();

      if (data[0] == '1' && data[2] == _todayChallenge?.seed) {
        _stopwatch.start();

        _recorder = RecorderState(
          character: int.parse(data[1]),
          seed: data[2],
        );
      }
    } else if (type == 'END') {
      if (_recorder != null &&
          data[0] == '1' &&
          data[2] == _todayChallenge?.seed &&
          _recorder!.isBossKilled == true) {
        _recorder!.character = int.parse(data[1]);
        _recorder!.seed = data[2];

        postRecord(_stopwatch.elapsedMilliseconds);
      }

      resetRecorder();
    } else if (type == 'BOSS') {
      _recorder?.isBossKilled = true;
    } else if (type == 'STAGE') {
      _recorder?.data.addAll(
        {_stopwatch.elapsedMilliseconds.toString(): "스테이지 ${data[0]} 입장"},
      );
    }
  }

  Future<void> refreshChallenge() async {
    final today = DateTime.now();

    final daily = await _supabase
        .from("daily_challenges")
        .select()
        .gte("date", today)
        .lte("date", today);

    setState(() {
      if (daily.isEmpty) {
        _todayChallenge = null;
        return;
      }

      _todayChallenge = DailyChallenge.fromJson(daily.first);
    });
  }

  Future<void> createRecorderMod() async {
    try {
      await refreshChallenge();

      if (_todayChallenge == null) {
        throw Exception("오늘의 챌린지가 없습니다.");
      }

      final setting = ref.read(settingProvider);
      final recorderDirectory =
          Directory('${setting.isaacPath}\\mods\\cartridge-recorder');

      if (await recorderDirectory.exists()) {
        await recorderDirectory.delete(recursive: true);
      }

      await recorderDirectory.create();

      final mainFile = File("${recorderDirectory.path}\\main.lua");
      await mainFile.create();
      mainFile.writeAsString(
        await RecorderMod.getModMain(
          _todayChallenge!.seed,
          _todayChallenge!.boss,
        ),
      );

      final metadataFile = File("${recorderDirectory.path}\\metadata.xml");
      await metadataFile.create();
      metadataFile.writeAsString(RecorderMod.modMetadata);
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  void startGame() async {
    try {
      final store = ref.watch(storeProvider);

      await ProcessUtil.killIsaac();

      await createRecorderMod();

      await store.applyPreset(
        await getRecordPreset(),
        isForceRerun: true,
        isNoDelay: true,
        isDebugConsole: false,
      );
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.blue.lightest;

    final time = _stopwatch.elapsed;
    final session = _supabase.auth.currentSession;

    if (session == null || session.isExpired) {
      return BackArrowView(
        color: baseColor,
        child: Row(
          children: [
            Flexible(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '로그인이 필요합니다',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 40),
                    HyperlinkButton(
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const SignInDialog(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    HyperlinkButton(
                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const SignUpDialog(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                ),
                child: const DailyChallengeRanking(),
              ),
            ),
          ],
        ),
      );
    }

    return BackArrowView(
      color: baseColor,
      child: Row(
        children: [
          Flexible(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HyperlinkButton(
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w200,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Text(
                        _todayChallenge?.boss ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        FormatUtil.getTimeString(time),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _todayChallenge?.seed ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Pretendard',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      IconButton(
                        style: const ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(width: 1, color: Colors.white),
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
                        onPressed: startGame,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
              ),
              child: const DailyChallengeRanking(),
            ),
          ),
        ],
      ),
    );
  }
}
