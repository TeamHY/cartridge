import 'package:cartridge/providers/music_player_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MusicView extends ConsumerStatefulWidget {
  const MusicView({super.key});

  @override
  ConsumerState<MusicView> createState() => _MusicViewState();
}

class _MusicViewState extends ConsumerState<MusicView> {
  @override
  Widget build(BuildContext context) {
    final musicPlayer = ref.watch(musicPlayerProvider);
    final playlists = musicPlayer.playlists;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              spacing: 4,
              children: [
                IconButton(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.arrowLeft,
                      size: 20,
                    ),
                    onPressed: () {}),
                Text(
                  'Music Player',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                Expanded(child: Container()),
                IconButton(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 20,
                    ),
                    onPressed: () {}),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: playlists.map((playlist) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  playlist.name,
                                  style:
                                      FluentTheme.of(context).typography.body,
                                ),
                              ),
                              IconButton(
                                icon: const PhosphorIcon(
                                  PhosphorIconsRegular.play,
                                  size: 20,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          ...playlist.tracks.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: FluentTheme.of(context)
                                      .typography
                                      .caption,
                                ),
                                ...entry.value.map((track) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const PhosphorIcon(
                                            PhosphorIconsRegular.play,
                                            size: 16,
                                          ),
                                          onPressed: () {},
                                        ),
                                        Expanded(child: Text(track.title)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
