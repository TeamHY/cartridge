import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

/// 세이브 쓰기 방식(롤백 실험용 스위치)
enum SaveWriteMode { atomicRename, inPlace }

abstract interface class EdenTokensPort {
  Future<int> read(SteamAccountProfile acc, IsaacEdition e, int slot);
  Future<void> write(
      SteamAccountProfile acc,
      IsaacEdition e,
      int slot,
      int value, {
        bool makeBackup = true,
        SaveWriteMode mode = SaveWriteMode.atomicRename,
      });
}
