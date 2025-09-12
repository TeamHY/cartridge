import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';


final useRepentogonByPresetIdProvider =
Provider.family<bool, String?>((ref, presetId) {
  if (presetId == null || presetId.isEmpty) return false;
  return ref.watch(
    optionPresetByIdProvider(presetId).select((p) => p?.useRepentogon ?? false),
  );
});
