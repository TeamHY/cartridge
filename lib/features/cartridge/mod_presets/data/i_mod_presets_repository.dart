import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';

abstract class IModPresetsRepository {
  Future<List<ModPreset>> listAll();
  Future<ModPreset?> findById(String id);
  Future<void> upsert(ModPreset preset);
  Future<void> removeById(String id);
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true});
  Future<void> upsertEntry(String presetId, ModEntry entry);
  Future<void> deleteEntry(String presetId, String modKey);
  Future<void> updateEntryState(
      String presetId,
      String modKey, {
        bool? enabled,
        bool? favorite,
      });
}
