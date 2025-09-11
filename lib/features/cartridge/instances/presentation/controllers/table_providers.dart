import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/features/cartridge/instances/application/instance_detail_controller.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_view.dart';

final instanceTableCtrlProvider =
AutoDisposeProvider.family<UTTableController<ModView>, String>((ref, instanceId) {
  final c = UTTableController<ModView>(ascending: true);
  ref.onDispose(c.dispose);

  // ★ 잠깐 구독이 끊겨도 즉시 파기되지 않도록 안전망
  final link = ref.keepAlive();
  Timer? timer;

  ref.onCancel(() {
    // 15초 안에 다시 구독되면 파기 취소
    timer = Timer(const Duration(seconds: 15), () {
      link.close(); // 진짜 해제
    });
  });

  ref.onResume(() {
    timer?.cancel();
    timer = null;
  });

  return c;
});

final modsByPresetMapProvider =
AutoDisposeProvider.family<Map<String, Set<String>>, String>((ref, instanceId) {
  final app = ref.watch(instanceDetailControllerProvider(instanceId));
  return app.maybeWhen(
    data: (view) {
      final map = <String, Set<String>>{};
      for (final r in view.items) {
        final presetIds = r.enabledByPresets;
        for (final pid in presetIds) {
          (map[pid] ??= <String>{}).add(r.id);
        }
      }
      return map;
    },
    orElse: () => const <String, Set<String>>{},
  );
});

final presetQuickFiltersProvider =
AutoDisposeProvider.family<List<UTQuickFilter<ModView>>, String>((ref, instanceId) {
  // pid -> Set<modId>
  final map = ref.watch(modsByPresetMapProvider(instanceId));
  // InstanceView에서 preset 라벨 맵 구성 (pid -> name)
  final app = ref.watch(instanceDetailControllerProvider(instanceId));

  final id2name = <String, String>{};
  app.whenData((view) {
    for (final p in view.appliedPresets) {
      id2name[p.presetId] = p.presetName;
    }
  });

  // 칩 표시 순서: appliedPresets 순서를 우선, 누락 pid는 맨 뒤에 추가
  final orderedIds = <String>[];
  if (id2name.isNotEmpty) {
    orderedIds.addAll(id2name.keys.where((pid) => map.containsKey(pid)));
  }
  for (final pid in map.keys) {
    if (!orderedIds.contains(pid)) orderedIds.add(pid);
  }

  return [
    for (final pid in orderedIds)
      UTQuickFilter<ModView>(
        id: 'mp_$pid',
        label: id2name[pid] ?? pid,
        test: (row) => map[pid]?.contains(row.id) ?? false,
      ),
  ];
});