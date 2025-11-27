import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cartridge/models/music_playlist.dart';
import 'package:cartridge/models/music_trigger_condition.dart';
import 'package:cartridge/providers/isaac_event_manager_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicPlayerNotifier extends ChangeNotifier {
  MusicPlayerNotifier(this.ref) {
    _initAudioPlayer();
  }

  final Ref ref;

  ProviderSubscription<SettingNotifier>? musicSettingSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<MusicPlaylist> _playlists = [];
  final List<MusicPlaylist> _playlistStack = [];

  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  double _volume = 1.0;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  List<MusicPlaylist> get playlists => _playlists;
  PlayerState? get playerState => _playerState;
  Duration? get duration => _duration;
  Duration? get position => _position;
  bool get isPlaying => _playerState == PlayerState.playing;
  double get volume => _volume;

  void _initAudioPlayer() {
    _playerState = _audioPlayer.state;

    _audioPlayer.getDuration().then((value) {
      _duration = value;
      notifyListeners();
    });

    _audioPlayer.getCurrentPosition().then((value) {
      _position = value;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _playerStateChangeSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    loadPlaylists();

    musicSettingSubscription = ref.listen(settingProvider, (previous, next) {
      loadPlaylists();
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _playNextTrack();
    });

    final isaacEventManager = ref.read(isaacEventManagerProvider);

    isaacEventManager.stageEnteredStream.listen((event) {
      _handleStageEntered(event.stage);
    });

    isaacEventManager.roomEnteredStream.listen((event) {
      _handleRoomEntered(event.roomType, event.isCleared);
    });

    isaacEventManager.bossClearedStream.listen((event) {
      _handleBossCleared(event.bossType);
    });
  }

  void _debugPrintStack() {
    if (_playlistStack.isEmpty) {
      debugPrint('[MusicStack] Empty');
    } else {
      debugPrint('[MusicStack] Stack (${_playlistStack.length} items):');
      for (int i = _playlistStack.length - 1; i >= 0; i--) {
        final playlist = _playlistStack[i];
        final marker = i == _playlistStack.length - 1 ? '-> ' : '   ';
        debugPrint(
            '$marker[$i] ${playlist.id} (${playlist.condition?.type ?? 'default'})');
      }
    }
  }

  void _handleStageEntered(stage) {
    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is StageStayingCondition) {
        return (p.condition as StageStayingCondition).stage.contains(stage);
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      _processEvent(matchedPlaylists.first, 'stage');
    }
  }

  void _handleRoomEntered(roomType, bool isCleared) {
    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is RoomStayingCondition) {
        final condition = p.condition as RoomStayingCondition;
        return condition.roomType == roomType &&
            (!condition.isOnlyUncleared || !isCleared);
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      _processEvent(matchedPlaylists.first, 'room');
    }
  }

  void _handleBossCleared(bossType) {
    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is BossClearedCondition) {
        return (p.condition as BossClearedCondition).bossType == bossType;
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      _processEvent(matchedPlaylists.first, 'boss');
    }
  }

  void _processEvent(MusicPlaylist playlist, String conditionType) {
    final existingIndex =
        _playlistStack.indexWhere((p) => p.condition?.type == conditionType);

    if (existingIndex != -1) {
      debugPrint(
          '[MusicStack] Found existing type "$conditionType" at index $existingIndex, popping to that level');
      while (_playlistStack.length > existingIndex) {
        _playlistStack.removeLast();
      }
    }

    _playlistStack.add(playlist);
    debugPrint('[MusicStack] Pushed "${playlist.id}" (type: $conditionType)');
    _debugPrintStack();

    _playNextTrack();
  }

  void _playNextTrack() async {
    if (_playlistStack.isEmpty) {
      final defaultPlaylist =
          _playlists.where((p) => p.condition == null).toList();
      if (defaultPlaylist.isNotEmpty) {
        _playlistStack.add(defaultPlaylist.first);
        debugPrint(
            '[MusicStack] Initialized with default playlist: ${defaultPlaylist.first.id}');
        _debugPrintStack();
      }
    }

    if (_playlistStack.isEmpty) {
      debugPrint('[MusicStack] No playlists available');
      return;
    }

    final currentPlaylist = _playlistStack.last;
    final track = currentPlaylist.getRandomTrack();

    if (track == null) {
      debugPrint(
          '[MusicStack] No tracks in current playlist: ${currentPlaylist.id}');
      return;
    }

    debugPrint(
        '[MusicStack] Playing: ${track.title} from ${currentPlaylist.id}');
    await _audioPlayer.play(DeviceFileSource(track.filePath));
  }

  Future<void> play() async {
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    final newVolume = volume.clamp(0.0, 1.0);
    if (_volume != newVolume) {
      _volume = newVolume;
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    }
  }

  Future<void> playSource(String source) async {
    await _audioPlayer.play(DeviceFileSource(source));
  }

  void resetMusicStack() {
    _playlistStack.clear();
    debugPrint('[MusicStack] Stack cleared');
    _debugPrintStack();
    _playNextTrack();
  }

  Future<void> loadPlaylists() async {
    final setting = ref.read(settingProvider);
    final directory = Directory(setting.musicPlaylistPath);

    if (!(await directory.exists())) {
      _playlists = [];
      notifyListeners();
      return;
    }

    final result = <MusicPlaylist>[];

    await for (final entity in directory.list()) {
      if (entity is Directory) {
        final playlist = MusicPlaylist(
          id: entity.path.split(Platform.pathSeparator).last,
          rootPath: setting.musicPlaylistPath,
        );
        result.add(playlist);
      }
    }

    for (final playlist in result) {
      await playlist.loadTracks();
    }

    final file = File('${setting.musicPlaylistPath}/music_playlists.json');

    if (!(await file.exists())) {
      _playlists = result;
      notifyListeners();
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final playlistsJson = json['playlists'] as List<dynamic>?;

    if (playlistsJson == null) {
      notifyListeners();
      return;
    }

    final playlists = playlistsJson
        .map(
          (playlist) => MusicPlaylist.fromJson(
              playlist as Map<String, dynamic>, setting.musicPlaylistPath),
        )
        .toList();

    _playlists = result.map((p) {
      final matched =
          playlists.firstWhere((loaded) => loaded.id == p.id, orElse: () => p);
      return MusicPlaylist(
        id: p.id,
        condition: matched.condition,
        tracks: p.tracks,
        rootPath: setting.musicPlaylistPath,
      );
    }).toList();

    notifyListeners();
  }

  Future<void> savePlaylists() async {
    final setting = ref.read(settingProvider);
    final file = File('${setting.musicPlaylistPath}/music_playlists.json');

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
    await loadPlaylists();
    notifyListeners();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    _audioPlayer.dispose();
    musicSettingSubscription?.close();
    super.dispose();
  }
}

final musicPlayerProvider = ChangeNotifierProvider<MusicPlayerNotifier>((ref) {
  return MusicPlayerNotifier(ref);
});
