class NumberUtil {
  static String formatNumberWithZero(int number, int length) {
    final numberString = number.toString();
    final isNeedPadding = numberString.length < length;

    if (!isNeedPadding) {
      return numberString;
    }

    return numberString.padLeft(length - numberString.length, '0');
  }
}
