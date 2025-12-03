import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/services/hotkey_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HotkeyNotifier extends ChangeNotifier {
  HotkeyNotifier(this.ref);

  @override
  void dispose() {
    state.unregisterAll();
    super.dispose();
  }

  final Ref ref;
  final HotkeyService state = HotkeyService();

  void init() {
    final setting = ref.watch(settingProvider);
    final musicPlayer = ref.read(musicPlayerProvider);

    state.onPlayPause = () {
      if (musicPlayer.isPlaying) {
        musicPlayer.pause();
      } else {
        musicPlayer.play();
      }
    };

    state.onNextTrack = () {
      musicPlayer.playNext();
    };

    state.onVolumeUp = () {
      final currentVolume = setting.musicVolume;
      setting.musicVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
      setting.saveSetting();
    };

    state.onVolumeDown = () {
      final currentVolume = setting.musicVolume;
      setting.musicVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
      setting.saveSetting();
    };

    state.registerPlayPauseHotkey(setting.playPauseHotkey);
    state.registerNextTrackHotkey(setting.nextTrackHotkey);
    state.registerVolumeUpHotkey(setting.volumeUpHotkey);
    state.registerVolumeDownHotkey(setting.volumeDownHotkey);

    ref.listen(settingProvider, (previous, next) {
      if (previous?.playPauseHotkey != next.playPauseHotkey) {
        state.registerPlayPauseHotkey(next.playPauseHotkey);
      }
      if (previous?.nextTrackHotkey != next.nextTrackHotkey) {
        state.registerNextTrackHotkey(next.nextTrackHotkey);
      }
      if (previous?.volumeUpHotkey != next.volumeUpHotkey) {
        state.registerVolumeUpHotkey(next.volumeUpHotkey);
      }
      if (previous?.volumeDownHotkey != next.volumeDownHotkey) {
        state.registerVolumeDownHotkey(next.volumeDownHotkey);
      }
    });
  }
}

final hotkeyProvider = Provider<HotkeyNotifier>((ref) => HotkeyNotifier(ref));
