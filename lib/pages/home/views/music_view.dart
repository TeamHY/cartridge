import 'package:cartridge/components/dialogs/create_playlist_dialog.dart';
import 'package:cartridge/components/dialogs/edit_playlist_dialog.dart';
import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isPickingFolder = false;

  Future<void> _pickFolder() async {
    setState(() {
      _isPickingFolder = true;
    });

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        ref.read(settingProvider).musicPlaylistPath = selectedDirectory;
        ref.read(settingProvider).saveSetting();
      }
    } finally {
      setState(() {
        _isPickingFolder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayer = ref.watch(musicPlayerProvider);
    final playlists = musicPlayer.playlists;
    final musicPlaylistPath =
        ref.watch(settingProvider.select((s) => s.musicPlaylistPath));

    return Column(
      children: [
        SubPageHeader(
          title: 'Music Player',
          onBackPressed: widget.onBackPressed,
          actions: [
            if (musicPlaylistPath.isNotEmpty)
              Expanded(
                child: Tooltip(
                  message: musicPlaylistPath,
                  child: Text(
                    musicPlaylistPath,
                    overflow: TextOverflow.ellipsis,
                    style: FluentTheme.of(context).typography.caption,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.folderOpen,
                size: 20,
              ),
              onPressed: _isPickingFolder ? null : _pickFolder,
            ),
            if (musicPlaylistPath.isNotEmpty)
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
                                playlist.id,
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
                                PhosphorIconsRegular.folder,
                                size: 20,
                              ),
                              onPressed: () {
                                playlist.openFolder();
                              },
                            ),
                          ],
                        ),
                        ...playlist.tracks.map((track) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style:
                                    FluentTheme.of(context).typography.caption,
                              ),
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
