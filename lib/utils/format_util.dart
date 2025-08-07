import 'package:flutter/widgets.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class FormatUtil {
  static String formatNumberWithZero(int number, int length) {
    final numberString = number.toString();
    final isNeedPadding = numberString.length < length;

    if (!isNeedPadding) {
      return numberString;
    }

    return numberString.padLeft(length - numberString.length, '0');
  }

  static String getTimeString(Duration time) {
    final hours = time.inHours.toString().padLeft(2, '0');
    final minutes = (time.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        ((time.inMilliseconds % 1000) / 10).floor().toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds.$milliseconds';
  }

  static String getDateString(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  static String getCharacterName(BuildContext context, int character) {
    final loc = AppLocalizations.of(context);
    final names = <int, String>{
      0: loc.character_isaac,
      1: loc.character_magdalene,
      2: loc.character_cain,
      3: loc.character_judas,
      4: loc.character_question_mark,
      5: loc.character_eve,
      6: loc.character_samson,
      7: loc.character_azazel,
      8: loc.character_lazarus,
      9: loc.character_eden,
      10: loc.character_the_lost,
      11: loc.character_lazarus2,
      12: loc.character_black_judas,
      13: loc.character_lilith,
      14: loc.character_keeper,
      15: loc.character_apollyon,
      16: loc.character_the_forgotten,
      17: loc.character_the_soul,
      18: loc.character_bethany,
      19: loc.character_jacob,
      20: loc.character_esau,
      21: loc.character_tainted_isaac,
      22: loc.character_tainted_magdalene,
      23: loc.character_tainted_cain,
      24: loc.character_tainted_judas,
      25: loc.character_tainted_question_mark,
      26: loc.character_tainted_eve,
      27: loc.character_tainted_samson,
      28: loc.character_tainted_azazel,
      29: loc.character_tainted_lazarus,
      30: loc.character_tainted_eden,
      31: loc.character_tainted_the_lost,
      32: loc.character_tainted_lilith,
      33: loc.character_tainted_keeper,
      34: loc.character_tainted_apollyon,
      35: loc.character_tainted_the_forgotten,
      36: loc.character_tainted_bethany,
      37: loc.character_tainted_jacob_and_esau,
      38: loc.character_tainted_lazarus2,
      39: loc.character_tainted_jacob2,
      40: loc.character_tainted_the_soul,
    };
    return names[character] ?? loc.character_unknown;
  }
}
