import 'package:characters/characters.dart';

final List<RegExp> kWorkshopTitlePatterns = [
  RegExp(r'^\s*Steam\s+Workshop\s*::\s*(.+)\s*$', caseSensitive: false),
  RegExp(r'^\s*스팀\s*창작마당\s*::\s*(.+)\s*$'),
];

String? extractWorkshopModName(String? pageTitle) {
  if (pageTitle == null || pageTitle.isEmpty) return null;
  for (final rx in kWorkshopTitlePatterns) {
    final m = rx.firstMatch(pageTitle);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.isNotEmpty) return name;
    }
  }
  return null;
}


final RegExp kAllowedInitial = RegExp(
  r'[0-9A-Za-z'
  r'\u00C0-\u02AF' r'\u0370-\u03FF' r'\u0400-\u04FF' r'\u0530-\u058F'
  r'\u0590-\u05FF' r'\u0600-\u06FF' r'\u0750-\u077F' r'\u08A0-\u08FF'
  r'\u0900-\u097F' r'\u0980-\u09FF' r'\u0A00-\u0A7F' r'\u0A80-\u0AFF'
  r'\u0B00-\u0B7F' r'\u0B80-\u0BFF' r'\u0C00-\u0C7F' r'\u0C80-\u0CFF'
  r'\u0D00-\u0D7F' r'\u0D80-\u0DFF' r'\u0E00-\u0E7F' r'\u0E80-\u0EFF'
  r'\u0F00-\u0FFF' r'\u1000-\u109F' r'\u10A0-\u10FF' r'\u1200-\u137F'
  r'\u3040-\u309F' r'\u30A0-\u30FF' r'\u31F0-\u31FF' r'\u3400-\u4DBF'
  r'\u4E00-\u9FFF' r'\uAC00-\uD7AF' r'\u1100-\u11FF' r'\u3130-\u318F'
  r']',
);

String extractInitialAny(String input, {String fallback = 'M'}) {
  for (final grapheme in input.trimLeft().characters) {
    for (final cp in grapheme.runes) {
      final ch = String.fromCharCode(cp);
      if (kAllowedInitial.hasMatch(ch)) return ch.toUpperCase();
    }
  }
  return fallback;
}

// 한글 포함 여부
final RegExp _rxKo = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]');
// 라틴 알파벳(단순)
final RegExp _rxLatin = RegExp(r'[A-Za-z]');

bool looksKoreanTitle(String? s) => s != null && _rxKo.hasMatch(s);
bool looksEnglishTitle(String? s) => s != null && _rxLatin.hasMatch(s) && !_rxKo.hasMatch(s);

/// 로케일에 비해 제목/이미지가 부실하면 refetch가 필요하다는 판단.
/// - 이미지가 없거나 파일이 없으면 true
/// - ko 로케일인데 영문 제목이면 true
/// - ko가 아니고(≈en) 한글 제목이면 true
bool shouldRefetchForLocale({
  required String langCode,
  required String? title,
  required String? imagePath,
  bool imageFileExists = false,
}) {
  if (imagePath == null || imagePath.isEmpty || !imageFileExists) return true;
  final wantKo = langCode.toLowerCase().startsWith('ko');
  if (wantKo && looksEnglishTitle(title)) return true;
  if (!wantKo && looksKoreanTitle(title)) return true;
  return false;
}
