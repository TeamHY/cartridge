import 'dart:convert';
import 'dart:io';

import 'package:cartridge/utils/presets_parser.dart';
import 'package:path_provider/path_provider.dart';

class PresetService {
  static Future<PresetsDataV3> loadPresets() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/presets.json');

    if (!(await file.exists())) {
      return PresetsDataV3(
        presets: [],
        gameConfigs: [],
        groups: {},
      );
    }

    return await PresetsParser.parseFromFile(file) ??
        PresetsDataV3(
          presets: [],
          gameConfigs: [],
          groups: {},
        );
  }

  static Future<void> savePresets(PresetsDataV3 data) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}/presets.json');

    await file.writeAsString(jsonEncode(data.toJson()));
  }
}
