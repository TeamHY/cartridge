import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/quick_bar.dart';

/// 상단 헤더를 생성한다.
///
/// ## 유스케이스(Use cases)
/// - 데스크톱 환경에서 창 드래그 이동과 최소화/최대화/닫기 버튼 제공
///
/// ## 처리(Behavior)
/// 1) 앱 아이콘/타이틀을 좌측에 배치
/// 2) WindowCaption을 우측에 배치해 기본 창 컨트롤 제공
NavigationAppBar buildNavigationAppBar(BuildContext context, WidgetRef ref) {
  final fTheme = FluentTheme.of(context);

  return NavigationAppBar(
    automaticallyImplyLeading: false,
    backgroundColor: fTheme.scaffoldBackgroundColor,
    title: DragToMoveArea(
      child: Row(
        children: [
          Image.asset(
            'assets/images/Cartridge_icon_32x32.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text('Cartridge', style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    ),
    actions: Row(
      children: [
        if (MediaQuery.of(context).size.width > 800) ...[
          const Spacer(),
          const QuickBar(),
        ],
        const Spacer(),
        IconButton(
          icon: const Icon(FluentIcons.refresh, size: 20),
          onPressed: () {
            final store = ref.read(storeProvider);
            store.reloadMods();
          },
        ),
        const SizedBox(width: 4),
        const SizedBox(
          width: 138,
          height: 50,
          child: WindowCaption(
            backgroundColor: Colors.transparent,
          ),
        ),
      ],
    ),
  );
}