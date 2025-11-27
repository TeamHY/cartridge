import 'package:cartridge/components/dialogs/create_playlist_dialog.dart';
import 'package:cartridge/components/dialogs/edit_playlist_dialog.dart';
import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MusicView extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const MusicView({super.key, this.onBackPressed});

  @override
  ConsumerState<MusicView> createState() => _MusicViewState();
}

class _MusicViewState extends ConsumerState<MusicView> {
  @override
  Widget build(BuildContext context) {
    final musicPlayer = ref.watch(musicPlayerProvider);
    final playlists = musicPlayer.playlists;

    return Column(
      children: [
        SubPageHeader(
          title: 'Music Player',
          onBackPressed: widget.onBackPressed,
          actions: [
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.plus,
                size: 20,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreatePlaylistDialog(),
                );
              },
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                                style: FluentTheme.of(context).typography.body,
                              ),
                            ),
                            IconButton(
                              icon: const PhosphorIcon(
                                PhosphorIconsRegular.pencil,
                                size: 20,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => EditPlaylistDialog(
                                    playlist: playlist,
                                  ),
                                );
                              },
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
                                style:
                                    FluentTheme.of(context).typography.caption,
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
    );
  }
}
