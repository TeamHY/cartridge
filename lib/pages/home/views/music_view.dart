import 'package:cartridge/components/dialogs/create_playlist_dialog.dart';
import 'package:cartridge/components/dialogs/edit_playlist_dialog.dart';
import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MusicView extends ConsumerStatefulWidget {
  const MusicView({super.key});

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

    playlists.sort(
      (a, b) => a.id.compareTo(b.id),
    );

    return Column(
      children: [
        SubPageHeader(
          title: '음악 플레이어',
          actions: [
            if (musicPlaylistPath.isNotEmpty)
              Expanded(
                child: Tooltip(
                  message: musicPlaylistPath,
                  child: Text(
                    musicPlaylistPath,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            AppIconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.folderOpen),
              iconSize: 20,
              onPressed: _isPickingFolder ? null : _pickFolder,
            ),
            if (musicPlaylistPath.isNotEmpty)
              AppIconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.plus),
                iconSize: 20,
                onPressed: () {
                  showAppDialog(
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
              spacing: 8,
              children: playlists.map((playlist) {
                return AppCard(
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
                                style: AppTextStyles.body,
                              ),
                            ),
                            Text('${playlist.tracks.length}'),
                            const SizedBox(width: 8),
                            AppIconButton(
                              icon: const PhosphorIcon(
                                  PhosphorIconsRegular.pencil),
                              iconSize: 20,
                              onPressed: () {
                                showAppDialog(
                                  context: context,
                                  builder: (context) => EditPlaylistDialog(
                                    playlist: playlist,
                                  ),
                                );
                              },
                            ),
                            AppIconButton(
                              icon: const PhosphorIcon(
                                  PhosphorIconsRegular.folder),
                              iconSize: 20,
                              onPressed: () {
                                playlist.openFolder();
                              },
                            ),
                          ],
                        ),
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
