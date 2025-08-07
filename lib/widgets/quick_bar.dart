import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class QuickBar extends StatelessWidget {
  const QuickBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
            onPressed: () async {
              await launchUrl(Uri.parse('https://www.youtube.com/@아이작오헌영'));
              await launchUrl(Uri.parse('https://www.twitch.tv/iwt2hw'));
              await launchUrl(Uri.parse('https://bj.afreecatv.com/iwt2hw'));
              await launchUrl(Uri.parse(
                  'https://chzzk.naver.com/f409bd9619bb9d384159a82d8892f73a'));
            },
            child: Text(loc.quick_live)),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse('https://open.kakao.com/o/gFr6pCbf')),
            child: Text(loc.quick_chat)),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse('https://cafe.naver.com/iwt2hw/2')),
            child: Text(loc.quick_mods)),
        const SizedBox(width: 4),
        Button(
            onPressed: () => launchUrl(Uri.parse('https://toss.me/iwt2hw')),
            child: Text(loc.quick_donation)),
      ],
    );
  }
}
