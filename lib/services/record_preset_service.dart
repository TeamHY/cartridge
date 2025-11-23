import 'dart:convert';

import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RecordPresetService {
  static Future<Preset> getRecordPreset() async {
    final response =
        await http.get(Uri.parse(dotenv.env['RECORD_PRESET_URL'] ?? ''));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final json = jsonDecode(response.body).cast<Map<String, dynamic>>();
    final mods = List<Mod>.from(json.map((e) => Mod.fromJson(e)));

    return Preset(name: 'record', mods: mods);
  }

  static Future<bool> validateRecordPreset({
    required List<Mod> currentMods,
    required Preset recordPreset,
  }) async {
    final currentModNames = currentMods
        .where((mod) => !mod.isDisable)
        .map((mod) => mod.name)
        .toSet();

    final presetModNames = recordPreset.mods
        .where((mod) => !mod.isDisable)
        .map((mod) => mod.name)
        .toSet();

    return presetModNames.containsAll(currentModNames);
  }
}
