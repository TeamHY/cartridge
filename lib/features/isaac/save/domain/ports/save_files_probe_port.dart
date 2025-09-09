import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

abstract interface class SaveFilesProbePort {
  Future<List<int>> listExistingSlots(SteamAccountProfile acc, IsaacEdition e);
}
