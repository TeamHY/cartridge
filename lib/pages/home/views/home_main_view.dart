import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/pages/record/record_page.dart';
import 'package:cartridge/pages/slot_machine/slot_machine_page.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart' as material;

class HomeMainView extends ConsumerWidget {
  const HomeMainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);
    final typography = FluentTheme.of(context).typography;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(FluentIcons.people,
                          size: 50, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '아이작 오헌영',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.home_button_record,
                        icon: FluentIcons.trophy,
                        color: Colors.white,
                        textColor: const Color(0xFF6366F1),
                        onTap: () => Navigator.push(
                          context,
                          FluentPageRoute(
                            builder: (context) => const RecordPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.home_button_slot_machine,
                        icon: FluentIcons.game,
                        color: Colors.white,
                        textColor: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(
                          context,
                          FluentPageRoute(
                            builder: (context) => const SlotMachinePage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.home_button_daily_run,
                        icon: FluentIcons.calendar_day,
                        color: Colors.white,
                        textColor: const Color(0xFFEC4899),
                        onTap: () => store.applyPreset(
                          null,
                          isEnableMods: false,
                          isDebugConsole: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Community Links',
            style: typography.subtitle?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
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

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return material.Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: material.Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: material.InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
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
    return material.Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: material.InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
