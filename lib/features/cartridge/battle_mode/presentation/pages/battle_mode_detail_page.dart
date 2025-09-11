import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/app/presentation/app_markdown.dart';

class BattleModeDetailPage extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final Future<void> Function()? onRunInstance;
  final String markdownAsset;

  const BattleModeDetailPage({
    super.key,
    this.onClose,
    this.onRunInstance,
    this.markdownAsset = 'assets/content/battle_mode.md',
  });

  @override
  ConsumerState<BattleModeDetailPage> createState() =>
      _BattleModeDetailPageState();
}

class _BattleModeDetailPageState extends ConsumerState<BattleModeDetailPage> {
  late Future<String> _mdFuture;

  @override
  void initState() {
    super.initState();
    _mdFuture = rootBundle.loadString(widget.markdownAsset);
  }

  @override
  Widget build(BuildContext context) {

    return ScaffoldPage(
      header: ContentHeaderBar.backText(
        onBack: widget.onClose,
        title: '대결모드',
      ),
      content: ContentShell(
        child: LayoutBuilder(
          builder: (_, c) {
            return Column(
              children: [
                DesktopGrid(
                  maxContentWidth: AppBreakpoints.lg + 1,
                  colsLg: 1,
                  colsMd: 1,
                  colsSm: 1,
                  items: [
                    GridItem(
                      child: _sectionCard(
                        context,
                        child: FutureBuilder<String>(
                          future: _mdFuture,
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: ProgressBar(),
                              );
                            }
                            if (snap.hasError) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!context.mounted) return;
                                UiFeedback.error(context, '문서 로드 실패', snap.error.toString());
                              });
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('문서를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.'),
                              );
                            }
                            final md = snap.data ?? '';
                            return AppMarkdown(data: md);
                          },
                        ),
                      ),
                    ),
                  ],
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

Widget _sectionCard(BuildContext context, {required Widget child}) {
  final t = FluentTheme.of(context);
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: t.resources.cardBackgroundFillColorDefault,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: t.resources.controlStrokeColorSecondary.withAlpha(32),
        width: .8,
      ),
    ),
    child: child,
  );
}
