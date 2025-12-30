import 'dart:async';

import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/services/hotkey_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HotkeyNotifier {
  HotkeyNotifier(this.ref) {
    _init();
  }

  final Ref ref;
  final HotkeyService _hotkeyService = HotkeyService();
  Timer? _registerTimer;

  void _init() {
    final setting = ref.read(settingProvider);
    final musicPlayer = ref.read(musicPlayerProvider);

    _hotkeyService.onPlayPause = () {
      if (musicPlayer.isPlaying) {
        musicPlayer.pause();
      } else {
        musicPlayer.play();
      }
    };

    _hotkeyService.onNextTrack = () {
      musicPlayer.playNext();
    };

    _hotkeyService.onVolumeUp = () {
      final currentVolume = setting.musicVolume;
      setting.musicVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
      setting.saveSetting();
    };

    _hotkeyService.onVolumeDown = () {
      final currentVolume = setting.musicVolume;
      setting.musicVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
      setting.saveSetting();
    };

    ref.listen(
      settingProvider,
      (_, next) {
        _registerTimer?.cancel();
        _registerTimer = Timer(const Duration(milliseconds: 500), () async {
          await _hotkeyService.unregisterAll();
          await _hotkeyService.registerPlayPauseHotkey(next.playPauseHotkey);
          await _hotkeyService.registerNextTrackHotkey(next.nextTrackHotkey);
          await _hotkeyService.registerVolumeUpHotkey(next.volumeUpHotkey);
          await _hotkeyService.registerVolumeDownHotkey(next.volumeDownHotkey);
        });
      },
      fireImmediately: true,
    );
  }

  Future<void> dispose() async {
    _registerTimer?.cancel();
    await _hotkeyService.unregisterAll();
  }
}

final hotkeyProvider = Provider<HotkeyNotifier>((ref) {
  final notifier = HotkeyNotifier(ref);
  ref.onDispose(() async {
    await notifier.dispose();
  });
  return notifier;
});
