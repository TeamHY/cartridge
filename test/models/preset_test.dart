import 'package:cartridge/models/game_launch_mode.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presets saved before launch modes default to vanilla', () {
    final preset = Preset.fromJson({'name': 'old', 'mods': []});

    expect(preset.launchMode, GameLaunchMode.vanilla);
  });

  test('launch mode survives a save and load', () {
    final saved = Preset(
      name: 'rgon',
      mods: [],
      gameConfigId: 'stream',
      launchMode: GameLaunchMode.repentogon,
    ).toJson();
    final loaded = Preset.fromJson(saved);

    expect(loaded.launchMode, GameLaunchMode.repentogon);
    expect(loaded.gameConfigId, 'stream');
  });
}
