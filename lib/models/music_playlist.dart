import 'dart:io';
import 'package:cartridge/models/music_track.dart';
import 'package:cartridge/models/music_trigger_condition.dart';

class MusicPlaylist {
  final String id;
  final String name;
  final MusicTriggerCondition condition;
  final String folderPath;

  final Map<String, List<MusicTrack>> tracks = {};

  MusicPlaylist({
    required this.id,
    required this.name,
    required this.condition,
    required this.folderPath,
  });

  Future<bool> get isFolderExists async {
    final folder = Directory(folderPath);
    return await folder.exists();
  }

  Future<void> loadTracks() async {
    tracks.clear();

    final folder = Directory(folderPath);

    if (!await folder.exists()) {
      return;
    }

    await for (final entity in folder.list()) {
      if (entity is Directory) {
        final groupName = entity.path.split(Platform.pathSeparator).last;
        final groupTracks = <MusicTrack>[];

        await for (final file in entity.list()) {
          if (file is File && _isMusicFile(file.path)) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            groupTracks.add(MusicTrack(title: fileName, filePath: file.path));
          }
        }

        if (groupTracks.isNotEmpty) {
          tracks[groupName] = groupTracks;
        }
      } else if (entity is File && _isMusicFile(entity.path)) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        tracks
            .putIfAbsent('미분류', () => [])
            .add(MusicTrack(title: fileName, filePath: entity.path));
      }
    }
  }

  bool _isMusicFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac'].contains(ext);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'condition': condition.toJson(),
      'folderPath': folderPath,
    };
  }

  factory MusicPlaylist.fromJson(Map<String, dynamic> json) {
    return MusicPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      condition: MusicTriggerCondition.fromJson(
          json['condition'] as Map<String, dynamic>),
      folderPath: json['folderPath'] as String,
    );
  }
}
