import 'package:cartridge/app/presentation/controllers/app_update_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/app/presentation/widgets/home/isaac_home_section.dart';
import 'package:cartridge/app/presentation/widgets/home/promo_banner.dart';
import 'package:cartridge/app/presentation/widgets/home/quick_launch_inline.dart';
import 'package:cartridge/app/presentation/widgets/home/steam_news_section.dart';
import 'package:cartridge/theme/theme.dart';


// ── HomePage ───────────────────────────────────────────────────────────

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    // 첫 프레임 이후로 미뤄 비차단 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUpdateServiceProvider).checkAndPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      header: const ContentHeaderBar.none(),
      content: ContentShell(
        child: LayoutBuilder(
          builder: (_, c) {
            final isNarrow = c.maxWidth < AppBreakpoints.md - 40;
            final narrowItems = const [
              GridItem(child: QuickLaunchInline()),
              GridItem(child: IsaacHomeSection()),
              GridItem(child: SteamNewsSection()),
              GridItem.full(child: PromoBanner()),
            ];
            final wideItems = const [
              GridItem(
                child: Column(
                  children: [
                    QuickLaunchInline(),
                    Gaps.h8,
                    SteamNewsSection(),
                  ],
                ),
              ),
              GridItem(child: IsaacHomeSection()),
              GridItem.full(child: PromoBanner()),
            ];
            return Column(
              children: [
                DesktopGrid(
                  maxContentWidth: AppBreakpoints.lg + 1,
                  colsLg: 2,
                  colsMd: 2,
                  colsSm: 1,
                  items: isNarrow ? narrowItems : wideItems,
                  rowCrossAxisAlignment: CrossAxisAlignment.end,
                ),
                Gaps.h16,
              ],
            );
          },
        ),
      ),
    );
  }
}
class DesktopGridItem {
  final Widget child;
  final bool fullRow;
  const DesktopGridItem(this.child, {this.fullRow = false});
}

class GridSection extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const GridSection({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}