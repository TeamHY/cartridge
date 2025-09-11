import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/theme/theme.dart';

class YoutubeBanner extends StatelessWidget {
  const YoutubeBanner({super.key});

  static final Uri _url = Uri.parse(
    'https://youtube.com/playlist?list=PLFacqh_WLjxRbAeiwDtJRB8nfI4QxgJBI&si=rRGS-vJEKU3QcjHJ',
  );

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final base = t.accentColor;
    final baseBg = Color.alphaBlend(base.withAlpha(t.brightness.isDark ? 38 : 48), t.cardColor);
    final hoverBg = Color.alphaBlend(base.withAlpha(t.brightness.isDark ? 64 : 72), t.cardColor);

    Future<void> open() async {
      final ok = await launchUrl(_url, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        UiFeedback.info(context, '외부 링크', '브라우저를 열 수 없습니다.');
      }
    }

    return HoverButton(
      onPressed: open,
      builder: (ctx, states) {
        final hovered = states.isHovered;
        return Container(
          decoration: BoxDecoration(
            color: hovered ? hoverBg : baseBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 썸네일 16:9
              ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                child: Image.asset(
                  'assets/images/contents/시참대회.png',
                  width: 192,
                  height: 108, // 16:9
                  fit: BoxFit.cover,
                ),
              ),
              Gaps.w16,
              // 타이틀 + 보조 아이콘
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '시청자 참여 대회 컨텐츠',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '오헌영이 내는 미션을 완료해보세요!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
