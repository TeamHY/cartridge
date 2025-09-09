import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';

abstract final class IsaacSaveFileNamer {
  static String fileName(IsaacEdition e, int slot) {
    if (slot < 1 || slot > 3) throw ArgumentError('slot must be 1..3');
    switch (e) {
      case IsaacEdition.rebirth:        return 'persistentgamedata$slot.dat';
      case IsaacEdition.afterbirth:     return 'ab_persistentgamedata$slot.dat';
      case IsaacEdition.afterbirthPlus: return 'abp_persistentgamedata$slot.dat';
      case IsaacEdition.repentance:     return 'rep_persistentgamedata$slot.dat';
      case IsaacEdition.repentancePlus: return 'rep+persistentgamedata$slot.dat';
    }
  }
}
