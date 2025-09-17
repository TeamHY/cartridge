// test/unit/cartridge/instances/instance_pack_service_test.dart
import 'dart:convert';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/record_mode/infra/recorder_mod.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/application/install_path_result.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_environment_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('InstancePackService', () {
    late _MemInstancesRepo instRepo;
    late _MemModPresetsRepo presetRepo;
    late _StubEnv env;
    late InstancePackService svc;

    late io.Directory tmpRoot;
    late io.Directory modsRoot1; // export 시 소스 로컬 모드들이 존재하는 곳
    late io.Directory modsRoot2; // import 시 대상 루트(다수결로 선택될 부모)

    setUp(() async {
      tmpRoot = await io.Directory.systemTemp.createTemp('pack_svc_test_');
      modsRoot1 = io.Directory(p.join(tmpRoot.path, 'mods_src'))..createSync(recursive: true);
      modsRoot2 = io.Directory(p.join(tmpRoot.path, 'mods_dst'))..createSync(recursive: true);

      instRepo = _MemInstancesRepo();
      presetRepo = _MemModPresetsRepo();

      // Env: export 시에는 LocalA/LocalB 의 실제 경로를 알려주고,
      // import 시에는 modsRoot2 하위가 최빈 parent 로 선택되도록 세팅
      env = _StubEnv();

      svc = InstancePackService(
        instancesRepo: instRepo,
        modPresetsRepo: presetRepo,
        env: env,
      );
    });

    tearDown(() async {
      if (tmpRoot.existsSync()) {
        await tmpRoot.delete(recursive: true);
      }
    });

    test('exportById → zip: manifest + image + local_mods 포함 & special mod 제외', () async {
      // ── 1) 로컬 모드 폴더 준비(Export에 포함될 A/B)
      final localA = io.Directory(p.join(modsRoot1.path, 'LocalA'))..createSync(recursive: true);
      final localB = io.Directory(p.join(modsRoot1.path, 'LocalB'))..createSync(recursive: true);
      io.File(p.join(localA.path, 'a.txt')).writeAsStringSync('AAA', flush: true);
      io.File(p.join(localB.path, 'b.txt')).writeAsStringSync('BBB', flush: true);

      // Env 가 반환할 설치맵(Export에서 로컬 모드 실제 경로를 잡아냄)
      env.installed = {
        'LocalA': _mkInstalled('LocalA', p.join(modsRoot1.path, 'LocalA')),
        'LocalB': _mkInstalled('LocalB', p.join(modsRoot1.path, 'LocalB')),
        'workshop_111': _mkInstalled('workshop_111', p.join(tmpRoot.path, 'workshop/111')),
      };

      // 2) 이미지(유저 파일) 준비
      final imageSrc = io.File(p.join(tmpRoot.path, 'img.png'))..writeAsBytesSync([1, 2, 3, 4], flush: true);

      // 3) 프리셋: 하나는 Repo에 미리 존재(identical), 하나는 새로 들어올 예정
      final existingPreset = ModPreset(
        id: 'p_ident',
        name: 'Identical',
        entries: [
          ModEntry(key: 'LocalB', enabled: true, favorite: false),
          ModEntry(key: 'workshop_222', enabled: true, favorite: false),
          ModEntry(key: RecorderMod.name, enabled: true, favorite: false), // special → export 에서 제외
        ],
        sortKey: null,
        ascending: null,
        updatedAt: DateTime.now(),
        lastSyncAt: DateTime.now(),
      );
      await presetRepo.upsert(existingPreset);

      // 4) 인스턴스 모델(Export 소스)
      final instId = IdUtil.genId('inst');
      final instance = Instance(
        id: instId,
        name: 'PackMe',
        optionPresetId: null,
        appliedPresets: [
          AppliedPresetRef(presetId: 'p_ident'),
          AppliedPresetRef(presetId: 'p_new'), // manifest에 함께 담길 새 프리셋
        ],
        gameMode: GameMode.normal,
        overrides: [
          ModEntry(key: 'LocalA', enabled: true, favorite: false),
          ModEntry(key: 'workshop_111', enabled: true, favorite: false),
          ModEntry(key: RecorderMod.name, enabled: true, favorite: false), // special
        ],
        image: InstanceImage.userFile(path: imageSrc.path, fit: BoxFit.cover),
        sortKey: InstanceSortKey.name,
        ascending: true,
        updatedAt: DateTime.now(),
        lastSyncAt: null,
        group: null,
        categories: const ['A', 'B'],
      );
      await instRepo.upsert(instance);

      // 새 프리셋은 Repo에는 없지만 export 시 manifest에 함께 실릴 수 있도록
      final presetNewForManifest = ModPreset(
        id: 'p_new',
        name: 'NewPreset',
        entries: [
          ModEntry(key: 'LocalB', enabled: false, favorite: false),
          ModEntry(key: RecorderMod.name, enabled: true, favorite: false), // special
        ],
        sortKey: ModSortKey.name,
        ascending: true,
        updatedAt: DateTime.now(),
        lastSyncAt: DateTime.now(),
      );
      // Repo에는 넣지 않음(findById 로만 사용되니까 넣어줘야? → exportById는 repo에서 load하므로 필요)
      await presetRepo.upsert(presetNewForManifest);

      // 5) Export
      final outDir = io.Directory(p.join(tmpRoot.path, 'exports'))..createSync(recursive: true);
      final result = await svc.exportById(instanceId: instId, targetDir: outDir.path);
      final outZip = result.maybeWhen(ok: (path, _, __) => path!, orElse: () => null);
      expect(outZip, isNotNull);
      expect(io.File(outZip!).existsSync(), isTrue);

      // 6) Zip 검사
      final bytes = await io.File(outZip).readAsBytes();
      final z = ZipDecoder().decodeBytes(bytes);

      // manifest.json 존재
      final maniFile = z.files.firstWhere((f) => f.name == 'manifest.json');
      expect(maniFile.isFile, isTrue);

      final manifest = json.decode(utf8.decode(maniFile.content as List<int>)) as Map<String, dynamic>;
      expect((manifest['instance'] as Map)['name'], 'PackMe');

      // special mod 제외 확인 (overrides/presets 모두)
      final overrides = ((manifest['instance'] as Map)['overrides'] as List).cast<Map>();
      expect(overrides.any((e) => e['key'] == RecorderMod.name), isFalse);

      final presetsJson = (manifest['mod_presets'] as List).cast<Map>();
      for (final pm in presetsJson) {
        final es = (pm['entries'] as List).cast<Map>();
        expect(es.any((e) => e['key'] == RecorderMod.name), isFalse);
      }

      // image 파일 포함
      final imgDecl = ((manifest['instance'] as Map)['image'] as Map?) ?? const {};
      expect(imgDecl['kind'], 'userfile');
      expect(imgDecl['filename'], isNotNull); // images/instance_image.png
      // zip 내 파일 확인
      final hasImageFile = z.files.any((f) => f.isFile && f.name == imgDecl['filename']);
      expect(hasImageFile, isTrue);

      // local_mods → LocalA/LocalB 만 포함(워크샵키 제외)
      final localMods = (manifest['local_mods'] as List).cast<Map>();
      final localKeys = localMods.map((e) => e['key'] as String).toSet();
      expect(localKeys, {'LocalA', 'LocalB'});
      // 실제 파일도 zip에 들어갔는지 대충 한 개씩 확인
      final aListed = z.files.any((f) => f.isFile && f.name.startsWith('local_mods/LocalA/'));
      final bListed = z.files.any((f) => f.isFile && f.name.startsWith('local_mods/LocalB/'));
      expect(aListed, isTrue);
      expect(bListed, isTrue);
      final hasWorkshop = z.files.any((f) => f.name.startsWith('local_mods/workshop_111/'));
      expect(hasWorkshop, isFalse);
    });

    test('importPack → 프리셋 중복재사용/신규생성 + 로컬모드 복사 + 이미지 언팩', () async {
      // ── 먼저 export용 zip 하나 만든 다음, 그 zip을 import로 검증 ──

      // 준비: 소스 로컬 모드/이미지/인스턴스/프리셋
      final srcLocal = io.Directory(p.join(modsRoot1.path, 'LocalOnly'))..createSync(recursive: true);
      io.File(p.join(srcLocal.path, 'file.txt')).writeAsStringSync('hi', flush: true);

      env.installed = {
        'LocalOnly': _mkInstalled('LocalOnly', srcLocal.path),
      };

      final img = io.File(p.join(tmpRoot.path, 'x.jpeg'))..writeAsBytesSync([9, 8, 7], flush: true);

      final instId = IdUtil.genId('inst');
      final inst = Instance(
        id: instId,
        name: 'ExportMe',
        optionPresetId: null,
        appliedPresets: [AppliedPresetRef(presetId: 'p_ident')], // 동일 프리셋(Repo에 존재)
        gameMode: GameMode.normal,
        overrides: [ModEntry(key: 'LocalOnly', enabled: true, favorite: false)],
        image: InstanceImage.userFile(path: img.path, fit: BoxFit.contain),
        sortKey: null,
        ascending: null,
        updatedAt: DateTime.now(),
        lastSyncAt: null,
        group: null,
        categories: const [],
      );
      await instRepo.upsert(inst);

      final identical = ModPreset(
        id: 'p_ident',
        name: 'Same',
        entries: [ModEntry(key: 'LocalOnly', enabled: true, favorite: false)],
        sortKey: null,
        ascending: null,
        updatedAt: DateTime.now(),
        lastSyncAt: DateTime.now(),
      );
      await presetRepo.upsert(identical);

      // export
      final outDir = io.Directory(p.join(tmpRoot.path, 'out'))..createSync(recursive: true);
      final zipPath = (await svc.exportById(instanceId: instId, targetDir: outDir.path))
          .maybeWhen(ok: (p0, _, __) => p0!, orElse: () => null);
      expect(zipPath, isNotNull);

      // import 시 modsRoot2 를 최빈 parent 로 감지하도록 환경 설정
      // (두 개 이상의 설치 항목이 modsRoot2 하위를 parent 로 가지게 셋업)
      env.installed = {
        'dummy1': _mkInstalled('dummy1', p.join(modsRoot2.path, 'd1')),
        'dummy2': _mkInstalled('dummy2', p.join(modsRoot2.path, 'd2')),
      };

      final importRes = await svc.importPack(zipPath: zipPath!);
      final newId = importRes.maybeWhen(ok: (id, _, __) => id!, orElse: () => null);
      expect(newId, isNotNull);

      // 인스턴스가 repo 에 저장되었는지
      final imported = await instRepo.findById(newId!);
      expect(imported, isNotNull);
      expect(imported!.name, 'ExportMe');

      // 이미지가 zip 옆의 cartridge_images/<newId>.<ext> 로 풀렸는지
      final imgPath = imported.image?.map(
        userFile: (f) => f.path,
        sprite: (_) => 'SPRITE',
      );
      expect(imgPath is String, isTrue);
      final imgFile = io.File(imgPath as String);
      expect(imgFile.existsSync(), isTrue);
      expect(imgFile.readAsBytesSync(), [9, 8, 7]);

      // 프리셋: identical 는 재사용(신규 생성 없음), 총 개수는 여전히 1
      final allPresets = await presetRepo.listAll();
      expect(allPresets.length, 1);
      expect(allPresets.single.id, 'p_ident');

      // 로컬 모드가 modsRoot2/<key> 로 복사됐는지
      final copied = io.File(p.join(modsRoot2.path, 'LocalOnly', 'file.txt'));
      expect(copied.existsSync(), isTrue);
      expect(copied.readAsStringSync(), 'hi');
    });

    test('export 옵션: includeImage=false → 이미지 파일 미동봉 + original_path만 기록', () async {
      // 이미지/인스턴스 준비
      final img = io.File(p.join(tmpRoot.path, 'orig.png'))..writeAsBytesSync([1, 2], flush: true);
      final inst = Instance(
        id: 'i1',
        name: 'NoImage',
        optionPresetId: null,
        appliedPresets: const [],
        gameMode: GameMode.normal,
        overrides: const [],
        image: InstanceImage.userFile(path: img.path, fit: BoxFit.cover),
        sortKey: null,
        ascending: null,
        updatedAt: DateTime.now(),
        lastSyncAt: null,
        group: null,
        categories: const [],
      );
      await instRepo.upsert(inst);

      env.installed = const {}; // 로컬 모드 없음

      final out = io.Directory(p.join(tmpRoot.path, 'out2'))..createSync(recursive: true);
      final res = await svc.exportById(
        instanceId: 'i1',
        targetDir: out.path,
        options: const InstanceExportOptions(includeImage: false),
      );
      final zipPath = res.maybeWhen(ok: (p0, _, __) => p0!, orElse: () => null);
      expect(zipPath, isNotNull);

      final z = ZipDecoder().decodeBytes(io.File(zipPath!).readAsBytesSync());
      // images/* 가 없어야 함
      expect(z.files.any((f) => f.name.startsWith('images/')), isFalse);

      final mani = z.files.firstWhere((f) => f.name == 'manifest.json');
      final m = json.decode(utf8.decode(mani.content as List<int>)) as Map<String, dynamic>;
      final imgDecl = ((m['instance'] as Map)['image'] as Map?) ?? const {};
      expect(imgDecl['filename'], isNull);
      expect(imgDecl['original_path'], img.path);
    });

    test('importPack: manifest 누락/비어있으면 invalid', () async {
      final archive = Archive();
      archive.addFile(ArchiveFile('readme.txt', 5, utf8.encode('hello')));
      final data = ZipEncoder().encode(archive);

      final zipPath = p.join(tmpRoot.path, 'bad.zip');
      io.File(zipPath).writeAsBytesSync(data, flush: true);

      final res = await svc.importPack(zipPath: zipPath);
      res.maybeMap(
        invalid: (_) => expect(true, isTrue),
        orElse: () => fail('expected invalid'),
      );
    });
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Stubs / Fakes
// ───────────────────────────────────────────────────────────────────────────

class _MemInstancesRepo implements IInstancesRepository {
  final List<Instance> _items = [];

  @override
  Future<Instance?> findById(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    return i < 0 ? null : _items[i];
  }

  @override
  Future<List<Instance>> listAll() async => List.unmodifiable(_items);

  @override
  Future<void> removeById(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    // not used here
  }

  @override
  Future<void> upsert(Instance i) async {
    final idx = _items.indexWhere((e) => e.id == i.id);
    if (idx < 0) {
      _items.add(i);
    } else {
      _items[idx] = i;
    }
  }
}

class _MemModPresetsRepo implements IModPresetsRepository {
  final Map<String, ModPreset> _map = {};

  @override
  Future<ModPreset?> findById(String id) async => _map[id];

  @override
  Future<List<ModPreset>> listAll() async => _map.values.toList(growable: false);

  @override
  Future<void> removeById(String id) async {
    _map.remove(id);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {}

  @override
  Future<void> upsert(ModPreset preset) async {
    _map[preset.id] = preset;
  }

  @override
  Future<void> upsertEntry(String presetId, ModEntry entry) async {
    final cur = _map[presetId];
    if (cur == null) return;
    final next = cur.copyWith(entries: [
      ...cur.entries.where((e) => e.key != entry.key),
      entry,
    ]);
    _map[presetId] = next;
  }

  @override
  Future<void> deleteEntry(String presetId, String modKey) async {
    final cur = _map[presetId];
    if (cur == null) return;
    final next = cur.copyWith(entries: cur.entries.where((e) => e.key != modKey).toList());
    _map[presetId] = next;
  }

  @override
  Future<void> updateEntryState(String presetId, String modKey, {bool? enabled, bool? favorite}) async {
    final cur = _map[presetId];
    if (cur == null) return;
    final next = cur.copyWith(
      entries: [
        for (final e in cur.entries)
          if (e.key == modKey)
            e.copyWith(enabled: enabled ?? e.enabled, favorite: favorite ?? e.favorite)
          else
            e,
      ],
    );
    _map[presetId] = next;
  }
}

class _StubEnv implements IsaacEnvironmentService {
  Map<String, InstalledMod> installed = const {};

  @override
  Future<Map<String, InstalledMod>> getInstalledModsMap() async => installed;

  // Unused in these tests
  @override
  Future<String?> detectOptionsIniPathAuto({List<String> fallbackCandidates = const []}) => throw UnimplementedError();
  @override
  Future<bool> isValidInstallDir(String? dir) => throw UnimplementedError();
  @override
  Future<LaunchEnvironment?> resolveEnvironment({String? optionsIniPathOverride, List<String> fallbackIniCandidates = const []}) => throw UnimplementedError();
  @override
  Future<String?> resolveInstallPath() => throw UnimplementedError();
  @override
  Future<InstallPathResolution> resolveInstallPathDetailed({String? installPathOverride}) => throw UnimplementedError();
  @override
  Future<String?> resolveModsRoot() => throw UnimplementedError();
  @override
  Future<String?> resolveOptionsIniPath({String? override, List<String> fallbackCandidates = const []}) => throw UnimplementedError();
}

InstalledMod _mkInstalled(String key, String folder) {
  // folderName == key 로 맞춰줌
  return InstalledMod(
    metadata: ModMetadata(id: '', name: '', directory: '', version: '', visibility: ModVisibility.public, tags: []),
    disabled: false,
    installPath: folder,
  );
}
