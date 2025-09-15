import 'package:cartridge/app/presentation/widgets/tm_trainer_art.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/app_navigation.dart';
import 'package:cartridge/app/presentation/controllers/app_stage_provider.dart';
import 'package:cartridge/app/presentation/pages/splash_page.dart';
import 'package:cartridge/app/presentation/widgets/error_view.dart';
import 'package:cartridge/app/presentation/widgets/warm_boot_hook.dart';
import 'package:cartridge/features/cartridge/setting/setting.dart';
import 'package:cartridge/l10n/app_localizations.dart';


class StageShell extends ConsumerStatefulWidget {
  const StageShell({super.key});

  @override
  ConsumerState<StageShell> createState() => _StageShellState();
}

class _StageShellState extends ConsumerState<StageShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final Animation<double> _fade = _ctrl;
  late final Animation<double> _scale =
  Tween<double>(begin: 1.0, end: 1.6).animate(_ctrl);

  bool _showSplash = false;
  bool _listening = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_listening) {
      _listening = true;
      ref.listen<AppStage>(appStageProvider, (prev, next) {
        if (next == AppStage.splash) {
          setState(() {
            _showSplash = true;
            _ctrl.value = 0.0;
          });
        } else {
          if (_showSplash && _ctrl.status != AnimationStatus.forward) {
            if (!TickerMode.of(context)) {
              // 🔹 골든/테스트 등 애니메이션 off 환경: 즉시 제거 (무한대기 방지)
              if (mounted) setState(() => _showSplash = false);
              _ctrl.value = 0.0;
            } else {
              _ctrl.forward().then((_) {
                if (mounted) setState(() => _showSplash = false);
                _ctrl.value = 0.0;
              });
            }
          }
        }
      });
    }

    final stage = ref.watch(appStageProvider);
    final loc = AppLocalizations.of(context);

    // 초기 상태 동기화
    final initial = ref.read(appStageProvider);
    if (initial == AppStage.splash) {
      _showSplash = true;
      _ctrl.value = 0.0;
    }

    // 본 화면(애니메이션 없음)
    late final Widget base;
    switch (stage) {
      case AppStage.main:
        base = const WarmBootHook(child: AppNavigation());
        break;
      case AppStage.error:
        base = ErrorView(
          messageText: loc.error_startup_message,
          retryText: loc.common_retry,
          closeText: loc.common_close,
          onRetry: () => ref.invalidate(appSettingControllerProvider),
          illustration: const TmTrainerArt(),
        );
        break;
      case AppStage.splash:
      // loadin 중엔 배경만(테마 색) 깔아두면 전환 시 깜빡임 방지
        base = Container(color: FluentTheme.of(context).scaffoldBackgroundColor);
        break;
    }
    final bool showSpinner = TickerMode.of(context) && !_ctrl.isAnimating;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) 본 화면(항상 "그대로" 표시, 애니메이션 없음)
        base,

        // 2) 스플래시 오버레이: 있을 때만 위에 얹고 "사라지는" 애니메이션만 적용
        if (_showSplash)
          IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(_fade), // 1→0 으로 사라짐
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.6)
                    .animate(ReverseAnimation(_scale)),
                child: SplashPage(
                  showSpinner: showSpinner,
                ),
              ),
            ),
          ),
      ],
    );
  }
}