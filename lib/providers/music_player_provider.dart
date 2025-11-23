import 'dart:convert';
import 'dart:io';

import 'package:cartridge/models/music_playlist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class MusicPlayerNotifier extends ChangeNotifier {
  MusicPlayerNotifier() {
    loadPlaylists();
  }

  List<MusicPlaylist> _playlists = [];

  List<MusicPlaylist> get playlists => _playlists;

  Future<void> loadPlaylists() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/music_playlists.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final playlistsJson = json['playlists'] as List<dynamic>?;

    if (playlistsJson != null) {
      _playlists = playlistsJson
          .map((playlist) =>
              MusicPlaylist.fromJson(playlist as Map<String, dynamic>))
          .toList();

      for (final playlist in _playlists) {
        await playlist.loadTracks();
      }
    }

    notifyListeners();
  }

  Future<void> savePlaylists() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/music_playlists.json');

    await file.writeAsString(jsonEncode({
      'version': 1,
      'playlists': _playlists.map((playlist) => playlist.toJson()).toList(),
    }));
  }

  void addPlaylist(MusicPlaylist playlist) {
    _playlists.add(playlist);
    savePlaylists();
    notifyListeners();
  }

  void removePlaylist(String id) {
    _playlists.removeWhere((playlist) => playlist.id == id);
    savePlaylists();
    notifyListeners();
  }

  void updatePlaylist(String id, MusicPlaylist updatedPlaylist) {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index != -1) {
      _playlists[index] = updatedPlaylist;
      savePlaylists();
      notifyListeners();
    }
  }

  Future<void> reloadPlaylist() async {
    for (final playlist in _playlists) {
      await playlist.loadTracks();
    }
    notifyListeners();
  }
}

final musicPlayerProvider = ChangeNotifierProvider<MusicPlayerNotifier>((ref) {
  return MusicPlayerNotifier();
});
