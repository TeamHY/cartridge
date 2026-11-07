import 'package:cartridge/services/repentogon_cli_service.dart';
import 'package:cartridge/services/steam_save_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _localConfig = r'''
"UserLocalConfigStore"
{
	"Software"
	{
		"Valve"
		{
			"Steam"
			{
				"apps"
				{
					"250900"
					{
						"LastPlayed"		"1762500000"
						"cloud"
						{
							"last_sync_state"		"synchronized"
						}
						"LaunchOptions"		"--luadebug --set-stage=\"1\""
					}
				}
			}
		}
	}
	"depots"
	{
		"250900"
		{
			"CDN"		"token"
		}
	}
}
''';

void main() {
  group('launchOptionsFromLocalConfig', () {
    test('reads the launch options of the app block', () {
      expect(
        launchOptionsFromLocalConfig(_localConfig, '250900'),
        '--luadebug --set-stage="1"',
      );
    });

    test('returns null when the app has no launch options', () {
      expect(launchOptionsFromLocalConfig(_localConfig, '113200'), isNull);
      expect(
        launchOptionsFromLocalConfig(
            _localConfig.replaceFirst('"LaunchOptions"', '"Other"'), '250900'),
        isNull,
      );
    });
  });

  group('launchArgsFromSteamOptions', () {
    test('keeps only options rgon-cli understands', () {
      expect(
        RepentogonCliService.launchArgsFromSteamOptions(
            '--luadebug -windowed %command% --set-stage=3 --luaheapsize 1024M'),
        ['--luadebug', '--set-stage=3', '--luaheapsize', '1024M'],
      );
    });

    test('drops a value option without its value', () {
      expect(
        RepentogonCliService.launchArgsFromSteamOptions(
            '--load-room --luadebug'),
        ['--luadebug'],
      );
      expect(RepentogonCliService.launchArgsFromSteamOptions(''), isEmpty);
    });

    test('unquotes quoted values', () {
      expect(
        RepentogonCliService.launchArgsFromSteamOptions(
            '--load-room "C:\\rooms\\my room.xml"'),
        ['--load-room', 'C:\\rooms\\my room.xml'],
      );
    });
  });
}
