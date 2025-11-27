import 'dart:io';
import 'package:cartridge/models/music_track.dart';
import 'package:cartridge/models/music_trigger_condition.dart';
import 'package:path/path.dart';

class MusicPlaylist {
  final String id;
  final MusicTriggerCondition? condition;

  final List<MusicTrack> tracks;

  late final String path;

  MusicPlaylist({
    required this.id,
    required String rootPath,
    this.condition,
    List<MusicTrack>? tracks,
  }) : tracks = tracks ?? [] {
    path = join(rootPath, id);
  }

  Future<bool> get isFolderExists async {
    final folder = Directory(path);
    return await folder.exists();
  }

  Future<void> loadTracks() async {
    tracks.clear();

    final folder = Directory(path);

    if (!await folder.exists()) {
      return;
    }

    await for (final entity in folder.list()) {
      if (entity is Directory) {
        await for (final file in entity.list()) {
          if (file is File && _isMusicFile(file.path)) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            tracks.add(MusicTrack(title: fileName, filePath: file.path));
          }
        }
      } else if (entity is File && _isMusicFile(entity.path)) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        tracks.add(MusicTrack(title: fileName, filePath: entity.path));
      }
    }
  }

  bool _isMusicFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac'].contains(ext);
  }

  void openFolder() async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path.replaceAll(RegExp('/'), "\\")]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condition': condition?.toJson(),
    };
  }

  factory MusicPlaylist.fromJson(Map<String, dynamic> json, String path) {
    return MusicPlaylist(
      id: json['id'] as String,
      condition: json['condition'] != null
          ? MusicTriggerCondition.fromJson(
              json['condition'] as Map<String, dynamic>)
          : null,
      rootPath: path,
    );
  }
}
