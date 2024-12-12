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

  static String getCharacterName(int character) {
    switch (character) {
      case 0:
        return '아이작';
      case 1:
        return '막달레나';
      case 2:
        return '카인';
      case 3:
        return '유다';
      case 4:
        return '???';
      case 5:
        return '이브';
      case 6:
        return '삼손';
      case 7:
        return '아자젤';
      case 8:
        return '나사로';
      case 9:
        return '에덴';
      case 10:
        return '더 로스트';
      case 11:
        return '나사로2';
      case 12:
        return '블랙 유다';
      case 13:
        return '릴리트';
      case 14:
        return '키퍼';
      case 15:
        return '아폴리온';
      case 16:
        return '더 포가튼';
      case 17:
        return '더 소울';
      case 18:
        return '베다니';
      case 19:
        return '야곱';
      case 20:
        return '에사우';
      case 21:
        return '더럽혀진 아이작';
      case 22:
        return '더럽혀진 막달레나';
      case 23:
        return '더럽혀진 카인';
      case 24:
        return '더럽혀진 유다';
      case 25:
        return '더럽혀진 ???';
      case 26:
        return '더럽혀진 이브';
      case 27:
        return '더럽혀진 삼손';
      case 28:
        return '더럽혀진 아자젤';
      case 29:
        return '더럽혀진 나사로';
      case 30:
        return '더럽혀진 에덴';
      case 31:
        return '더럽혀진 더 로스트';
      case 32:
        return '더럽혀진 릴리트';
      case 33:
        return '더럽혀진 키퍼';
      case 34:
        return '더럽혀진 아폴리온';
      case 35:
        return '더럽혀진 더 포가튼';
      case 36:
        return '더럽혀진 베다니';
      case 37:
        return '더럽혀진 야곱';
      case 38:
        return '더럽혀진 나사로2';
      case 39:
        return '더럽혀진 야곱2';
      case 40:
        return '더럽혀진 더 소울';
      default:
        return '알 수 없음';
    }
  }
}
