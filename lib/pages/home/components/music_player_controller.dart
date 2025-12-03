import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MusicPlayer extends ConsumerWidget {
  const MusicPlayer({super.key, this.onTap, this.isSelected});

  final bool? isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicPlayer = ref.watch(musicPlayerProvider);
    final isPlaying = musicPlayer.isPlaying;
    final duration = musicPlayer.duration;
    final position = musicPlayer.position;
    final volume = ref.watch(settingProvider.select((s) => s.musicVolume));

    return material.Ink(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected == true
                ? FluentTheme.of(context).accentColor
                : Colors.black.withValues(alpha: 0.1),
            width: 1,
          )),
      child: material.InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.music_note,
                    size: 16,
                    color: Colors.grey[130],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      musicPlayer.currentTrackTitle ?? "No Track",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[130],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    duration != null
                        ? '${position?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${position?.inSeconds.remainder(60).toString().padLeft(2, '0')} / ${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
                        : '00:00 / 00:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[130],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IconButton(
                  //   icon: const PhosphorIcon(PhosphorIconsFill.skipBack,
                  //       size: 16),
                  //   onPressed: () {},
                  // ),
                  // const SizedBox(width: 8),
                  IconButton(
                    icon: PhosphorIcon(
                      isPlaying
                          ? PhosphorIconsFill.pause
                          : PhosphorIconsFill.play,
                      size: 20,
                    ),
                    onPressed: musicPlayer.currentPlaylist == null
                        ? null
                        : isPlaying
                            ? musicPlayer.pause
                            : musicPlayer.play,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsFill.skipForward,
                        size: 16),
                    onPressed: musicPlayer.currentPlaylist == null
                        ? null
                        : musicPlayer.playNext,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          volume == 0
                              ? PhosphorIconsFill.speakerSimpleSlash
                              : volume < 0.5
                                  ? PhosphorIconsFill.speakerSimpleLow
                                  : PhosphorIconsFill.speakerSimpleHigh,
                          size: 16,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                        Expanded(
                            child: material.SliderTheme(
                          data: const material.SliderThemeData(
                            trackHeight: 2,
                            thumbShape: material.RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: material.RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: material.Slider(
                            padding: const EdgeInsets.all(4),
                            value: volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (value) {
                              final setting = ref.read(settingProvider);
                              setting.musicVolume = value;
                              setting.saveSetting();
                            },
                          ),
                        )),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${(volume * 100).round()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
