import 'dart:async';

import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/dialogs/sign_in_dialog.dart';
import 'package:cartridge/widgets/dialogs/sign_up_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

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

  String getTimeString(Duration time) {
    final hours = time.inHours.toString().padLeft(2, '0');
    final minutes = (time.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        ((time.inMilliseconds % 1000) / 10).floor().toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final baseColor = Colors.blue.lightest;

    final time = _stopwatch.elapsed;
    final session = _supabase.auth.currentSession;

    return NavigationView(
      content: Stack(
        children: [
          Container(
            color: baseColor,
            child: Center(
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          session?.user.userMetadata?['display_name'] ??
                              '로그인 필요',
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
                          onPressed: () async {
                            if (_stopwatch.isRunning) {
                              return _stopwatch.stop();
                            }

                            _stopwatch.start();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                iconButtonMode: IconButtonMode.large,
                icon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(
                    FluentIcons.back,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: DragToMoveArea(
                  child: Container(
                    height: 50,
                  ),
                ),
              ),
              const SizedBox(
                width: 138,
                height: 50,
                child: WindowCaption(
                  brightness: Brightness.dark,
                  backgroundColor: Colors.transparent,
                ),
              )
            ],
          )
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
