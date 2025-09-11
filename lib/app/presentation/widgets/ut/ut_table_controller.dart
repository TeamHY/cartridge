import 'package:flutter/foundation.dart';

/// UTTable의 상태를 외부에서 제어/구독할 수 있는 컨트롤러.
/// - 정렬, 포커스, 리사이즈(px override), 검색/필터, 선택 상태를 보관
class UTTableController<T> extends ChangeNotifier {
  // ---- 정렬 ----
  String? sortColumnId;
  bool ascending;

  // ---- 선택(내부 선택을 쓰는 경우에만 사용) ----
  final Set<T> selected = <T>{};

  // ---- 리사이즈(px overrides) ----
  final Map<String, double> pxOverrides = <String, double>{};

  // ---- 포커스 ----
  int focusIndex = 0;

  // ---- 검색/필터 ----
  String query;
  final Set<String> activeFilterIds = <String>{};

  UTTableController({
    this.sortColumnId,
    this.ascending = true,
    String? initialQuery,
  }) : query = initialQuery ?? '';

  // ---------- selection ----------
  bool isSelected(T row) => selected.contains(row);
  void setSelected(T row, bool value) {
    if (value ? selected.add(row) : selected.remove(row)) {
      notifyListeners();
    }
  }

  void clearSelection() {
    if (selected.isNotEmpty) {
      selected.clear();
      notifyListeners();
    }
  }

  void selectAll(Iterable<T> rows) {
    selected
      ..clear()
      ..addAll(rows);
    notifyListeners();
  }

  // ---------- sort ----------
  void setSort(String? columnId, bool asc) {
    sortColumnId = columnId;
    ascending = asc;
    notifyListeners();
  }

  // ---------- resize ----------
  void setPxOverride(String colId, double px) {
    if (pxOverrides[colId] != px) {
      pxOverrides[colId] = px;
      notifyListeners();
    }
  }

  void clearPxOverride(String colId) {
    if (pxOverrides.remove(colId) != null) {
      notifyListeners();
    }
  }

  // ---------- focus ----------
  void setFocusIndex(int i) {
    if (focusIndex != i) {
      focusIndex = i;
      notifyListeners();
    }
  }

  // ---------- search / filter ----------
  void setQuery(String q) {
    if (query != q) {
      query = q;
      notifyListeners();
    }
  }

  void toggleFilter(String id, {bool? enable}) {
    final want = enable ?? !activeFilterIds.contains(id);
    final changed = want ? activeFilterIds.add(id) : activeFilterIds.remove(id);
    if (changed) notifyListeners();
  }

  // ---------- (옵션) 직렬화 ----------
  Map<String, dynamic> toMap() => {
    'sortColumnId': sortColumnId,
    'ascending': ascending,
    'pxOverrides': Map<String, double>.from(pxOverrides),
    'focusIndex': focusIndex,
    'query': query,
    'activeFilterIds': activeFilterIds.toList(),
  };

  void loadFromMap(Map<String, dynamic> m) {
    sortColumnId = m['sortColumnId'] as String?;
    ascending = (m['ascending'] as bool?) ?? true;
    final px = m['pxOverrides'];
    if (px is Map) {
      pxOverrides
        ..clear()
        ..addAll(px.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
    }
    focusIndex = (m['focusIndex'] as int?) ?? 0;
    query = (m['query'] as String?) ?? '';
    final filters = m['activeFilterIds'];
    activeFilterIds
      ..clear()
      ..addAll(filters is List ? filters.map((e) => e.toString()) : const <String>[]);
    notifyListeners();
  }
}

class UTTableToolbarController extends ChangeNotifier {
  bool _searchOpen;

  UTTableToolbarController({bool initialSearchOpen = false})
      : _searchOpen = initialSearchOpen;

  bool get isSearchOpen => _searchOpen;

  void openSearch() => _set(true);
  void closeSearch() => _set(false);
  void toggleSearch() => _set(!_searchOpen);

  void _set(bool v) {
    if (_searchOpen == v) return;
    _searchOpen = v;
    notifyListeners();
  }
}