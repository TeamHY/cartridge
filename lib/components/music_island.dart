import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _collapsedSize = Size(180, 24);
const _expandedSize = Size(420, 99);
const _padding = 12.0;
const _slotSize = 28.0;
const _collapsedSlotSize = 24.0;
const _titleOpticalOffset = Offset(0, -0.75);
const _hoverGrowth = 0.06;
const _expandedMinLayoutWidth = 340.0;

String _formatDuration(Duration? duration) {
  if (duration == null) return '00:00';
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class MusicIsland extends ConsumerStatefulWidget {
  const MusicIsland({super.key, required this.onOpenMusic});

  final VoidCallback onOpenMusic;

  @override
  ConsumerState<MusicIsland> createState() => _MusicIslandState();
}

class _MusicIslandState extends ConsumerState<MusicIsland>
    with TickerProviderStateMixin {
  static final _openSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 220, ratio: 0.72);
  static final _closeSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: 0.9);

  late final AnimationController _progress =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _hover =
      AnimationController.unbounded(vsync: this);
  bool _isOpen = false;
  bool _isHovered = false;
  bool _isPressed = false;
  Timer? _closeTimer;

  void _toggleMute(double volume) {
    final setting = ref.read(settingProvider);
    if (volume > 0) {
      setting.musicVolumeBeforeMute = volume;
      setting.musicVolume = 0;
    } else {
      setting.musicVolume = setting.musicVolumeBeforeMute;
    }
    setting.saveSetting();
  }

  void _setOpen(bool value) {
    _closeTimer?.cancel();
    if (_isOpen == value) return;
    setState(() => _isOpen = value);
    _progress.animateWith(SpringSimulation(
      value ? _openSpring : _closeSpring,
      _progress.value,
      value ? 1 : 0,
      _progress.velocity,
    ));
  }

  void _animateHover(bool value) {
    _hover.animateWith(SpringSimulation(
      _openSpring,
      _hover.value,
      value ? 1 : 0,
      _hover.velocity,
    ));
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    if (!_isOpen) return;
    _closeTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_isHovered && !_isPressed) _setOpen(false);
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _progress.dispose();
    _hover.dispose();
    super.dispose();
  }

  AppColors get _c => AppColors.of(context);

  Color get _foreground => _c.ink;

  Color get _accent => _c.accent;

  Widget _layer({
    required double opacity,
    required bool interactive,
    required double width,
    required double minWidth,
    required Widget child,
  }) {
    final layoutWidth = math.max(width, minWidth);

    return IgnorePointer(
      ignoring: !interactive,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: width / layoutWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(width: layoutWidth, child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayer = ref.watch(musicPlayerProvider);
    final collapsed = _buildCollapsed(musicPlayer);
    final expanded = _buildExpanded(musicPlayer);

    final island = AnimatedBuilder(
      animation: Listenable.merge([_progress, _hover]),
      builder: (context, _) {
        final p = _progress.value;
        final t = p.clamp(0.0, 1.0);

        final width = lerpDouble(_collapsedSize.width, _expandedSize.width, p)!;

        final body = Container(
          width: width,
          height: lerpDouble(_collapsedSize.height, _expandedSize.height, p),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color.lerp(_c.surface3, _c.surfaceRaised, t),
            border: Border.all(color: Color.lerp(_c.surface3, _c.line, t)!),
            borderRadius: BorderRadius.circular(
              lerpDouble(12, AppRadius.lg, t)!,
            ),
            boxShadow: [
              BoxShadow(
                color: _c.shadowMenu.withValues(alpha: _c.shadowMenu.a * t),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: IconTheme(
              data: IconThemeData(color: _foreground),
              child: DefaultTextStyle(
                style: TextStyle(color: _foreground, fontSize: 12),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  minHeight: 0,
                  maxHeight: _expandedSize.height,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      _layer(
                        opacity: (1 - t / 0.35).clamp(0.0, 1.0),
                        interactive: !_isOpen,
                        width: width,
                        minWidth: _collapsedSize.width,
                        child: collapsed,
                      ),
                      _layer(
                        opacity: ((t - 0.15) / 0.55).clamp(0.0, 1.0),
                        interactive: _isOpen,
                        width: width,
                        minWidth: _expandedMinLayoutWidth,
                        child: expanded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        return Transform.scale(
          scale: 1 + _hoverGrowth * _hover.value * (1 - t),
          child: body,
        );
      },
    );

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: MouseRegion(
          onEnter: (_) {
            _isHovered = true;
            _closeTimer?.cancel();
            _animateHover(true);
          },
          onExit: (_) {
            _isHovered = false;
            _scheduleClose();
            _animateHover(false);
          },
          child: Listener(
            onPointerDown: (_) => _isPressed = true,
            onPointerUp: (_) {
              _isPressed = false;
              if (!_isHovered) _scheduleClose();
            },
            onPointerCancel: (_) {
              _isPressed = false;
              if (!_isHovered) _scheduleClose();
            },
            child: island,
          ),
        ),
      ),
    );
  }

  Widget _slot(double size, Widget child) {
    return SizedBox.square(dimension: size, child: Center(child: child));
  }

  Widget _trackButton(MusicPlayerNotifier musicPlayer,
      {required bool expanded}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setOpen(!_isOpen),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              _slot(
                expanded ? _slotSize : _collapsedSlotSize,
                PhosphorIcon(
                  musicPlayer.isPlaying
                      ? PhosphorIconsBold.waveform
                      : PhosphorIconsBold.musicNote,
                  size: 14,
                  color: musicPlayer.isPlaying ? _accent : _foreground,
                ),
              ),
              SizedBox(width: expanded ? 8 : 4),
              Expanded(
                child: Transform.translate(
                  offset: _titleOpticalOffset,
                  child: Text(
                    musicPlayer.currentTrackTitle ?? 'No Track',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _foreground,
                      fontSize: expanded ? 14 : 12,
                      fontWeight: expanded ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    VoidCallback? onPressed, {
    double iconSize = 14,
    double slotSize = _slotSize,
  }) {
    return AppIconButton(
      icon: PhosphorIcon(icon),
      size: slotSize,
      iconSize: iconSize,
      color: _foreground,
      onPressed: onPressed,
    );
  }

  Widget _playButton(MusicPlayerNotifier musicPlayer,
      {required double iconSize, required double slotSize}) {
    final hasPlaylist = musicPlayer.currentPlaylist != null;

    return _iconButton(
      musicPlayer.isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
      hasPlaylist
          ? (musicPlayer.isPlaying ? musicPlayer.pause : musicPlayer.play)
          : null,
      iconSize: iconSize,
      slotSize: slotSize,
    );
  }

  Widget _buildCollapsed(MusicPlayerNotifier musicPlayer) {
    return SizedBox(
      height: _collapsedSize.height,
      child: Row(
        children: [
          _trackButton(musicPlayer, expanded: false),
          _playButton(musicPlayer, iconSize: 12, slotSize: _collapsedSlotSize),
        ],
      ),
    );
  }

  Widget _buildExpanded(MusicPlayerNotifier musicPlayer) {
    final duration = musicPlayer.duration;
    final position = musicPlayer.position;
    final progress = duration == null || duration.inMilliseconds == 0
        ? 0.0
        : ((position?.inMilliseconds ?? 0) / duration.inMilliseconds)
            .clamp(0.0, 1.0);
    final volume = ref.watch(settingProvider.select((s) => s.musicVolume));

    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _trackButton(musicPlayer, expanded: true),
              Tooltip(
                message: AppLocalizations.of(context).music_island_playlists,
                child: _iconButton(PhosphorIconsRegular.queue, () {
                  _setOpen(false);
                  widget.onOpenMusic();
                }),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: (_slotSize - 14) / 2,
              vertical: 8,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(color: _c.line),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: _accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _playButton(musicPlayer, iconSize: 16, slotSize: _slotSize),
              _iconButton(
                PhosphorIconsFill.skipForward,
                musicPlayer.currentPlaylist == null
                    ? null
                    : musicPlayer.playNext,
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: TextStyle(
                  color: _c.ink3,
                  fontSize: 12,
                  fontFamily: 'Consolas',
                ),
              ),
              const Spacer(),
              _iconButton(
                volume == 0
                    ? PhosphorIconsFill.speakerSimpleSlash
                    : PhosphorIconsFill.speakerSimpleHigh,
                () => _toggleMute(volume),
              ),
              SizedBox(
                width: 96,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: _accent,
                    inactiveTrackColor: _c.line,
                    thumbColor: _accent,
                    overlayColor: _accent.withValues(alpha: 0.1),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                  ),
                  child: Slider(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    value: volume,
                    onChanged: (value) {
                      final setting = ref.read(settingProvider);
                      setting.musicVolume = value;
                      setting.saveSetting();
                    },
                  ),
                ),
              ),
              _slot(
                _slotSize,
                Text(
                  '${(volume * 100).round()}',
                  style: TextStyle(
                    color: _c.ink3,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
