import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MusicPlayer extends ConsumerStatefulWidget {
  const MusicPlayer({super.key, this.onTap, this.isSelected});

  final bool? isSelected;
  final VoidCallback? onTap;

  @override
  ConsumerState<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends ConsumerState<MusicPlayer> {
  final player = AudioPlayer();

  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _playerState = player.state;
    player.getDuration().then((value) => setState(() => _duration = value));
    player
        .getCurrentPosition()
        .then((value) => setState(() => _position = value));
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    player.dispose();
    super.dispose();
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() => _playerState = state);
    });
  }

  Future<void> _play() async {
    await player.resume();
  }

  Future<void> _pause() async {
    await player.pause();
  }

  @override
  Widget build(BuildContext context) {
    return material.Ink(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isSelected == true
                ? FluentTheme.of(context).accentColor
                : Colors.black.withValues(alpha: 0.1),
            width: 1,
          )),
      child: material.InkWell(
        onTap: widget.onTap,
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
                      'Now Playing',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[130],
                      ),
                    ),
                  ),
                  Text(
                    _duration != null
                        ? '${_position?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_position?.inSeconds.remainder(60).toString().padLeft(2, '0')} / ${_duration?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_duration?.inSeconds.remainder(60).toString().padLeft(2, '0')}'
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
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsFill.skipBack,
                        size: 16),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: PhosphorIcon(
                      _isPlaying
                          ? PhosphorIconsFill.pause
                          : PhosphorIconsFill.play,
                      size: 20,
                    ),
                    onPressed: _isPlaying ? _pause : _play,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsFill.skipForward,
                        size: 16),
                    onPressed: () {},
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
