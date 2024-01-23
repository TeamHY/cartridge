import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickBar extends StatelessWidget {
  const QuickBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
            onPressed: () async {
              await launchUrl(
                  Uri.parse('https://www.youtube.com/@HeonYeong_Isaac'));
              await launchUrl(Uri.parse('https://www.twitch.tv/iwt2hw'));
              await launchUrl(Uri.parse('https://bj.afreecatv.com/iwt2hw'));
              await launchUrl(Uri.parse(
                  'https://chzzk.naver.com/f409bd9619bb9d384159a82d8892f73a'));
            },
            child: const Text('생방송')),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse('https://open.kakao.com/o/gFr6pCbf')),
            child: const Text('오픈채팅')),
        const SizedBox(width: 4),
        Button(
            onPressed: () =>
                launchUrl(Uri.parse('https://cafe.naver.com/iwt2hw/2')),
            child: const Text('모드')),
        const SizedBox(width: 4),
        Button(
            onPressed: () => launchUrl(Uri.parse('https://toss.me/iwt2hw')),
            child: const Text('후원')),
      ],
    );
  }
}
