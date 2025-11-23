import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/pages/home/components/home_navigation_bar.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeMainView extends StatelessWidget {
  const HomeMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeNavigationBar(),
          Row(
            children: [
              Expanded(
                child: _buildPlayCard(
                  context,
                  title: 'Play instance',
                  subtitle: 'No instances',
                  icon: FluentIcons.play,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlayCard(
                  context,
                  title: 'Play vanilla',
                  subtitle: 'No preset',
                  icon: FluentIcons.play,
                  color: const Color(0xFF3498DB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Steam Isaac News',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              HyperlinkButton(
                onPressed: () {},
                child: const Text('See more news →'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(FluentIcons.people, size: 40),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아이작 오헌영 • Community & Support',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A place made with Isaac players! Find streams, community, guides and various event news.',
                        style: FluentTheme.of(context).typography.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildLinkCard(
                context,
                label: 'YouTube',
                color: const Color(0xFFFF0000),
                icon: FluentIcons.video,
                onTap: () => launchUrl(Uri.parse(AppUrls.youtube)),
              ),
              _buildLinkCard(
                context,
                label: 'Chzzk',
                color: const Color(0xFF00E5A0),
                icon: FluentIcons.streaming,
                onTap: () => launchUrl(Uri.parse(AppUrls.chzzk)),
              ),
              _buildLinkCard(
                context,
                label: 'Soop',
                color: const Color(0xFF4A90E2),
                icon: FluentIcons.video,
                onTap: () => launchUrl(Uri.parse(AppUrls.afreeca)),
              ),
              _buildLinkCard(
                context,
                label: 'Twitch',
                color: const Color(0xFF9146FF),
                icon: FluentIcons.video,
                onTap: () => launchUrl(Uri.parse(AppUrls.twitch)),
              ),
              _buildLinkCard(
                context,
                label: 'Discord',
                color: const Color(0xFF5865F2),
                icon: FluentIcons.chat,
                onTap: () => launchUrl(Uri.parse(AppUrls.discord)),
              ),
              _buildLinkCard(
                context,
                label: 'Kakao OpenChat',
                color: const Color(0xFFFAE100),
                icon: FluentIcons.chat,
                onTap: () => launchUrl(Uri.parse(AppUrls.openChat)),
              ),
              _buildLinkCard(
                context,
                label: 'Naver Cafe',
                color: const Color(0xFF03C75A),
                icon: FluentIcons.news,
                onTap: () => launchUrl(Uri.parse(AppUrls.naverCafeHome)),
              ),
              _buildLinkCard(
                context,
                label: 'Donate (Playsquad)',
                color: const Color(0xFFFF6B6B),
                icon: FluentIcons.heart,
                onTap: () => launchUrl(Uri.parse(AppUrls.donationPlaysquad)),
              ),
              _buildLinkCard(
                context,
                label: 'Donate (Toonation)',
                color: const Color(0xFF00D4FF),
                icon: FluentIcons.money,
                onTap: () => launchUrl(Uri.parse(AppUrls.donation)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Button(
      onPressed: onTap,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.all(16)),
        backgroundColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
