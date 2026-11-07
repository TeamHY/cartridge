import 'package:cartridge/components/app_icon.dart';
import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeMainView extends ConsumerWidget {
  const HomeMainView(
      {super.key,
      this.onRecordPressed,
      this.onSlotMachinePressed,
      this.onQuizPressed,
      this.onSaveApplyPressed,
      this.onIsaacOptionsPressed});

  final VoidCallback? onRecordPressed;
  final VoidCallback? onSlotMachinePressed;
  final VoidCallback? onQuizPressed;
  final VoidCallback? onSaveApplyPressed;
  final VoidCallback? onIsaacOptionsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

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
                      child: const Center(
                        child: AppIcon(AppIcons.user,
                            size: 50, color: Color(0xFF6366F1)),
                      ),
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
                        icon: AppIcons.trophy,
                        color: Colors.white,
                        textColor: const Color(0xFF6366F1),
                        onTap: onRecordPressed ?? () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.home_button_slot_machine,
                        icon: AppIcons.slot,
                        color: Colors.white,
                        textColor: const Color(0xFF8B5CF6),
                        onTap: onSlotMachinePressed ?? () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.home_button_quiz,
                        icon: AppIcons.quiz,
                        color: Colors.white,
                        textColor: const Color(0xFF14B8A6),
                        onTap: onQuizPressed ?? () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.home_button_daily_run,
                        icon: AppIcons.play,
                        color: Colors.white,
                        textColor: const Color(0xFFEC4899),
                        onTap: () => store.applyPreset(
                          null,
                          isEnableMods: false,
                          isDebugConsole: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: '올클 세이브',
                        icon: AppIcons.memoryCard,
                        color: Colors.white,
                        textColor: const Color(0xFF0EA5A3),
                        onTap: onSaveApplyPressed ?? () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        label: loc.setting_isaac_options_section,
                        icon: AppIcons.sliders,
                        color: Colors.white,
                        textColor: const Color(0xFF475569),
                        onTap: onIsaacOptionsPressed ?? () {},
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
            style: AppTextStyles.title.copyWith(fontSize: 22),
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
                logo: const BrandLogo(BrandLogos.youtube, size: 45),
                onTap: () => launchUrl(Uri.parse(AppUrls.youtube)),
              ),
              _buildLinkCard(
                context,
                label: 'Chzzk',
                color: Colors.black,
                logo: Transform.translate(
                  offset: const Offset(0, -0.5),
                  child: Image.asset('assets/images/brand_chzzk.png',
                      width: 66.5, height: 66.5),
                ),
                onTap: () => launchUrl(Uri.parse(AppUrls.chzzk)),
              ),
              _buildLinkCard(
                context,
                label: 'Soop',
                color: const Color(0xFF17191C),
                logo: Image.asset('assets/images/brand_soop.png',
                    width: 57.5, height: 57.5),
                onTap: () => launchUrl(Uri.parse(AppUrls.afreeca)),
              ),
              _buildLinkCard(
                context,
                label: 'Twitch',
                color: const Color(0xFF9146FF),
                logo: Transform.translate(
                  offset: const Offset(0, 3),
                  child: const BrandLogo(BrandLogos.twitch, size: 42.5),
                ),
                onTap: () => launchUrl(Uri.parse(AppUrls.twitch)),
              ),
              _buildLinkCard(
                context,
                label: 'Discord',
                color: const Color(0xFF5865F2),
                logo: const BrandLogo(BrandLogos.discord, size: 41.5),
                onTap: () => launchUrl(Uri.parse(AppUrls.discord)),
              ),
              _buildLinkCard(
                context,
                label: 'Kakao OpenChat',
                color: const Color(0xFFFAE100),
                logo: Transform.translate(
                  offset: const Offset(0, 0.5),
                  child: const BrandLogo(BrandLogos.kakaoTalk,
                      size: 53, color: Color(0xFF3C1E1E)),
                ),
                onTap: () => launchUrl(Uri.parse(AppUrls.openChat)),
              ),
              _buildLinkCard(
                context,
                label: 'Naver Cafe',
                color: const Color(0xFF03C75A),
                logo: const BrandLogo(BrandLogos.naver, size: 32),
                onTap: () => launchUrl(Uri.parse(AppUrls.naverCafeHome)),
              ),
              _buildLinkCard(
                context,
                label: 'Donate',
                color: const Color(0xFFFF6B6B),
                logo: const AppIcon(AppIcons.heart,
                    size: 57, color: Colors.white),
                onTap: () => launchUrl(Uri.parse(AppUrls.donationPlaysquad)),
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
    required AppIcons icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(icon, color: textColor, size: 28),
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
    required Widget logo,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);

    return AppPressable(
      onPressed: onTap,
      focusRadius: 16,
      builder: (context, states) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: states.contains(WidgetState.hovered) ? c.surface3 : c.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.line,
            width: 1,
          ),
        ),
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
                clipBehavior: Clip.antiAlias,
                child: Center(child: logo),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
