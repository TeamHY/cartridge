import 'package:flutter/widgets.dart';
import 'package:cartridge/l10n/app_localizations.dart';

const List<String> _kCharacterImageFiles = [
  'Transition_Isaac.webp',
  'Transition_Magdalene.webp',
  'Transition_Cain.webp',
  'Transition_Judas.webp',
  'Transition_BlueBaby.webp',
  'Transition_Eve.webp',
  'Transition_Samson.webp',
  'Transition_Azazel.webp',
  'Transition_Lazarus.webp',
  'Transition_Eden.webp',
  'Transition_Lost.webp',
  'Transition_Lazarus_Risen.webp',
  'Transition_Judas_Dark.webp',
  'Transition_Lilith.webp',
  'Transition_Keeper.webp',
  'Transition_Apollyon.webp',
  'Transition_Forgotten.webp',
  'Transition_Forgotten.webp',
  'Transition_Bethany.webp',
  'Transition_JacobEsau.webp',
  'Transition_JacobEsau.webp',

  'Transition_Isaac_Tainted.webp',
  'Transition_Magdalene_Tainted.webp',
  'Transition_Cain_Tainted.webp',
  'Transition_Judas_Tainted.webp',
  'Transition_BlueBaby_Tainted.webp',
  'Transition_Eve_Tainted.webp',
  'Transition_Samson_Tainted.webp',
  'Transition_Azazel_Tainted.webp',
  'Transition_Lazarus_Tainted.webp',
  'Transition_Tainted_Eden.gif',
  'Transition_Lost_Tainted.webp',
  'Transition_Lilith_Tainted.webp',
  'Transition_Keeper_Tainted.webp',
  'Transition_Apollyon_Tainted.webp',
  'Transition_Forgotten_Tainted.webp',
  'Transition_Bethany_Tainted.webp',
  'Transition_Jacob_Tainted.webp',
  'Transition_Lazarus_T_Dead.webp',
  'Transition_Jacob_T_DarkEsau.webp',
  'Transition_Forgotten_Tainted.webp',
];

/// Enum of Isaac characters in the exact DB index order.
/// Developers should use this enum instead of raw integers whenever possible.
enum IsaacCharacter {
  isaac,
  magdalene,
  cain,
  judas,
  blueBaby,
  eve,
  samson,
  azazel,
  lazarus,
  eden,
  theLost,
  lazarus2,
  blackJudas,
  lilith,
  keeper,
  apollyon,
  theForgotten,
  theSoul,
  bethany,
  jacob,
  esau,
  tIsaac,
  tMagdalene,
  tCain,
  tJudas,
  tBlueBaby,
  tEve,
  tSamson,
  tAzazel,
  tLazarus,
  tEden,
  tTheLost,
  tLilith,
  tKeeper,
  tApollyon,
  tTheForgotten,
  tBethany,
  tJacobAndEsau,
  tLazarus2,
  tJacob2,
  tTheSoul,
}

extension IsaacCharacterX on IsaacCharacter {

  static void _debugAssertLength() {
    assert(
    _kCharacterImageFiles.length == IsaacCharacter.values.length,
    'Character image list (${_kCharacterImageFiles.length}) '
        'must match enum length (${IsaacCharacter.values.length}).',
    );
  }

  String get imageFile {
    _debugAssertLength();
    return _kCharacterImageFiles[index]; // enum의 기본 index 사용
  }

  String get imageAsset => 'assets/images/characters/$imageFile';

  String localizedName(AppLocalizations loc) {
    switch (this) {
      case IsaacCharacter.isaac:          return loc.character_isaac;
      case IsaacCharacter.magdalene:      return loc.character_magdalene;
      case IsaacCharacter.cain:           return loc.character_cain;
      case IsaacCharacter.judas:          return loc.character_judas;
      case IsaacCharacter.blueBaby:       return loc.character_blue_baby;
      case IsaacCharacter.eve:            return loc.character_eve;
      case IsaacCharacter.samson:         return loc.character_samson;
      case IsaacCharacter.azazel:         return loc.character_azazel;
      case IsaacCharacter.lazarus:        return loc.character_lazarus;
      case IsaacCharacter.eden:           return loc.character_eden;
      case IsaacCharacter.theLost:        return loc.character_the_lost;
      case IsaacCharacter.lazarus2:       return loc.character_lazarus2;
      case IsaacCharacter.blackJudas:     return loc.character_black_judas;
      case IsaacCharacter.lilith:         return loc.character_lilith;
      case IsaacCharacter.keeper:         return loc.character_keeper;
      case IsaacCharacter.apollyon:       return loc.character_apollyon;
      case IsaacCharacter.theForgotten:   return loc.character_the_forgotten;
      case IsaacCharacter.theSoul:        return loc.character_the_soul;
      case IsaacCharacter.bethany:        return loc.character_bethany;
      case IsaacCharacter.jacob:          return loc.character_jacob;
      case IsaacCharacter.esau:           return loc.character_esau;
      case IsaacCharacter.tIsaac:         return loc.character_tainted_isaac;
      case IsaacCharacter.tMagdalene:     return loc.character_tainted_magdalene;
      case IsaacCharacter.tCain:          return loc.character_tainted_cain;
      case IsaacCharacter.tJudas:         return loc.character_tainted_judas;
      case IsaacCharacter.tBlueBaby:      return loc.character_tainted_blue_baby;
      case IsaacCharacter.tEve:           return loc.character_tainted_eve;
      case IsaacCharacter.tSamson:        return loc.character_tainted_samson;
      case IsaacCharacter.tAzazel:        return loc.character_tainted_azazel;
      case IsaacCharacter.tLazarus:       return loc.character_tainted_lazarus;
      case IsaacCharacter.tEden:          return loc.character_tainted_eden;
      case IsaacCharacter.tTheLost:       return loc.character_tainted_the_lost;
      case IsaacCharacter.tLilith:        return loc.character_tainted_lilith;
      case IsaacCharacter.tKeeper:        return loc.character_tainted_keeper;
      case IsaacCharacter.tApollyon:      return loc.character_tainted_apollyon;
      case IsaacCharacter.tTheForgotten:  return loc.character_tainted_the_forgotten;
      case IsaacCharacter.tBethany:       return loc.character_tainted_bethany;
      case IsaacCharacter.tJacobAndEsau:  return loc.character_tainted_jacob_and_esau;
      case IsaacCharacter.tLazarus2:      return loc.character_tainted_lazarus2;
      case IsaacCharacter.tJacob2:        return loc.character_tainted_jacob2;
      case IsaacCharacter.tTheSoul:       return loc.character_tainted_the_soul;
    }
  }

  /// Factory: build from DB integer index.
  static IsaacCharacter? fromIndex(int i) {
    if (i < 0 || i >= IsaacCharacter.values.length) return null;
    return IsaacCharacter.values[i];
  }
}

/// Simple model used by UI widgets where a combined object is convenient.
class GameCharacter {
  final int id;
  const GameCharacter(this.id);

  IsaacCharacter get _safeEnum =>
      IsaacCharacterX.fromIndex(id) ?? IsaacCharacter.isaac;

  String get imageAsset => _safeEnum.imageAsset;
  String localizedName(AppLocalizations loc) => _safeEnum.localizedName(loc);
  LocalizedGameCharacter localized(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return LocalizedGameCharacter(
      id: _safeEnum.index,
      name: _safeEnum.localizedName(loc),
      imageAsset: _safeEnum.imageAsset,
    );
  }
}

@immutable
class LocalizedGameCharacter {
  final int id;
  final String name;
  final String imageAsset;
  const LocalizedGameCharacter({
    required this.id,
    required this.name,
    required this.imageAsset,
  });
}