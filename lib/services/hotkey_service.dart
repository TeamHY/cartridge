import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  HotKey? _playPauseHotkey;
  HotKey? _nextTrackHotkey;
  HotKey? _volumeUpHotkey;
  HotKey? _volumeDownHotkey;

  VoidCallback? onPlayPause;
  VoidCallback? onNextTrack;
  VoidCallback? onVolumeUp;
  VoidCallback? onVolumeDown;

  Future<void> registerPlayPauseHotkey(String hotkeyString) async {
    if (hotkeyString.trim().isEmpty) {
      return;
    }

    try {
      final hotkey = _parseHotkey(hotkeyString);
      if (hotkey != null) {
        await hotKeyManager.register(
          hotkey,
          keyDownHandler: (hotKey) {
            debugPrint('[HotkeyService] Play/Pause hotkey pressed');
            onPlayPause?.call();
          },
        );
        _playPauseHotkey = hotkey;
        debugPrint(
            '[HotkeyService] Registered play/pause hotkey: $hotkeyString');
      }
    } catch (e) {
      debugPrint('[HotkeyService] Failed to register play/pause hotkey: $e');
    }
  }

  Future<void> registerNextTrackHotkey(String hotkeyString) async {
    if (hotkeyString.trim().isEmpty) {
      return;
    }

    try {
      final hotkey = _parseHotkey(hotkeyString);
      if (hotkey != null) {
        await hotKeyManager.register(
          hotkey,
          keyDownHandler: (hotKey) {
            debugPrint('[HotkeyService] Next track hotkey pressed');
            onNextTrack?.call();
          },
        );
        _nextTrackHotkey = hotkey;
        debugPrint(
            '[HotkeyService] Registered next track hotkey: $hotkeyString');
      }
    } catch (e) {
      debugPrint('[HotkeyService] Failed to register next track hotkey: $e');
    }
  }

  Future<void> registerVolumeUpHotkey(String hotkeyString) async {
    if (hotkeyString.trim().isEmpty) {
      return;
    }

    try {
      final hotkey = _parseHotkey(hotkeyString);
      if (hotkey != null) {
        await hotKeyManager.register(
          hotkey,
          keyDownHandler: (hotKey) {
            debugPrint('[HotkeyService] Volume up hotkey pressed');
            onVolumeUp?.call();
          },
        );
        _volumeUpHotkey = hotkey;
        debugPrint(
            '[HotkeyService] Registered volume up hotkey: $hotkeyString');
      }
    } catch (e) {
      debugPrint('[HotkeyService] Failed to register volume up hotkey: $e');
    }
  }

  Future<void> registerVolumeDownHotkey(String hotkeyString) async {
    if (hotkeyString.trim().isEmpty) {
      return;
    }

    try {
      final hotkey = _parseHotkey(hotkeyString);
      if (hotkey != null) {
        await hotKeyManager.register(
          hotkey,
          keyDownHandler: (hotKey) {
            debugPrint('[HotkeyService] Volume down hotkey pressed');
            onVolumeDown?.call();
          },
        );
        _volumeDownHotkey = hotkey;
        debugPrint(
            '[HotkeyService] Registered volume down hotkey: $hotkeyString');
      }
    } catch (e) {
      debugPrint('[HotkeyService] Failed to register volume down hotkey: $e');
    }
  }

  Future<void> unregisterAll() async {
    hotKeyManager.unregisterAll();
    _playPauseHotkey = null;
    _nextTrackHotkey = null;
    _volumeUpHotkey = null;
    _volumeDownHotkey = null;
    debugPrint('[HotkeyService] Unregistered all hotkeys');
  }

  HotKey? _parseHotkey(String hotkeyString) {
    final parts = hotkeyString.toLowerCase().split('+');
    if (parts.isEmpty) return null;

    final modifiers = <HotKeyModifier>[];
    String? key;

    for (final part in parts) {
      switch (part.trim()) {
        case 'ctrl':
        case 'control':
          modifiers.add(HotKeyModifier.control);
          break;
        case 'alt':
          modifiers.add(HotKeyModifier.alt);
          break;
        case 'shift':
          modifiers.add(HotKeyModifier.shift);
          break;
        case 'meta':
        case 'win':
        case 'cmd':
          modifiers.add(HotKeyModifier.meta);
          break;
        default:
          key = part.trim();
      }
    }

    if (key == null) return null;

    final keyCode = _getKeyCode(key);
    if (keyCode == null) return null;

    return HotKey(
      key: keyCode,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
  }

  PhysicalKeyboardKey? _getKeyCode(String key) {
    switch (key) {
      case 'a':
        return PhysicalKeyboardKey.keyA;
      case 'b':
        return PhysicalKeyboardKey.keyB;
      case 'c':
        return PhysicalKeyboardKey.keyC;
      case 'd':
        return PhysicalKeyboardKey.keyD;
      case 'e':
        return PhysicalKeyboardKey.keyE;
      case 'f':
        return PhysicalKeyboardKey.keyF;
      case 'g':
        return PhysicalKeyboardKey.keyG;
      case 'h':
        return PhysicalKeyboardKey.keyH;
      case 'i':
        return PhysicalKeyboardKey.keyI;
      case 'j':
        return PhysicalKeyboardKey.keyJ;
      case 'k':
        return PhysicalKeyboardKey.keyK;
      case 'l':
        return PhysicalKeyboardKey.keyL;
      case 'm':
        return PhysicalKeyboardKey.keyM;
      case 'n':
        return PhysicalKeyboardKey.keyN;
      case 'o':
        return PhysicalKeyboardKey.keyO;
      case 'p':
        return PhysicalKeyboardKey.keyP;
      case 'q':
        return PhysicalKeyboardKey.keyQ;
      case 'r':
        return PhysicalKeyboardKey.keyR;
      case 's':
        return PhysicalKeyboardKey.keyS;
      case 't':
        return PhysicalKeyboardKey.keyT;
      case 'u':
        return PhysicalKeyboardKey.keyU;
      case 'v':
        return PhysicalKeyboardKey.keyV;
      case 'w':
        return PhysicalKeyboardKey.keyW;
      case 'x':
        return PhysicalKeyboardKey.keyX;
      case 'y':
        return PhysicalKeyboardKey.keyY;
      case 'z':
        return PhysicalKeyboardKey.keyZ;
      case '0':
        return PhysicalKeyboardKey.digit0;
      case '1':
        return PhysicalKeyboardKey.digit1;
      case '2':
        return PhysicalKeyboardKey.digit2;
      case '3':
        return PhysicalKeyboardKey.digit3;
      case '4':
        return PhysicalKeyboardKey.digit4;
      case '5':
        return PhysicalKeyboardKey.digit5;
      case '6':
        return PhysicalKeyboardKey.digit6;
      case '7':
        return PhysicalKeyboardKey.digit7;
      case '8':
        return PhysicalKeyboardKey.digit8;
      case '9':
        return PhysicalKeyboardKey.digit9;
      case 'f1':
        return PhysicalKeyboardKey.f1;
      case 'f2':
        return PhysicalKeyboardKey.f2;
      case 'f3':
        return PhysicalKeyboardKey.f3;
      case 'f4':
        return PhysicalKeyboardKey.f4;
      case 'f5':
        return PhysicalKeyboardKey.f5;
      case 'f6':
        return PhysicalKeyboardKey.f6;
      case 'f7':
        return PhysicalKeyboardKey.f7;
      case 'f8':
        return PhysicalKeyboardKey.f8;
      case 'f9':
        return PhysicalKeyboardKey.f9;
      case 'f10':
        return PhysicalKeyboardKey.f10;
      case 'f11':
        return PhysicalKeyboardKey.f11;
      case 'f12':
        return PhysicalKeyboardKey.f12;
      case 'space':
        return PhysicalKeyboardKey.space;
      case 'enter':
        return PhysicalKeyboardKey.enter;
      case 'tab':
        return PhysicalKeyboardKey.tab;
      case 'escape':
      case 'esc':
        return PhysicalKeyboardKey.escape;
      case 'backspace':
        return PhysicalKeyboardKey.backspace;
      case 'delete':
      case 'del':
        return PhysicalKeyboardKey.delete;
      case 'home':
        return PhysicalKeyboardKey.home;
      case 'end':
        return PhysicalKeyboardKey.end;
      case 'pageup':
        return PhysicalKeyboardKey.pageUp;
      case 'pagedown':
        return PhysicalKeyboardKey.pageDown;
      case 'arrowup':
      case 'up':
        return PhysicalKeyboardKey.arrowUp;
      case 'arrowdown':
      case 'down':
        return PhysicalKeyboardKey.arrowDown;
      case 'arrowleft':
      case 'left':
        return PhysicalKeyboardKey.arrowLeft;
      case 'arrowright':
      case 'right':
        return PhysicalKeyboardKey.arrowRight;
      case '[':
      case 'bracketleft':
        return PhysicalKeyboardKey.bracketLeft;
      case ']':
      case 'bracketright':
        return PhysicalKeyboardKey.bracketRight;
      case ';':
      case 'semicolon':
        return PhysicalKeyboardKey.semicolon;
      case '\'':
      case 'quote':
        return PhysicalKeyboardKey.quote;
      case ',':
      case 'comma':
        return PhysicalKeyboardKey.comma;
      case '.':
      case 'period':
        return PhysicalKeyboardKey.period;
      case '/':
      case 'slash':
        return PhysicalKeyboardKey.slash;
      case '\\':
      case 'backslash':
        return PhysicalKeyboardKey.backslash;
      case '`':
      case 'backquote':
        return PhysicalKeyboardKey.backquote;
      case '-':
      case 'minus':
        return PhysicalKeyboardKey.minus;
      case '=':
      case 'equal':
        return PhysicalKeyboardKey.equal;
      default:
        return null;
    }
  }
}
