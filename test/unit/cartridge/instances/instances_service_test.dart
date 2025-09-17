// test/instances/instances_service_test.dart
import 'dart:io';
import 'package:cartridge/core/infra/file_io.dart' show setAppSupportDirProvider;
import 'package:path/path.dart' as p;

import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_environment_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

void main() {
  group('InstancesService', () {
    late _MemRepo repo;
    late _StubModPresets modPresets;
    late _StubOptionPresets optionPresets;
    late InstancesService svc;

    late Directory tmpAppSupport;
    setUp(() async {
      tmpAppSupport = await Directory.systemTemp.createTemp('cartridge_appsupport_');
      setAppSupportDirProvider(() async => tmpAppSupport);

      repo = _MemRepo();
      modPresets = _StubModPresets();
      optionPresets = _StubOptionPresets();

      // 라벨 표시용 프리셋 레지스트리
      modPresets.registry = {
        'p1': ModPreset(id: 'p1', name: 'Preset One', entries: const []),
        'p2': ModPreset(id: 'p2', name: 'Preset Two', entries: const []),
      };

      svc = InstancesService(
        repo: repo,
        envService: _NoEnv(),
        optionPresetsService: optionPresets,
        modPresetsService: modPresets,
        // computeModViewsUseCase: 기본 구현 사용(테스트는 카운트에 의존하지 않음)
      );
    });

    tearDown(() async {
      try {
        if (await tmpAppSupport.exists()) {
          await tmpAppSupport.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('listAllViews(): pos ASC 순서 + applied 라벨 구성', () async {
      await repo.upsert(_mkInstance('a', name: 'Alpha', applied: const ['p1']));
      await repo.upsert(_mkInstance('b', name: 'Beta',  applied: const ['p2', 'ghost']));
      await repo.upsert(_mkInstance('c', name: 'Gamma', applied: const []));

      final views = await svc.listAllViews(installedOverride: const {});

      expect(views.map((e) => e.id).toList(), ['a', 'b', 'c']);
      expect(views[0].appliedPresets.map((e) => e.presetName).toList(), ['Preset One']);
      // unknown preset id → id가 라벨로 사용됨
      expect(views[1].appliedPresets.map((e) => e.presetName).toList(), ['Preset Two', 'ghost']);
    });

    test('getViewById(): 존재 시 View, 없으면 null', () async {
      await repo.upsert(_mkInstance('x', name: 'X', applied: const ['p1']));

      final hit = await svc.getViewById('x', installedOverride: const {});
      expect(hit, isNotNull);
      expect(hit!.id, 'x');

      final miss = await svc.getViewById('ghost', installedOverride: const {});
      expect(miss, isNull);
    });

    test('create(): SeedMode.allOff → overrides 비어있고 기본 normalize 적용', () async {
      final res = await svc.create(
        name: ' New ',
        seedMode: SeedMode.allOff,
        appliedPresets: [AppliedPresetRef(presetId: 'p1'), AppliedPresetRef(presetId: 'p1')],
        installedOverride: const {},
      );
      res.map(
        ok: (r) {
          final inst = r.data!;
          expect(inst.name, 'New'); // trim + 기본 이름 유지
          expect(inst.overrides, isEmpty);
          // dedup(순서 보존)
          expect(inst.appliedPresets.map((e) => e.presetId).toList(), ['p1']);
        },
        invalid: (_) => fail('expected ok'),
        notFound: (_) => fail('expected ok'),
        conflict: (_) => fail('expected ok'),
        failure: (_) => fail('expected ok'),
      );
    });

    test('rename(): notFound / 동일 이름(noop) / 다른 이름(ok)', () async {
      final id = (await svc.create(name: 'Alpha', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final nf = await svc.rename('ghost', 'Z');
      nf.maybeMap(notFound: (_) => expect(true, isTrue), orElse: () => fail('expected notFound'));

      final noop = await svc.rename(id, 'Alpha');
      noop.maybeMap(ok: (r) => expect(r.code, 'instance.rename.noop'), orElse: () => fail('expected ok'));

      final ok = await svc.rename(id, 'NewName');
      ok.maybeMap(ok: (r) => expect(r.data!.name, 'NewName'), orElse: () => fail('expected ok'));
    });

    test('delete(): notFound / ok', () async {
      final id = (await svc.create(name: 'A', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final nf = await svc.delete('ghost');
      nf.maybeMap(notFound: (_) => expect(true, isTrue), orElse: () => fail('expected notFound'));

      final ok = await svc.delete(id);
      ok.maybeMap(ok: (_) => expect(repo.items.any((e) => e.id == id), isFalse), orElse: () => fail('expected ok'));
    });

    test('clone(): notFound / 정상(새 id + suffix)', () async {
      final id = (await svc.create(name: 'Base', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final nf = await svc.clone(sourceId: 'ghost', duplicateSuffix: '(copy)');
      nf.maybeMap(notFound: (_) => expect(true, isTrue), orElse: () => fail('expected notFound'));

      final ok = await svc.clone(sourceId: id, duplicateSuffix: '(copy)');
      ok.maybeMap(
        ok: (r) {
          expect(r.data!.id, isNot(id));
          expect(r.data!.name, 'Base (copy)');
        },
        orElse: () => fail('expected ok'),
      );
    });

    test('이미지 설정/해제: userFile→sprite→userFile→clear (복사·삭제 동작 검증)', () async {
      final id = (await svc.create(name: 'I', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      // 1) 소스 파일 준비
      final src1 = File(p.join(tmpAppSupport.path, 'src1.png'));
      await src1.writeAsBytes([1, 2, 3], flush: true);

      // 2) userFile 설정 → 앱 관리 경로로 복사되었는지
      final u1 = await svc.setImageToUserFile(instanceId: id, path: src1.path);
      u1.maybeMap(
        ok: (r) {
          final saved = r.data!;
          final savedPath = saved.image!.map(
            userFile: (f) => f.path,
            sprite: (_) => 'SPRITE',
          );
          final expected = p.join(tmpAppSupport.path, 'instance_images', '$id.png');
          expect(savedPath, expected);
          expect(File(expected).existsSync(), isTrue);
        },
        orElse: () => fail('expected ok'),
      );

      // 3) sprite로 변경 → 이전 관리 파일 삭제
      final s = await svc.setImageToSprite(instanceId: id, index: 0);
      s.maybeMap(
        ok: (r) {
          final expected = p.join(tmpAppSupport.path, 'instance_images', '$id.png');
          expect(File(expected).existsSync(), isFalse, reason: 'sprite로 바꾸면 기존 userFile 삭제');
          expect(r.data!.image!.map(sprite: (_) => true, userFile: (_) => false), isTrue);
        },
        orElse: () => fail('expected ok'),
      );

      // 4) 다시 userFile
      final src2 = File(p.join(tmpAppSupport.path, 'another.jpeg'));
      await src2.writeAsBytes([4, 5, 6, 7], flush: true);
      final u2 = await svc.setImageToUserFile(instanceId: id, path: src2.path);
      u2.maybeMap(
        ok: (r) {
          final expected = p.join(tmpAppSupport.path, 'instance_images', '$id.jpeg');
          expect(File(expected).existsSync(), isTrue);
          expect(r.data!.image!.map(userFile: (_) => true, sprite: (_) => false), isTrue);
        },
        orElse: () => fail('expected ok'),
      );

      // 5) clear → 관리 파일 삭제
      final c = await svc.clearImage(id);
      c.maybeMap(
        ok: (r) {
          final expected1 = p.join(tmpAppSupport.path, 'instance_images', '$id.png');
          final expected2 = p.join(tmpAppSupport.path, 'instance_images', '$id.jpeg');
          expect(File(expected1).existsSync(), isFalse);
          expect(File(expected2).existsSync(), isFalse);
          expect(r.data!.image, isNull);
        },
        orElse: () => fail('expected ok'),
      );
    });

    test('이미지 설정 실패: 존재하지 않는 소스 파일 → 실패(or invalid)', () async {
      final id = (await svc.create(name: 'I2', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final bad = await svc.setImageToUserFile(instanceId: id, path: p.join(tmpAppSupport.path, 'no_such_file.png'));
      expect(
        bad.maybeWhen(failure: (_, __, ___) => true, invalid: (_, __, ___) => true, orElse: () => false),
        isTrue,
        reason: '소스 파일이 없으면 실패/invalid 여야 한다',
      );
    });

    test('setItemState()/bulkSetItemState(): override 추가/갱신/제거', () async {
      final id = (await svc.create(name: 'E', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      // 신규 추가 (enabled=true)
      await svc.setItemState(instanceId: id, item: _mv('mod.b', 'B'), enabled: true);
      var cur = await repo.findById(id);
      expect(cur!.overrides.any((e) => e.key == 'mod.b' && e.enabled == true), isTrue);

      // 즐겨찾기만 갱신 (favorite=true → 저장)
      await svc.setItemState(instanceId: id, item: _mv('mod.a', 'A'), favorite: true);
      cur = await repo.findById(id);
      expect(cur!.overrides.singleWhere((e) => e.key == 'mod.a').favorite, isTrue);

      // enabled=false, favorite=false → "저장" 되어야 함
      await svc.setItemState(instanceId: id, item: _mv('mod.c', 'C'), enabled: false);
      cur = await repo.findById(id);
      expect(
        cur!.overrides.any((e) => e.key == 'mod.c' && e.enabled == false && e.favorite == false),
        isTrue,
        reason: 'enabled=false라도 저장되어야 한다',
      );

      // bulk: 하나는 추가 안 됨(enabled=null & favorite=false), 하나는 제거됨(기존 + enabled=null & favorite=false)
      final res = await svc.bulkSetItemState(
        instanceId: id,
        items: [
          _mv('mod.b', 'B'), // 이미 있음 → enabled=null, favorite=false → 제거 대상
          _mv('mod.x', 'X'), // 신규     → enabled=null, favorite=false → 추가 안 됨
        ],
        enabled: null,
        favorite: false,
      );
      res.maybeMap(ok: (_) => expect(true, isTrue), orElse: () => fail('expected ok'));

      cur = await repo.findById(id);
      expect(cur!.overrides.any((e) => e.key == 'mod.b'), isFalse, reason: '기존 + (null,false) → 제거');
      expect(cur.overrides.any((e) => e.key == 'mod.x'), isFalse, reason: '신규 + (null,false) → 추가 안 됨');

      // bulk: enabled=false, favorite=false → 신규라도 저장되어야 함
      final res2 = await svc.bulkSetItemState(
        instanceId: id,
        items: [_mv('mod.d', 'D')],
        enabled: false,
        favorite: false,
      );
      res2.maybeMap(ok: (_) => expect(true, isTrue), orElse: () => fail('expected ok'));

      cur = await repo.findById(id);
      expect(
        cur!.overrides.any((e) => e.key == 'mod.d' && e.enabled == false && e.favorite == false),
        isTrue,
        reason: 'bulk에서도 enabled=false면 저장되어야 한다',
      );
    });

    test('setOptionPreset(): notFound / ok', () async {
      final id = (await svc.create(name: 'O', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final nf = await svc.setOptionPreset('ghost', 'opt1');
      nf.maybeMap(notFound: (_) => expect(true, isTrue), orElse: () => fail('expected notFound'));

      final ok = await svc.setOptionPreset(id, 'opt1');
      ok.maybeMap(ok: (r) => expect(r.data!.optionPresetId, 'opt1'), orElse: () => fail('expected ok'));
    });

    test('replaceAppliedPresets(): 중복 제거 + 업데이트 시간 변경', () async {
      final id = (await svc.create(name: 'R', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final next = await svc.replaceAppliedPresets(instanceId: id, refs: [
        AppliedPresetRef(presetId: 'p1'),
        AppliedPresetRef(presetId: 'p1'),
        AppliedPresetRef(presetId: 'p2'),
      ]);
      expect(next, isNotNull);
      expect(next!.appliedPresets.map((e) => e.presetId).toList(), ['p1', 'p2']);
      expect(next.updatedAt, isNotNull);
    });

    test('deleteItem(): override 한 개 제거', () async {
      final id = (await svc.create(name: 'D', seedMode: SeedMode.allOff, installedOverride: const {}))
          .maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');
      await svc.setItemState(instanceId: id, item: _mv('k', 'K'), enabled: true);
      var cur = await repo.findById(id);
      expect(cur!.overrides.any((e) => e.key == 'k'), isTrue);

      await svc.deleteItem(instanceId: id, itemId: 'k');
      cur = await repo.findById(id);
      expect(cur!.overrides.any((e) => e.key == 'k'), isFalse);
    });

    test('removeMissingFromAllAppliedPresets(): notFound / ok(위임 호출 수 확인)', () async {
      final id = (await svc.create(
        name: 'Z', seedMode: SeedMode.allOff, appliedPresets: [AppliedPresetRef(presetId: 'p1'), AppliedPresetRef(presetId: 'p2')],
        installedOverride: const {},
      )).maybeWhen(ok: (d, _, __) => d!.id, orElse: () => '');

      final nf = await svc.removeMissingFromAllAppliedPresets(instanceId: 'ghost', installedOverride: const {});
      nf.maybeMap(notFound: (_) => expect(true, isTrue), orElse: () => fail('expected notFound'));

      final ok = await svc.removeMissingFromAllAppliedPresets(instanceId: id, installedOverride: const {});
      ok.maybeMap(ok: (_) => expect(modPresets.removeMissingCalls, ['p1', 'p2']), orElse: () => fail('expected ok'));
    });

    test('reorderInstances(): ok / invalid / failure', () async {
      await repo.upsert(_mkInstance('a', name: 'A'));
      await repo.upsert(_mkInstance('b', name: 'B'));
      await repo.upsert(_mkInstance('c', name: 'C'));

      // ok
      final r1 = await svc.reorderInstances(const ['c', 'a', 'b']);
      r1.maybeMap(ok: (_) => expect(repo.order, ['c', 'a', 'b']), orElse: () => fail('expected ok'));

      // invalid
      repo.throwArgument = true;
      final r2 = await svc.reorderInstances(const ['a', 'x', 'b']);
      r2.maybeMap(failure: (f) => expect(f.code, 'instance.reorder.invalid'), orElse: () => fail('expected failure'));

      // generic failure
      repo.throwArgument = false;
      repo.throwGeneric = true;
      final r3 = await svc.reorderInstances(const ['b', 'a', 'c']);
      r3.maybeMap(failure: (f) => expect(f.code, 'instance.reorder.failure'), orElse: () => fail('expected failure'));
    });
  });
}

// ── Helpers & Stubs ───────────────────────────────────────────────────────────
Instance _mkInstance(String id, {required String name, List<String> applied = const []}) {
  return Instance(
    id: id,
    name: name,
    optionPresetId: null,
    appliedPresets: [for (final p in applied) AppliedPresetRef(presetId: p)],
    gameMode: GameMode.normal,
    overrides: const [],
    image: null,
    sortKey: InstanceSortKey.name,
    ascending: true,
    updatedAt: null,
    lastSyncAt: null,
    group: null,
    categories: const [],
  );
}

ModView _mv(String id, String name, {bool installed = false}) => ModView(
  id: id,
  isInstalled: installed,
  explicitEnabled: false,
  effectiveEnabled: false,
  favorite: false,
  displayName: name,
  installedRef: null,
  status: ModRowStatus.ok,
  enabledByPresets: const <String>{},
  updatedAt: DateTime.now(),
);

class _MemRepo implements IInstancesRepository {
  final List<Instance> items = [];
  List<String> get order => items.map((e) => e.id).toList();
  bool throwArgument = false;
  bool throwGeneric = false;

  @override
  Future<List<Instance>> listAll() async => List.unmodifiable(items);

  @override
  Future<Instance?> findById(String id) async {
    final i = items.indexWhere((e) => e.id == id);
    return i < 0 ? null : items[i];
  }

  @override
  Future<void> upsert(Instance i) async {
    final idx = items.indexWhere((e) => e.id == i.id);
    if (idx < 0) {
      items.add(i);
    } else {
      items[idx] = i; // pos(=index) 유지
    }
  }

  @override
  Future<void> removeById(String id) async {
    items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    if (throwArgument) throw ArgumentError('bad ids');
    if (throwGeneric) throw StateError('boom');
    final map = {for (final v in items) v.id: v};
    items
      ..clear()
      ..addAll(orderedIds.map((id) => map[id]!).toList());
  }
}

class _StubModPresets extends ModPresetsService {
  _StubModPresets() : super(repository: _NoModRepo(), envService: _NoEnv());

  Map<String, ModPreset> registry = {};
  final List<String> removeMissingCalls = [];

  @override
  Future<List<ModPreset>> getRawPresetsByIds(Set<String> ids) async {
    return [for (final id in ids) if (registry[id] != null) registry[id]!];
  }

  @override
  Future<ModPresetView?> getById({required String presetId, Map<String, InstalledMod>? installedOverride, String? modsRootOverride}) async {
    final p = registry[presetId];
    if (p == null) return null;
    // 최소 필드만 채운 View
    return ModPresetView(key: p.id, name: p.name, items: const [], totalCount: 0, enabledCount: 0);
  }

  @override
  Future<Result<ModPresetView>> removeMissing({
    required String presetId,
    Map<String, InstalledMod>? installedOverride,
    String? modsRootOverride,
  }) async {
    removeMissingCalls.add(presetId);
    // 테스트에서는 data를 사용하지 않지만, 시그니처를 만족하도록 최소 View를 넣어줍니다.
    final name = registry[presetId]?.name ?? presetId;
    return Result.ok(
      data: ModPresetView(
        key: presetId,
        name: name,
        items: const [],
        totalCount: 0,
        enabledCount: 0,
      ),
      code: 'modPreset.removeMissing.ok',
    );
  }
}

class _NoModRepo implements IModPresetsRepository {
  @override
  Future<ModPreset?> findById(String id) async => null;
  @override
  Future<List<ModPreset>> listAll() async => const [];
  @override
  Future<void> removeById(String id) async {}
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {}
  @override
  Future<void> upsert(ModPreset preset) async {}
  @override
  Future<void> upsertEntry(String presetId, ModEntry entry) async {}
  @override
  Future<void> deleteEntry(String presetId, String modKey) async {}
  @override
  Future<void> updateEntryState(String presetId, String modKey, {bool? enabled, bool? favorite}) async {}
}

class _StubOptionPresets extends OptionPresetsService {
  _StubOptionPresets() : super(repo: _NoOptRepo());

  @override
  Future<OptionPresetView?> getViewById(String id) async {
    if (id == 'opt1') {
      return OptionPresetView(
        id: 'opt1',
        name: 'Option One',
        windowWidth: null,
        windowHeight: null,
        windowPosX: null,
        windowPosY: null,
        fullscreen: null,
        gamma: null,
        enableDebugConsole: null,
        pauseOnFocusLost: null,
        mouseControl: null,
        useRepentogon: null,
      );
    }
    return null;
  }
}

class _NoOptRepo implements IOptionPresetsRepository {
  @override
  Future<OptionPreset?> findById(String id) async => null;
  @override
  Future<List<OptionPreset>> listAll() async => const [];
  @override
  Future<void> removeById(String id) async {}
  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {}
  @override
  Future<void> upsert(OptionPreset preset) async {}
}

class _NoEnv implements IsaacEnvironmentService {
  @override
  Future<Map<String, InstalledMod>> getInstalledModsMap() async => const {};

  @override
  Future<String?> detectOptionsIniPathAuto({List<String> fallbackCandidates = const []}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isValidInstallDir(String? dir) {
    throw UnimplementedError();
  }

  @override
  Future<LaunchEnvironment?> resolveEnvironment({String? optionsIniPathOverride, List<String> fallbackIniCandidates = const []}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveInstallPath() {
    throw UnimplementedError();
  }

  @override
  Future<InstallPathResolution> resolveInstallPathDetailed({String? installPathOverride}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveModsRoot() {
    throw UnimplementedError();
  }

  @override
  Future<String?> resolveOptionsIniPath({String? override, List<String> fallbackCandidates = const []}) {
    throw UnimplementedError();
  }
}
