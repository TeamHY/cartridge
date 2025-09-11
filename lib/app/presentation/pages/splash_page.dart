import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';


class SplashPage extends StatelessWidget {
  const SplashPage({
    super.key,
    this.showSpinner = true,
    this.logo,
  });
  final bool showSpinner;
  final ImageProvider? logo;

  static const _defaultLogo = AssetImage(
    'assets/images/Cartridge_icon_200_200.png',
  );

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    return Container(
      key: const Key('splash-bg'),
      color: fTheme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(
            image: logo ?? _defaultLogo,
            width: 200, height: 200,
            filterQuality: FilterQuality.medium,
          ),
          Gaps.h16,
          Visibility(
            key: const Key('splash-spinner'),
            visible: showSpinner,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: Semantics(label: 'Loading', child: ProgressRing()),
          ),
        ],
      ),
    );
  }
}
