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

    _hotkeyService.registerPlayPauseHotkey(setting.playPauseHotkey);
    _hotkeyService.registerNextTrackHotkey(setting.nextTrackHotkey);
    _hotkeyService.registerVolumeUpHotkey(setting.volumeUpHotkey);
    _hotkeyService.registerVolumeDownHotkey(setting.volumeDownHotkey);

    ref.listen(settingProvider, (previous, next) {
      if (previous?.playPauseHotkey != next.playPauseHotkey) {
        _hotkeyService.registerPlayPauseHotkey(next.playPauseHotkey);
      }
      if (previous?.nextTrackHotkey != next.nextTrackHotkey) {
        _hotkeyService.registerNextTrackHotkey(next.nextTrackHotkey);
      }
      if (previous?.volumeUpHotkey != next.volumeUpHotkey) {
        _hotkeyService.registerVolumeUpHotkey(next.volumeUpHotkey);
      }
      if (previous?.volumeDownHotkey != next.volumeDownHotkey) {
        _hotkeyService.registerVolumeDownHotkey(next.volumeDownHotkey);
      }
    });
  }

  void dispose() {
    _hotkeyService.unregisterAll();
  }
}

final hotkeyProvider = Provider<HotkeyNotifier>((ref) {
  final notifier = HotkeyNotifier(ref);
  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
});
