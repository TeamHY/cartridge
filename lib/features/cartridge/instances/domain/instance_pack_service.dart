import 'dart:convert';
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:cartridge/core/validation.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:cartridge/core/infra/file_io.dart' as fio;

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/cartridge/record_mode/infra/recorder_mod.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/application/isaac_environment_service.dart';

/// Export / Import 할때 제외할 모드 목록
final kCartridgeSpecialModKeys = <String>{
  RecorderMod.name,
};

bool _isWorkshopKey(String key) => RegExp(r'_(\d+)$').hasMatch(key);
bool _isLocalKey(String key) => !_isWorkshopKey(key);
bool _isSpecialKey(String key) => kCartridgeSpecialModKeys.contains(key);

class InstanceExportOptions {
  final bool includeLocalMods;
  final bool includeImage;
  const InstanceExportOptions({
    this.includeLocalMods = true,
    this.includeImage = true,
  });
}

class InstanceImportOptions {
  /// 동일한 이름의 로컬 모드 폴더가 이미 있으면 건너뜀
  final bool skipExistingLocalMods;
  const InstanceImportOptions({
    this.skipExistingLocalMods = true,
  });
}

class InstancePackService {
  final IInstancesRepository instancesRepo;
  final IModPresetsRepository modPresetsRepo;
  final IsaacEnvironmentService env;

  InstancePackService({
    required this.instancesRepo,
    required this.modPresetsRepo,
    required this.env,
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Export (View로 시작하지만 DB 원본을 재조회)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<Result<String>> exportFromView({
    required InstanceView view,
    required String targetDir,
    InstanceExportOptions options = const InstanceExportOptions(),
    String? nameHint,
  }) async {
    return exportById(
      instanceId: view.id,
      targetDir: targetDir,
      options: options,
      nameHint: nameHint,
    );
  }

  Future<Result<String>> exportById({
    required String instanceId,
    required String targetDir,
    InstanceExportOptions options = const InstanceExportOptions(),
    String? nameHint,
  }) async {
    // 1) 모델 재조회
    final inst = await instancesRepo.findById(instanceId);
    if (inst == null) {
      return const Result.notFound(code: 'instance.export.notFound');
    }

    // 2) 프리셋 원본 로드
    final presetIds = inst.appliedPresetIds;
    final presets = <ModPreset>[];
    for (final id in presetIds) {
      final p = await modPresetsRepo.findById(id);
      if (p != null) presets.add(p);
    }

    // 3) 특수 모드 제외
    List<ModEntry> filterSpecial(Iterable<ModEntry> src) =>
        src.where((e) => !_isSpecialKey(e.key)).toList(growable: false);

    final filteredInst = inst.copyWith(overrides: filterSpecial(inst.overrides));
    final filteredPresets = [
      for (final p in presets) p.copyWith(entries: filterSpecial(p.entries)),
    ];

    // 4) 로컬 모드 후보 수집
    final localKeys = <String>{
      for (final e in filteredInst.overrides) if (_isLocalKey(e.key)) e.key,
      for (final p in filteredPresets)
        for (final e in p.entries)
          if (_isLocalKey(e.key)) e.key,
    };

    // 5) 설치 맵 (로컬 모드 실제 경로 확보용)
    final installed = await env.getInstalledModsMap();

    // 6) manifest 조립
    final manifest = _buildManifest(
      instance: filteredInst,
      presets: filteredPresets,
      includeImage: options.includeImage,
      localKeys: options.includeLocalMods ? localKeys : const <String>{},
    );

    // 7) zip 작성
    final zipPath = await _writeZip(
      targetDir: targetDir,
      nameHint: (nameHint?.trim().isNotEmpty ?? false) ? nameHint!.trim() : filteredInst.name,
      manifest: manifest,
      image: options.includeImage ? filteredInst.image : null,
      localKeys: options.includeLocalMods ? localKeys : const <String>{},
      installed: installed,
    );

    return Result.ok(data: zipPath, code: 'instance.export.ok');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Import
  // ─────────────────────────────────────────────────────────────────────────────
  Future<Result<String>> importPack({
    required String zipPath,
    InstanceImportOptions options = const InstanceImportOptions(),
  }) async {
    final bytes = await io.File(zipPath).readAsBytes();
    final z = ZipDecoder().decodeBytes(bytes);

    final maniFile = z.files.firstWhere(
          (f) => f.isFile && f.name == 'manifest.json',
      orElse: () => ArchiveFile('missing', 0, const <int>[]),
    );
    if (!maniFile.isFile || (maniFile.content as List).isEmpty) {
      return Result.invalid(code: 'instance.import.badManifest', violations: [const Violation("instance.import.empty")]);
    }

    final manifest = json.decode(utf8.decode(maniFile.content as List<int>)) as Map<String, dynamic>;
    final presetsJson = ((manifest['mod_presets'] as List?) ?? const []).cast<Map>();
    final instanceJson = (manifest['instance'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final localModsJson = ((manifest['local_mods'] as List?) ?? const []).cast<Map>();

    // 1) 프리셋 중복 제거(동일성 판정 → 기존 재사용, 없으면 생성)
    final existing = await modPresetsRepo.listAll();
    final sigToExistingId = <String, String>{
      for (final p in existing) _sigPresetModel(p): p.id,
    };

    final oldToNewPresetId = <String, String>{};
    for (final m in presetsJson) {
      final sig = _sigPresetFromManifest(m);
      final oldId = (m['id'] as String?) ?? '';

      if (sigToExistingId.containsKey(sig)) {
        oldToNewPresetId[oldId] = sigToExistingId[sig]!;
      } else {
        final newId = IdUtil.genId('mp');
        final model = _toPresetModelWithId(newId, m);
        await modPresetsRepo.upsert(model);
        oldToNewPresetId[oldId] = newId;
        sigToExistingId[sig] = newId;
      }
    }

    // 2) 로컬 모드 폴더 복사
    final modsRoot = await _detectModsRoot();
    if (modsRoot != null) {
      for (final lm in localModsJson) {
        final rel = (lm['path'] as String?) ?? '';
        final key = (lm['key'] as String?) ?? '';
        if (rel.isEmpty || key.isEmpty) continue;

        final dstDir = io.Directory(p.join(modsRoot, key));
        if (options.skipExistingLocalMods && await dstDir.exists()) continue;
        await _extractDirectoryFromZip(
          z: z,
          prefix: '$rel/',
          destRoot: dstDir.path,
        );
      }
    }

    // 3) 인스턴스 모델 생성 + 이미지 언팩
    final newInstanceId = IdUtil.genId('inst');
    final imageBaseDir = await _imageBaseDir();
    final image = await _unpackImageForInstance(
      z: z,
      imageJson: (instanceJson['image'] as Map?)?.cast<String, dynamic>(),
      destDirForImages: imageBaseDir,
      instanceId: newInstanceId,
    );

    final applied = ((instanceJson['applied_presets'] as List?) ?? const [])
        .cast<Map>()
        .map((r) => AppliedPresetRef(
      presetId: oldToNewPresetId[(r['preset_id'] as String?) ?? ''] ?? IdUtil.genId('mp'),
      isMandatory: (r['is_mandatory'] as bool?) ?? false,
    ))
        .toList(growable: false);

    final overrides = ((instanceJson['overrides'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => ModEntry(
      key: (e['key'] as String?) ?? '',
      enabled: e.containsKey('enabled') ? (e['enabled'] as bool?) : null,
      favorite: (e['favorite'] as bool?) ?? false,
      updatedAt: DateTime.now(),
    ))
        .toList(growable: false);

    final sortKey = (instanceJson['sort_key'] as int?);
    final instance = Instance(
      id: newInstanceId,
      name: (instanceJson['name'] as String?)?.trim().isNotEmpty == true
          ? (instanceJson['name'] as String)
          : 'Imported',
      optionPresetId: null,
      appliedPresets: applied,
      gameMode: GameMode.values[(instanceJson['game_mode'] as int?) ?? GameMode.normal.index],
      overrides: overrides,
      sortKey: sortKey == null ? null : InstanceSortKey.values[sortKey],
      ascending: instanceJson['ascending'] as bool?,
      updatedAt: DateTime.now(),
      lastSyncAt: DateTime.now(),
      image: image,
      group: null,
      categories: ((instanceJson['categories'] as List?) ?? const <String>[]).cast<String>(),
    );

    await instancesRepo.upsert(instance);
    return Result.ok(data: instance.id, code: 'instance.import.ok');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 내부: manifest/zip helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Map<String, Object?> _buildManifest({
    required Instance instance,
    required List<ModPreset> presets,
    required bool includeImage,
    required Set<String> localKeys,
  }) {
    final presetPayloads = [for (final p in presets) _canonPresetPayload(p)];
    final instancePayload = _canonInstancePayload(instance);

    return {
      'schema': 1,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      'exporter': {'app': 'cartridge', 'version': 'dev'},
      'special_mods_excluded': kCartridgeSpecialModKeys.toList(),

      'signatures': {
        'instance': _sha256OfJson(instancePayload),
        'presets': presetPayloads.map(_sha256OfJson).toList(),
      },

      'instance': {
        'name': instance.name,
        'game_mode': instance.gameMode.index,
        'sort_key': instance.sortKey?.index,
        'ascending': instance.ascending,
        'applied_presets': [
          for (final r in instance.appliedPresets)
            {'preset_id': r.presetId, 'is_mandatory': r.isMandatory}
        ],
        'overrides': [
          for (final e in instance.overrides)
            {'key': e.key, 'enabled': e.enabled, 'favorite': e.favorite}
        ],
        'image': _packImage(instance.image, includeImage: includeImage),
        'categories': instance.categories,
      },

      'mod_presets': [
        for (final p in presets)
          {
            'id': p.id,
            'name': p.name,
            'sort_key': p.sortKey?.index,
            'ascending': p.ascending,
            'entries': [
              for (final e in p.entries)
                {'key': e.key, 'enabled': (e.enabled ?? false), 'favorite': e.favorite}
            ],
          }
      ],

      'local_mods': [
        for (final k in localKeys) {'key': k, 'path': 'local_mods/$k'}
      ],
    };
  }

  Map<String, Object?>? _packImage(InstanceImage? img, {required bool includeImage}) {
    if (img is InstanceSprite) {
      return {'kind': 'sprite', 'index': img.index};
    }
    if (img is InstanceUserFile) {
      return includeImage
          ? {
        'kind': 'userfile',
        'filename': 'images/instance_image${p.extension(img.path)}',
        'fit': img.fit.index,
      }
          : {
        'kind': 'userfile',
        'filename': null,
        'fit': img.fit.index,
        'original_path': img.path,
      };
    }
    return null;
  }

  Future<String> _writeZip({
    required String targetDir,
    required String nameHint,
    required Map<String, Object?> manifest,
    required InstanceImage? image,
    required Set<String> localKeys,
    required Map<String, InstalledMod> installed,
  }) async {
    final archive = Archive();

    // manifest.json
    final manifestBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // image
    if (image is InstanceUserFile) {
      final fileName = (manifest['instance'] as Map)['image']?['filename'] as String?;
      if (fileName != null) {
        final file = io.File(image.path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
        }
      }
    }

    // local mods
    if (localKeys.isNotEmpty) {
      for (final key in localKeys) {
        final src = _resolveLocalModDir(key, installed);
        if (src == null) continue;
        final relPrefix = 'local_mods/$key';
        await for (final ent in io.Directory(src).list(recursive: true, followLinks: false)) {
          if (ent is! io.File) continue;
          final rel = p.join(relPrefix, p.relative(ent.path, from: src));
          final bytes = await ent.readAsBytes();
          archive.addFile(ArchiveFile(rel.replaceAll('\\', '/'), bytes.length, bytes));
        }
      }
    }

    final encoder = ZipEncoder();
    final data = encoder.encode(archive);

    final outName = _safeFileName('${nameHint.isEmpty ? "instance" : nameHint}.zip');
    final outPath = p.join(targetDir, outName);
    await io.File(outPath).writeAsBytes(data, flush: true);
    return outPath;
  }

  String _safeFileName(String name) {
    final base = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return base.isEmpty ? 'instance.zip' : base;
  }

  String? _resolveLocalModDir(String key, Map<String, InstalledMod> installed) {
    // installed[key].installPath 가 있으면 그걸 사용
    final hit = installed[key];
    if (hit != null && hit.installPath.isNotEmpty && !_isWorkshopKey(key)) {
      return p.normalize(hit.installPath);
    }
    return null;
  }

  Future<void> _extractDirectoryFromZip({
    required Archive z,
    required String prefix,
    required String destRoot,
  }) async {
    for (final f in z.files) {
      if (!f.isFile) continue;
      if (!f.name.startsWith(prefix)) continue;
      final sub = f.name.substring(prefix.length);
      final target = io.File(p.join(destRoot, sub));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(f.content as List<int>, flush: true);
    }
  }

  Future<InstanceImage?> _unpackImageForInstance({
    required Archive z,
    required Map<String, dynamic>? imageJson,
    required String destDirForImages,
    required String instanceId,
  }) async {
    if (imageJson == null) return null;
    final kind = imageJson['kind'] as String?;
    if (kind == 'sprite') {
      final idx = imageJson['index'] as int? ?? 0;
      return InstanceImage.sprite(index: idx);
    }
    if (kind == 'userfile') {
      final filename = imageJson['filename'] as String?;
      final fitIdx = imageJson['fit'] as int? ?? 0;
      final fit = BoxFit.values[(fitIdx < 0 || fitIdx >= BoxFit.values.length) ? BoxFit.cover.index : fitIdx];

      if (filename == null || filename.isEmpty) {
        // 파일 동봉 안 된 케이스: original_path 가 있으면 그대로 사용(존재여부는 보장 못함)
        final orig = imageJson['original_path'] as String?;
        if (orig != null && orig.isNotEmpty) {
          return InstanceImage.userFile(path: orig, fit: fit);
        }
        return null;
      }

      // zip 안에 포함된 이미지를 꺼내 앱이 접근 가능한 위치로 복사(압축파일 옆/하위 디렉토리)
      final outDir = io.Directory(destDirForImages);
      await outDir.create(recursive: true);
      final ext = p.extension(filename).isEmpty ? '.png' : p.extension(filename);
      final outPath = p.join(outDir.path, '$instanceId$ext');

      final fileInZip = z.files.firstWhere(
            (f) => f.isFile && f.name == filename,
        orElse: () => ArchiveFile('missing', 0, const <int>[]),
      );
      if (!fileInZip.isFile || (fileInZip.content as List).isEmpty) return null;

      await io.File(outPath).writeAsBytes(fileInZip.content as List<int>, flush: true);
      return InstanceImage.userFile(path: outPath, fit: fit);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 동일성 판정(시그니처)
  // ─────────────────────────────────────────────────────────────────────────────
  Map<String, Object?> _canonPresetPayload(ModPreset p) => {
    'name': p.name,
    'entries': [
      for (final e in (p.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        {'key': e.key, 'enabled': e.enabled ?? false, 'favorite': e.favorite}
    ],
  };

  Map<String, Object?> _canonPresetPayloadFromManifest(Map m) {
    final name = (m['name'] as String?) ?? '';
    final entries = ((m['entries'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => {
      'key': (e['key'] as String?) ?? '',
      'enabled': (e['enabled'] as bool?) ?? false,
      'favorite': (e['favorite'] as bool?) ?? false,
    })
        .toList()
      ..sort((a, b) => (a['key'] as String).compareTo(b['key'] as String));
    return {'name': name, 'entries': entries};
  }

  String _sha256OfJson(Map<String, Object?> m) =>
      sha256.convert(utf8.encode(json.encode(m))).toString();

  String _sigPresetModel(ModPreset p) => _sha256OfJson(_canonPresetPayload(p));
  String _sigPresetFromManifest(Map m) => _sha256OfJson(_canonPresetPayloadFromManifest(m));

  Map<String, Object?> _canonInstancePayload(Instance i) => {
    'name': i.name,
    'overrides': [
      for (final e in (i.overrides.toList()..sort((a, b) => a.key.compareTo(b.key))))
        {'key': e.key, 'enabled': e.enabled, 'favorite': e.favorite}
    ],
  };

  // ─────────────────────────────────────────────────────────────────────────────
  // 모델 변환
  // ─────────────────────────────────────────────────────────────────────────────
  ModPreset _toPresetModelWithId(String newId, Map m) => ModPreset(
    id: newId,
    name: (m['name'] as String?) ?? '',
    entries: [
      for (final e in ((m['entries'] as List?) ?? const []).cast<Map>())
        ModEntry(
          key: (e['key'] as String?) ?? '',
          enabled: (e['enabled'] as bool?) ?? false, // 프리셋은 이진 규약
          favorite: (e['favorite'] as bool?) ?? false,
          updatedAt: DateTime.now(),
        )
    ],
    sortKey: (m['sort_key'] as int?) != null
        ? ModSortKey.values[(m['sort_key'] as int)]
        : null,
    ascending: m['ascending'] as bool?,
    updatedAt: DateTime.now(),
    lastSyncAt: DateTime.now(),
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // mods root 추론
  //   - 설치 맵의 installPath 들의 상위 디렉토리(부모)를 가장 다수결로 선택
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String?> _detectModsRoot() async {
    final installed = await env.getInstalledModsMap();
    if (installed.isEmpty) return null;
    final parents = <String, int>{};
    for (final m in installed.values) {
      final folder = m.installPath;
      if (folder.isEmpty) continue;
      final parent = p.dirname(folder);
      parents[parent] = (parents[parent] ?? 0) + 1;
    }
    if (parents.isEmpty) return null;
    parents.removeWhere((k, v) => k.trim().isEmpty);
    if (parents.isEmpty) return null;
    // 최빈값 parent 선택
    final best = parents.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return best;
  }

  // 인스턴스 이미지 저장 기본 경로(AppSupport/instance_images)
  Future<String> _imageBaseDir() async {
    final dir = await fio.ensureAppSupportSubDir('instance_images');
    return dir.path;
  }
}
