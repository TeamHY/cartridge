/// ACF에서 `"Name" { ... }` 블록의 본문만 추출
String acfExtractBlock(String txt, String name) {
  final open = RegExp('"$name"\\s*\\{', multiLine: true).firstMatch(txt);
  if (open == null) return '';
  final start = open.end;
  var depth = 1;
  for (var i = start; i < txt.length; i++) {
    final ch = txt[i];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return txt.substring(start, i);
    }
  }
  return '';
}

/// 블록 본문에서 `"12345" {` 같은 **숫자 키**를 모두 수집
Set<int> acfExtractNumericKeys(String? block) {
  if (block == null || block.isEmpty) return <int>{};
  final rx = RegExp(r'"\s*(\d+)\s*"\s*\{', multiLine: true);
  final ids = <int>{};
  for (final m in rx.allMatches(block)) {
    final id = int.tryParse(m.group(1)!);
    if (id != null) ids.add(id);
  }
  return ids;
}
