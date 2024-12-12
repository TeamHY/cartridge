import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/utils/isaac_log_file.dart';
import 'package:cartridge/utils/process_util.dart';
import 'package:cartridge/utils/recorder_mod.dart';
import 'package:cartridge/widgets/back_arrow_view.dart';
import 'package:cartridge/widgets/daily_challenge_ranking.dart';
import 'package:cartridge/widgets/dialogs/error_dialog.dart';
import 'package:cartridge/widgets/dialogs/sign_in_dialog.dart';
import 'package:cartridge/widgets/dialogs/sign_up_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

class RecorderState {
  RecorderState({
    this.character = 0,
    this.seed = '',
    this.isBossKilled = false,
    this.data = const {},
  });

  int character;
  String seed;
  bool isBossKilled;
  Map<String, dynamic> data;
}

class DailyRecord {
  DailyRecord({
    required this.time,
    required this.seed,
    required this.character,
    required this.data,
  });

  final String time;
  final String seed;
  final int character;
  final Map<String, dynamic> data;
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
  late DateTime _targetDate;

  Map<String, dynamic>? _todayChallenge;

  List<DailyRecord> _dailyRecords = [];

  RecorderState _recorder = RecorderState();

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

    _targetDate = DateTime.now();

    syncChallenge();
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

  void postRecord(String time) async {
    final res = await _supabase.functions.invoke('daily-record', body: {
      'time': time,
      'seed': _recorder.seed,
      'character': _recorder.character,
      'data': _recorder.data
    });

    print(res.data);
  }

  String getTimeString(Duration time) {
    final hours = time.inHours.toString().padLeft(2, '0');
    final minutes = (time.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        ((time.inMilliseconds % 1000) / 10).floor().toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds.$milliseconds';
  }

  void onMessage(String type, List<String> data) {
    if (type == 'START') {
      _stopwatch.stop();
      _stopwatch.reset();

      if (data[0] == '1' && data[2] == _todayChallenge?['seed']) {
        _stopwatch.start();

        _recorder = RecorderState(
          character: int.parse(data[1]),
          seed: data[2],
        );
      }
    } else if (type == 'END') {
      if (data[0] == '1' &&
          data[2] == _todayChallenge?['seed'] &&
          _recorder.isBossKilled == true) {
        _recorder.character = int.parse(data[1]);
        _recorder.seed = data[2];

        postRecord(getTimeString(_stopwatch.elapsed));
      }

      _stopwatch.stop();
      _stopwatch.reset();
    } else if (type == 'BOSS') {
      _recorder.isBossKilled = true;
    } else if (type == 'STAGE') {
      _recorder.data.addAll(
        {_stopwatch.elapsedMilliseconds.toString(): "스테이지 ${data[0]} 입장"},
      );
    }
  }

  Future<void> syncChallenge() async {
    final today = DateTime.now();

    final daily = await _supabase
        .from("daily_challenges")
        .select()
        .gte("date", today)
        .lte("date", today);

    final dailyRecords = await _supabase
        .from("daily_challenge_records")
        .select()
        .eq("challenge_id", daily[0]["id"]);

    print(dailyRecords);

    setState(() {
      _todayChallenge = daily.firstOrNull;
    });
  }

  Future<void> createRecorderMod() async {
    try {
      await syncChallenge();

      final setting = ref.read(settingProvider);
      final recorderDirectory =
          Directory('${setting.isaacPath}\\mods\\cartridge-recorder');
      await recorderDirectory.delete(recursive: true);
      await recorderDirectory.create();

      final mainFile = File("${recorderDirectory.path}\\main.lua");
      await mainFile.create();
      mainFile.writeAsString(RecorderMod.getModMain(
          _todayChallenge!["seed"], _todayChallenge!["boss"]));

      final metadataFile = File("${recorderDirectory.path}\\metadata.xml");
      await metadataFile.create();
      metadataFile.writeAsString(RecorderMod.modMetadata);
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, "모드 생성 중 오류가 발생했습니다.");
      }
    }
  }

  void startGame() async {
    try {
      final store = ref.watch(storeProvider);

      final response = await http.get(Uri.https('raw.githubusercontent.com',
          'TeamHY/cartridge/main/assets/record_presets.json'));

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final json = jsonDecode(response.body).cast<Map<String, dynamic>>();
      final mods = List<Mod>.from(json.map((e) => Mod.fromJson(e)));

      await ProcessUtil.killIsaac();

      await createRecorderMod();

      await store.applyPreset(
        Preset(name: '', mods: mods),
        isForceRerun: true,
        isNoDelay: true,
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

    return BackArrowView(
      color: baseColor,
      child: Row(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      session?.user.userMetadata?['display_name'] ?? '로그인 필요',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    AuthAction(
                      isSignedIn: session != null,
                    )
                  ],
                ),
                const SizedBox(height: 40),
                Column(
                  children: [
                    Text(
                      getTimeString(time),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                          fontFeatures: [FontFeature.tabularFigures()]),
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
          Flexible(
            child: DailyChallengeRanking(date: "231", seed: "231", boss: "231"),
          ),
        ],
      ),
    );
  }
}

class AuthAction extends StatelessWidget {
  const AuthAction({
    super.key,
    this.isSignedIn = false,
  });

  final bool isSignedIn;

  List<Widget> getButtons(BuildContext context) {
    if (isSignedIn) {
      return [
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
      ];
    }

    return [
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: getButtons(context),
    );
  }
}
