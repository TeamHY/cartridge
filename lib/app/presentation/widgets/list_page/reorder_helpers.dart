// lib/app/presentation/widgets/reorder/reorder_helpers.dart
/// 현재 목록(items)과 기존 workingOrder(ids)를 합쳐
List<String> mergeWorkingOrder<T>(
    List<String> workingIds,
    List<T> items,
    String Function(T) idOf,
    ) {
  final curIds = items.map(idOf).toList(growable: false);
  return <String>[
    ...workingIds.where(curIds.contains),
    ...curIds.where((id) => !workingIds.contains(id)),
  ];
}

/// base 리스트에 working order를 적용(없으면 base 그대로)
List<T> applyWorkingOrder<T>(
    List<T> base,
    List<String> order,
    String Function(T) idOf,
    ) {
  if (order.isEmpty) return base;
  final map = {for (final v in base) idOf(v): v};
  final out = <T>[];
  for (final id in order) {
    final v = map.remove(id);
    if (v != null) out.add(v);
  }
  if (map.isNotEmpty) out.addAll(map.values);
  return out;
}