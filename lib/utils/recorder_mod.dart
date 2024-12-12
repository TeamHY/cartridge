import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  static Future<String> getModMain(String seed, String boss) async {
    final response =
        await http.get(Uri.parse(dotenv.env['RECORDER_MOD_URL'] ?? ''));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final modMain = response.body;

    return modMain.replaceFirst('%SEED%', seed).replaceFirst('%BOSS%', boss);
  }
}
