import 'dart:async';

import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/models/daily_challenge.dart';
import 'package:cartridge/models/weekly_challenge.dart';
import 'package:cartridge/providers/isaac_event_manager_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/services/auth_service.dart';
import 'package:cartridge/services/challenge_service.dart';
import 'package:cartridge/services/mod_manager.dart';
import 'package:cartridge/services/record_preset_service.dart';
import 'package:cartridge/utils/format_util.dart';
import 'package:cartridge/services/process_util.dart';
import 'package:cartridge/pages/record/components/back_arrow_view.dart';
import 'package:cartridge/pages/record/components/ranking/daily_challenge_ranking.dart';
import 'package:cartridge/components/dialogs/error_dialog.dart';
import 'package:cartridge/components/dialogs/nickname_edit_dialog.dart';
import 'package:cartridge/components/dialogs/sign_in_dialog.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/components/dialogs/sign_up_dialog.dart';
import 'package:cartridge/pages/record/components/ranking/weekly_challenge_ranking.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:cartridge/services/mod_service.dart';

enum ChallengeType { daily, weekly }

class RecorderState {
  RecorderState({
    this.type = ChallengeType.daily,
    this.character = 0,
    this.seed = '',
    this.isBossKilled = false,
  });

  ChallengeType type;
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
  late final AuthService _authService;
  late final ChallengeService _challengeService;

  late Timer _timer;
  late StreamSubscription<AuthState> _authSubscription;

  int _rankingTabIndex = 1;

  DailyChallenge? _dailyChallenge;
  WeeklyChallenge? _weeklyChallenge;
  RecorderState? _recorder = RecorderState();

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    _authService = AuthService(_supabase);
    _challengeService = ChallengeService(_supabase);

    ref.read(storeProvider.notifier).checkAstroVersion();

    _timer = Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
      setState(() {
        if (_stopwatch.isRunning) {}
      });
    });

    _authSubscription = _authService.authStateChanges.listen((data) async {
      final isAdmin = await _authService.isUserAdmin(data.session?.user.id);
      setState(() {
        _isAdmin = isAdmin;
      });
    });

    ref.read(isaacEventManagerProvider).recorderStream.listen(onMessage);

    _refreshChallenge();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);

    _timer.cancel();
    _authSubscription.cancel();

    super.dispose();
  }

  @override
  void onWindowFocus() {
    ref.read(storeProvider.notifier).checkAstroVersion();
  }

  Future<void> _submitDailyRecord(int time) async {
    if (_recorder == null) return;

    await _challengeService.submitDailyRecord(
      time: time,
      seed: _recorder!.seed,
      character: _recorder!.character,
      data: _recorder!.data,
    );

    _showRecordCompleteDialog(time);
  }

  Future<void> _submitWeeklyRecord(int time) async {
    if (_recorder == null) return;

    await _challengeService.submitWeeklyRecord(
      time: time,
      seed: _recorder!.seed,
      character: _recorder!.character,
      data: _recorder!.data,
    );

    _showRecordCompleteDialog(time);
  }

  void _showRecordCompleteDialog(int time) {
    final loc = AppLocalizations.of(context);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: Text(loc.record_record_complete_title),
            content: Text(
              FormatUtil.getTimeString(Duration(milliseconds: time)),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(loc.common_close),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _onLoad() async {
    if (!(await _validateRecordPreset())) {
      await ProcessUtil.killIsaac();

      if (context.mounted) {
        showErrorDialog(
            context, AppLocalizations.of(context).record_invalid_mod_warning);
      }
    }
  }

  void _resetRecorder() {
    _stopwatch.stop();
    _stopwatch.reset();
    _recorder = null;
  }

  Future<bool> _validateRecordPreset() async {
    final setting = ref.read(settingProvider);
    final preset = await RecordPresetService.getRecordPreset();
    final currentMods = await ModService.loadMods(setting.isaacPath);

    return RecordPresetService.validateRecordPreset(
      currentMods: currentMods,
      recordPreset: preset,
    );
  }

  void onMessage((String type, List<String> data) params) {
    final type = params.$1;
    final data = params.$2;

    if (type == 'LOAD') {
      _onLoad();
    } else if (type == 'RESET') {
      _resetRecorder();
    } else if (type == 'START') {
      final setting = ref.read(settingProvider);
      ModManager.deleteRecorderMod(setting.isaacPath);

      _resetRecorder();

      final challengeType = data[0];
      final character = int.parse(data[1]);
      final seed = data[2];

      if (challengeType == 'D' && seed == _dailyChallenge?.seed) {
        _stopwatch.start();
        _recorder = RecorderState(
          type: ChallengeType.daily,
          character: character,
          seed: seed,
        );
      } else if (challengeType == 'W' &&
          character == _weeklyChallenge?.character &&
          seed == _weeklyChallenge?.seed) {
        _stopwatch.start();
        _recorder = RecorderState(
          type: ChallengeType.weekly,
          character: character,
          seed: seed,
        );
      }
    } else if (type == 'END') {
      final challengeType = data[0];
      final character = int.parse(data[1]);
      final seed = data[2];

      if (_recorder != null && _recorder!.isBossKilled == true) {
        if (_recorder!.type == ChallengeType.daily &&
            challengeType == 'D' &&
            seed == _dailyChallenge?.seed) {
          _submitDailyRecord(_stopwatch.elapsedMilliseconds);
        } else if (_recorder!.type == ChallengeType.weekly &&
            challengeType == 'W' &&
            seed == _weeklyChallenge?.seed) {
          _submitWeeklyRecord(_stopwatch.elapsedMilliseconds);
        }

        _recorder!.character = character;
        _recorder!.seed = seed;
      }

      _resetRecorder();
    } else if (type == 'BOSS') {
      _recorder?.isBossKilled = true;
    } else if (type == 'STAGE') {
      _recorder?.data.addAll(
        {
          _stopwatch.elapsedMilliseconds.toString():
              AppLocalizations.of(context).record_stage_entry(data[0], data[1])
        },
      );
    }
  }

  Future<void> _refreshChallenge() async {
    final dailyChallenge = await _challengeService.getDailyChallenge();
    final weeklyChallenge = await _challengeService.getWeeklyChallenge();

    setState(() {
      _dailyChallenge = dailyChallenge;
      _weeklyChallenge = weeklyChallenge;
    });
  }

  Future<void> _createRecorderMod() async {
    await _refreshChallenge();

    if (_dailyChallenge == null || _weeklyChallenge == null) {
      throw Exception(AppLocalizations.of(context).record_no_challenge);
    }

    final setting = ref.read(settingProvider);

    await ModManager.createRecorderMod(
      isaacPath: setting.isaacPath,
      dailySeed: _dailyChallenge!.seed,
      dailyBoss: _dailyChallenge!.boss,
      dailyCharacter: _dailyChallenge!.character ?? 0,
      weeklySeed: _weeklyChallenge!.seed,
      weeklyBoss: _weeklyChallenge!.boss,
      weeklyCharacter: _weeklyChallenge!.character,
    );
  }

  Future<void> _startGame() async {
    try {
      final store = ref.watch(storeProvider);

      await ProcessUtil.killIsaac();
      await _createRecorderMod();

      final isDebugConsole = await _authService.isCurrentUserAdmin();

      await store.applyPreset(
        await RecordPresetService.getRecordPreset(),
        isForceRerun: true,
        isNoDelay: true,
        isDebugConsole: isDebugConsole,
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
    final session = _authService.currentSession;
    final loc = AppLocalizations.of(context);

    final stopwatchView = (session == null || session.isExpired)
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.record_login_required,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 40),
              HyperlinkButton(
                child: Text(
                  loc.record_signin,
                  style: const TextStyle(
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
                child: Text(
                  loc.record_signup,
                  style: const TextStyle(
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
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                child: Text(
                  loc.record_check_rules,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                  ),
                ),
                onPressed: () async {
                  await launchUrl(Uri.parse(AppUrls.rulesPost));
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HyperlinkButton(
                    child: Text(
                      loc.record_nickname_edit,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w200,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const NicknameEditDialog(),
                      );
                    },
                  ),
                  HyperlinkButton(
                    child: Text(
                      loc.record_signout,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w200,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    onPressed: () async {
                      await _authService.signOut();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Text(
                            loc.record_daily_target,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _dailyChallenge?.boss ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _dailyChallenge?.seed ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        children: [
                          Text(
                            loc.record_weekly_target,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _weeklyChallenge?.boss ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _weeklyChallenge?.seed ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
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
                    onPressed: _startGame,
                  ),
                ],
              ),
            ],
          );

    return BackArrowView(
      color: baseColor,
      child: Row(
        children: [
          Flexible(
            child: Center(child: stopwatchView),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[30],
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(8)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HyperlinkButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            _rankingTabIndex == 0
                                ? Colors.white
                                : Colors.grey[30],
                          ),
                        ),
                        child: Text(loc.record_daily_ranking),
                        onPressed: () {
                          setState(() {
                            _rankingTabIndex = 0;
                          });
                        },
                      ),
                      HyperlinkButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            _rankingTabIndex == 1
                                ? Colors.white
                                : Colors.grey[30],
                          ),
                        ),
                        child: Text(loc.record_weekly_ranking),
                        onPressed: () {
                          setState(() {
                            _rankingTabIndex = 1;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_rankingTabIndex == 0) ...[
                    Expanded(
                        child: Container(
                      color: Colors.white,
                      child: DailyChallengeRanking(
                        isAdmin: _isAdmin,
                      ),
                    )),
                  ] else ...[
                    Expanded(
                        child: Container(
                      color: Colors.white,
                      child: WeeklyChallengeRanking(
                        isAdmin: _isAdmin,
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
