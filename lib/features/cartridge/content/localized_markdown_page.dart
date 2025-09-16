import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:cartridge/app/presentation/widgets/markdown/app_markdown.dart';
import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class LocalizedMarkdownPage extends StatefulWidget {
  final String title;
  final String markdownAsset;
  final VoidCallback onClose;
  const LocalizedMarkdownPage({
    super.key,
    required this.title,
    required this.markdownAsset,
    required this.onClose,
  });

  @override
  State<LocalizedMarkdownPage> createState() => _LocalizedMarkdownPageState();
}

class _LocalizedMarkdownPageState extends State<LocalizedMarkdownPage> {
  Future<String>? _mdFuture;
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_lang != lang || _mdFuture == null) {
      _lang = lang;
      _mdFuture = rootBundle
          .loadString(widget.markdownAsset)
          .then((md) => _extractLang(md, lang));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ScaffoldPage(
      header: ContentHeaderBar.backText(
        onBack: widget.onClose,
        title: widget.title,
      ),
      content: ContentShell(
        child: DesktopGrid(
          maxContentWidth: AppBreakpoints.lg + 1,
          colsLg: 1, colsMd: 1, colsSm: 1,
          items: [
            GridItem(
              child: _sectionCard(
                context,
                child: FutureBuilder<String>(
                  future: _mdFuture,
                  builder: (context, snap) {
                    if (_mdFuture == null) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: ProgressBar(),
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(height: 360, child: Center(child: ProgressRing(),),),
                      );
                    }
                    if (snap.hasError) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        UiFeedback.error(context, content: loc.doc_load_fail_desc);
                      });
                      return EmptyState.withDefault404(
                        title: loc.doc_load_fail_desc,
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
      ),
    );
  }

  static String _extractLang(String md, String lang) {
    // <!-- lang:ko --> ... <!-- /lang -->
    final start = RegExp(r'<!--\s*lang\s*:\s*([a-zA-Z\-]+)\s*-->', multiLine: true);
    final end = RegExp(r'<!--\s*/lang\s*-->', multiLine: true);

    final matches = start.allMatches(md).toList();
    for (final m in matches) {
      final blockLang = m.group(1)?.toLowerCase();
      final endMatch = end.firstMatch(md.substring(m.end));
      if (endMatch != null) {
        final endIdx = m.end + endMatch.start;
        if (blockLang == lang.toLowerCase()) {
          return md.substring(m.end, endIdx).trim();
        }
      }
    }
    // 블록이 없거나 해당 언어 블록이 없으면 전체 사용
    return md;
  }
}

Widget _sectionCard(BuildContext context, {required Widget child}) {
  final t = FluentTheme.of(context);
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: t.resources.cardBackgroundFillColorDefault,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: t.resources.controlStrokeColorSecondary.withAlpha(32),
        width: .8,
      ),
    ),
    child: child,
  );
}
