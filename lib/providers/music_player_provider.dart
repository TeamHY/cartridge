import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cartridge/constants/isaac_enums.dart';
import 'package:cartridge/models/music_playlist.dart';
import 'package:cartridge/models/music_trigger_condition.dart';
import 'package:cartridge/providers/isaac_event_manager_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicPlayerNotifier extends ChangeNotifier {
  static const Duration _suspendFadeOutDuration = Duration(milliseconds: 150);
  static const Duration _suspendFadeInDuration = Duration(milliseconds: 300);
  static const Duration _fadeInterval = Duration(milliseconds: 30);

  MusicPlayerNotifier(this.ref) {
    _initAudioPlayer();
  }

  final Ref ref;

  ProviderSubscription<SettingNotifier>? musicSettingSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<MusicPlaylist> _playlists = [];
  final List<MusicPlaylist> _playlistStack = [];
  MusicPlaylist? _currentPlaylist;
  String? _currentTrackTitle;

  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  Timer? _nextTrackTimer;
  String? _pendingTrackPath;
  bool _waitingForNextTrack = false;
  int _playbackRequest = 0;
  Future<void> _playbackOperation = Future.value();
  final List<StreamSubscription> _eventSubscriptions = [];

  bool _isSuspended = false;
  bool _resumeAfterSuspend = false;
  Timer? _suspendTimer;
  DateTime? _suspendUntil;
  Timer? _fadeTimer;
  Completer<bool>? _fadeCompleter;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  List<MusicPlaylist> get playlists => _playlists;
  PlayerState? get playerState => _playerState;
  Duration? get duration => _duration;
  Duration? get position => _position;
  bool get isPlaying => _isSuspended
      ? _resumeAfterSuspend
      : _waitingForNextTrack || _playerState == PlayerState.playing;
  bool get isSuspended => _isSuspended;
  String? get currentTrackTitle => _currentTrackTitle;
  MusicPlaylist? get currentPlaylist => _currentPlaylist;

  void _initAudioPlayer() {
    _playerState = _audioPlayer.state;

    _audioPlayer.setPlaybackRate(0.5);

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

      if (!_isSuspended &&
          _fadeTimer == null &&
          _audioPlayer.volume != next.musicVolume) {
        _audioPlayer.setVolume(next.musicVolume);
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _updatePlayback(forcePlay: true);
    });

    final isaacEventManager = ref.read(isaacEventManagerProvider);

    _eventSubscriptions.add(
        isaacEventManager.stageEnteredStream.listen((event) {
      _handleStageEntered(event.stage);
    }));

    _eventSubscriptions.add(
        isaacEventManager.roomEnteredStream.listen((event) {
      _handleRoomEntered(event.roomType, event.isCleared);
    }));

    _eventSubscriptions.add(
        isaacEventManager.roomClearedStream.listen((event) {
      _handleRoomCleared(event.roomType);
    }));

    _eventSubscriptions.add(
        isaacEventManager.bossClearedStream.listen((event) {
      _handleBossCleared(event.bossType);
    }));

    _eventSubscriptions.add(
        isaacEventManager.musicPauseStream.listen((event) {
      suspendFor(event.duration);
    }));
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

  void _handleStageEntered(IsaacStage stage) {
    _resetPlaylistStack();

    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is StageStayingCondition) {
        return (p.condition as StageStayingCondition).stage.contains(stage);
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      matchedPlaylists.shuffle();
      _processEvent('stage', matchedPlaylists.first);
    } else {
      _processEvent('stage', null);
    }
  }

  void _handleRoomEntered(IsaacRoomType roomType, bool isCleared) {
    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is RoomStayingCondition) {
        final condition = p.condition as RoomStayingCondition;

        if (!condition.roomTypes.contains(roomType)) return false;

        if (isCleared) return !condition.isOnlyWithMonsters;

        return true;
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      if (!isCleared) {
        final withMonstersPlaylists = matchedPlaylists
            .where(
                (p) => (p.condition as RoomStayingCondition).isOnlyWithMonsters)
            .toList();

        if (withMonstersPlaylists.isNotEmpty) {
          withMonstersPlaylists.shuffle();
          _processEvent('room', withMonstersPlaylists.first);
          return;
        }
      }

      matchedPlaylists.shuffle();
      _processEvent('room', matchedPlaylists.first);
    } else {
      _processEvent('room', null);
    }
  }

  void _handleRoomCleared(IsaacRoomType roomType) {
    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is RoomStayingCondition) {
        final condition = p.condition as RoomStayingCondition;

        if (!condition.roomTypes.contains(roomType)) return false;

        return !condition.isOnlyWithMonsters;
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      matchedPlaylists.shuffle();
      _processEvent('room', matchedPlaylists.first);
    } else {
      _processEvent('room', null);
    }
  }

  void _handleBossCleared(IsaacBossType bossType) {
    final matchedPlaylists = _playlists.where((p) {
      if (p.condition is BossClearedCondition) {
        return (p.condition as BossClearedCondition)
            .bossTypes
            .contains(bossType);
      }
      return false;
    }).toList();

    if (matchedPlaylists.isNotEmpty) {
      matchedPlaylists.shuffle();
      _processEvent('boss', matchedPlaylists.first);
    } else {
      _processEvent('boss', null);
    }
  }

  void _processEvent(String conditionType, MusicPlaylist? playlist) {
    final existingIndex =
        _playlistStack.indexWhere((p) => p.condition?.type == conditionType);

    if (existingIndex != -1) {
      debugPrint(
          '[MusicStack] Found existing type "$conditionType" at index $existingIndex, popping to that level');
      _playlistStack.removeAt(existingIndex);
    }

    if (playlist == null) {
      debugPrint(
          '[MusicStack] No matching playlist for condition type "$conditionType"');
      _debugPrintStack();
    } else {
      _playlistStack.add(playlist);
      debugPrint('[MusicStack] Pushed "${playlist.id}" (type: $conditionType)');
    }

    _debugPrintStack();
    _updatePlayback();
  }

  void _resetPlaylistStack() {
    _playlistStack.clear();
    debugPrint('[MusicStack] Stack cleared');
    _debugPrintStack();
  }

  void _cancelPendingPlayback({bool keepTrack = false}) {
    _playbackRequest++;
    _nextTrackTimer?.cancel();
    _nextTrackTimer = null;
    _waitingForNextTrack = false;
    if (!keepTrack) _pendingTrackPath = null;
  }

  Future<void> _runPlaybackOperation(
      int request, Future<void> Function() action) {
    final operation = _playbackOperation.then((_) async {
      if (request == _playbackRequest) await action();
    });
    _playbackOperation = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _playTrack(String path, int request) async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
      if (request != _playbackRequest) return;
    }

    await _audioPlayer.setSource(DeviceFileSource(path));
    if (request != _playbackRequest) return;

    if (_isSuspended) {
      _resumeAfterSuspend = true;
      return;
    }

    await _audioPlayer.resume();
  }

  Future<void> _runSuspendOperation(Future<void> Function() action) {
    _playbackOperation =
        _playbackOperation.then((_) => action()).catchError((Object _) {});
    return _playbackOperation;
  }

  Future<void> suspendFor(Duration duration) async {
    if (duration <= Duration.zero) {
      await _endSuspend();
      return;
    }

    final until = DateTime.now().add(duration);

    final suspendUntil = _suspendUntil;

    if (_isSuspended && suspendUntil != null && suspendUntil.isAfter(until)) {
      return;
    }

    _suspendUntil = until;
    _suspendTimer?.cancel();
    _suspendTimer = Timer(duration, _endSuspend);

    if (_isSuspended) return;

    _isSuspended = true;
    _resumeAfterSuspend = _audioPlayer.state == PlayerState.playing;
    debugPrint('[MusicSuspend] Suspended for ${duration.inMilliseconds}ms');
    notifyListeners();

    if (_resumeAfterSuspend) {
      final faded = await _fadeVolume(() => 0, _suspendFadeOutDuration);
      if (!faded || !_isSuspended) return;
    }

    await _runSuspendOperation(_audioPlayer.pause);
  }

  Future<void> _endSuspend() async {
    _suspendTimer?.cancel();
    _suspendTimer = null;
    _suspendUntil = null;

    if (!_isSuspended) return;

    final shouldResume = _resumeAfterSuspend;
    _isSuspended = false;
    _resumeAfterSuspend = false;
    debugPrint('[MusicSuspend] Ended (resume: $shouldResume)');
    notifyListeners();

    if (!shouldResume) {
      _cancelFade();
      await _audioPlayer.setVolume(_musicVolume);
      return;
    }

    await _runSuspendOperation(() async {
      if (_audioPlayer.state != PlayerState.playing) {
        await _audioPlayer.setVolume(0);
      }
      await _audioPlayer.resume();
    });

    if (!_isSuspended) {
      await _fadeVolume(() => _musicVolume, _suspendFadeInDuration);
    }
  }

  double get _musicVolume => ref.read(settingProvider).musicVolume;

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _fadeCompleter?.complete(false);
    _fadeCompleter = null;
  }

  Future<bool> _fadeVolume(double Function() target, Duration duration) {
    _cancelFade();

    final from = _audioPlayer.volume;
    final completer = Completer<bool>();
    final stopwatch = Stopwatch()..start();
    _fadeCompleter = completer;

    _fadeTimer = Timer.periodic(_fadeInterval, (timer) {
      final progress = (stopwatch.elapsedMicroseconds /
              duration.inMicroseconds)
          .clamp(0.0, 1.0);
      _audioPlayer.setVolume(from + (target() - from) * progress);

      if (progress >= 1) {
        timer.cancel();
        _fadeTimer = null;
        _fadeCompleter = null;
        completer.complete(true);
      }
    });

    return completer.future;
  }

  Future<void> _playPendingTrack(int request) async {
    if (request != _playbackRequest) return;

    _nextTrackTimer = null;
    await _runPlaybackOperation(request, () async {
      final path = _pendingTrackPath;
      _waitingForNextTrack = false;
      notifyListeners();

      if (path != null && request == _playbackRequest) {
        await _playTrack(path, request);
        if (request == _playbackRequest) _pendingTrackPath = null;
      }
    });
  }

  Future<void> _updatePlayback({
    bool forcePlay = false,
    bool delayPlayback = true,
  }) async {
    if (_playlistStack.isEmpty) {
      _cancelPendingPlayback();
      final request = _playbackRequest;
      _currentPlaylist = null;
      _currentTrackTitle = null;
      notifyListeners();
      await _runPlaybackOperation(request, _audioPlayer.release);
      debugPrint('[MusicStack] No playlists available');
      return;
    }

    final targetPlaylist = _playlistStack.last;

    if (!forcePlay && _currentPlaylist == targetPlaylist) {
      debugPrint(
          '[MusicStack] Playlist unchanged (${targetPlaylist.id}), skipping playback');
      return;
    }

    _cancelPendingPlayback();
    final request = _playbackRequest;
    _currentPlaylist = targetPlaylist;
    final track = targetPlaylist.getRandomTrack();

    if (track == null) {
      _currentTrackTitle = null;
      notifyListeners();
      await _runPlaybackOperation(request, _audioPlayer.stop);
      debugPrint(
          '[MusicStack] No tracks in current playlist: ${targetPlaylist.id}');
      return;
    }

    _currentTrackTitle = track.title;
    debugPrint(
        '[MusicStack] Playing: ${track.title} from ${targetPlaylist.id}');
    _pendingTrackPath = track.filePath;
    final delay = ref.read(settingProvider).musicTrackDelay;
    if (delayPlayback && delay > 0) {
      _waitingForNextTrack = true;
      _position = Duration.zero;
      _duration = null;
      notifyListeners();
      await _runPlaybackOperation(request, _audioPlayer.stop);
      if (request != _playbackRequest) return;

      _nextTrackTimer = Timer(Duration(milliseconds: delay), () {
        _playPendingTrack(request);
      });
    } else {
      notifyListeners();
      await _playPendingTrack(request);
    }
  }

  Future<void> play() async {
    if (_isSuspended && _pendingTrackPath == null) {
      _resumeAfterSuspend = true;
      notifyListeners();
      return;
    }

    _cancelPendingPlayback(keepTrack: true);
    if (_pendingTrackPath != null) {
      await _playPendingTrack(_playbackRequest);
    } else {
      await _runPlaybackOperation(_playbackRequest, _audioPlayer.resume);
    }
  }

  Future<void> playNext() async {
    await _updatePlayback(forcePlay: true, delayPlayback: false);
  }

  Future<void> pause() async {
    _resumeAfterSuspend = false;
    _cancelPendingPlayback(keepTrack: true);
    final request = _playbackRequest;
    notifyListeners();
    await _runPlaybackOperation(request, _audioPlayer.pause);
  }

  Future<void> stop() async {
    _resumeAfterSuspend = false;
    _cancelPendingPlayback(keepTrack: true);
    final request = _playbackRequest;
    notifyListeners();
    await _runPlaybackOperation(request, _audioPlayer.stop);
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> playSource(String source) async {
    _cancelPendingPlayback();
    final request = _playbackRequest;
    _pendingTrackPath = source;
    notifyListeners();
    await _playPendingTrack(request);
  }

  void resetMusicStack() {
    _playlistStack.clear();
    _currentPlaylist = null;
    _currentTrackTitle = null;
    debugPrint('[MusicStack] Stack cleared');
    _debugPrintStack();
    _updatePlayback();
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
    _cancelPendingPlayback();
    _suspendTimer?.cancel();
    _cancelFade();
    for (final subscription in _eventSubscriptions) {
      subscription.cancel();
    }
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    _playbackOperation.then((_) => _audioPlayer.dispose());
    musicSettingSubscription?.close();
    super.dispose();
  }
}

final musicPlayerProvider = ChangeNotifierProvider<MusicPlayerNotifier>((ref) {
  return MusicPlayerNotifier(ref);
});
