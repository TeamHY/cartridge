import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/theme/theme.dart';

class YoutubeBanner extends StatelessWidget {
  final double? height;
  const YoutubeBanner({
    super.key,
    this.height,
  });

  static final Uri _url = Uri.parse(
    'https://youtube.com/playlist?list=PLFacqh_WLjxRbAeiwDtJRB8nfI4QxgJBI&si=rRGS-vJEKU3QcjHJ',
  );

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final loc = AppLocalizations.of(context);
    final base = t.accentColor;
    final baseBg = Color.alphaBlend(base.withAlpha(t.brightness.isDark ? 38 : 48), t.cardColor);
    final hoverBg = Color.alphaBlend(base.withAlpha(t.brightness.isDark ? 64 : 72), t.cardColor);

    Future<void> open() async {
      final ok = await launchUrl(_url, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        UiFeedback.warn(context, content: loc.youtube_toast_body);
      }
    }

    return HoverButton(
      onPressed: open,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return Container(
          decoration: BoxDecoration(
            color: hovered ? hoverBg : baseBg,
            borderRadius: AppShapes.panel,
          ),
          child: Row(
            children: [
              // 썸네일 16:9
              ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                child: Image.asset(
                  'assets/content/시참대회.png',
                  width: height != null ? height! * (16/9) : null,
                  height: height, // 16:9
                  fit: BoxFit.cover,
                  semanticLabel: loc.youtube_banner_thumbnail_semantics,
                ),
              ),
              Gaps.w16,
              // 타이틀 + 보조 아이콘
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.youtube_banner_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Gaps.h8,
                    Text(
                      loc.youtube_banner_subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
