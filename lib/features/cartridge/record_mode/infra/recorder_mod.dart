import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Recorder mod script/template provider for Record Mode.
///
/// Moved from core/utils to feature-scoped infra layer to better reflect
/// ownership and dependencies (dotenv, http).
class RecorderMod {
  static const modMetadata = """
<metadata>
	<name>CartridgeRecorder</name>
	<directory>cartridge-recorder</directory>
	<description/>
	<version>1.0</version>
	<visibility/>
</metadata>
""";

  /// Fetches the main.lua template from configured URL and injects placeholders
  /// with the provided daily/weekly values.
  static Future<String> getModMain(
    String dailySeed,
    String dailyBoss,
    int dailyCharacter,
    String weeklySeed,
    String weeklyBoss,
    int weeklyCharacter,
  ) async {
    final url = dotenv.env['RECORDER_MOD_URL'] ?? '';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final modMain = response.body;

    return modMain
        .replaceFirst('%DAILY_SEED%', dailySeed)
        .replaceFirst('%DAILY_BOSS%', dailyBoss)
        .replaceFirst('%DAILY_CHARACTER%', dailyCharacter.toString())
        .replaceFirst('%WEEKLY_SEED%', weeklySeed)
        .replaceFirst('%WEEKLY_BOSS%', weeklyBoss)
        .replaceFirst('%WEEKLY_CHARACTER%', weeklyCharacter.toString());
  }
}
