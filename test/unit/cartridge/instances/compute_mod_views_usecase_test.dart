import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

void main() {
  group('ComputeModViewsUseCase', () {
    final usecase = ComputeModViewsUseCase();

    InstalledMod installed0({
      required String folder,
      String id = '',
      String name = '',
      String version = '1.0',
      bool disabled = false,
    }) {
      return InstalledMod(
        metadata: ModMetadata(
          id: id,
          name: name,
          directory: folder, // folderName 으로 사용됨
          version: version,
          visibility: ModVisibility.public,
          tags: const <String>[],
        ),
        disabled: disabled,
      );
    }

    ModPreset preset0({
      required String id,
      required String name,
      required List<ModEntry> entries,
    }) {
      return ModPreset(id: id, name: name, entries: entries);
    }

    Instance instance({
      List<AppliedPresetRef> applied = const [],
      List<ModEntry> overrides = const [],
      String name = 'I',
    }) {
      return Instance(
        id: 'inst',
        name: name,
        optionPresetId: null,
        appliedPresets: applied,
        gameMode: GameMode.normal,
        overrides: overrides,
        image: null,
        sortKey: InstanceSortKey.name,
        ascending: true,
        updatedAt: null,
        lastSyncAt: null,
        group: null,
        categories: const [],
      );
    }

    test('설치만 있고 preset/override 없음 → disabled, 이름은 설치 메타', () {
      final installed = [installed0(folder: 'mod.a', name: 'Installed A')];
      final views = usecase(
        installedMods: installed,
        selectedPresets: const [],
        instance: instance(),
      );

      expect(views, hasLength(1));
      final v = views.single;
      expect(v.id, 'mod.a');
      expect(v.isInstalled, isTrue);
      expect(v.effectiveEnabled, isFalse);
      expect(v.explicitEnabled, isFalse);
      expect(v.favorite, isFalse);
      expect(v.displayName, 'Installed A');
      expect(v.enabledByPresets, isEmpty);
    });

    test('Preset이 enable → effectiveEnabled=true, explicitEnabled=false, enabledByPresets에 id 포함', () {
      final preset = preset0(
        id: 'p1',
        name: 'P1',
        entries: [ModEntry(key: 'mod.a', enabled: true, favorite: false, workshopName: 'PresetName A')],
      );

      final views = usecase(
        installedMods: [installed0(folder: 'mod.a', name: 'Installed A')],
        selectedPresets: [preset],
        instance: instance(),
      );

      final v = views.singleWhere((e) => e.id == 'mod.a');
      expect(v.effectiveEnabled, isTrue);
      expect(v.explicitEnabled, isFalse, reason: 'preset만으로 explicitEnabled는 켜지지 않음');
      expect(v.enabledByPresets, contains('p1'));
    });

    test('Instance override: enabled=true → explicitEnabled/effectiveEnabled=true', () {
      final views = usecase(
        installedMods: [installed0(folder: 'mod.a', name: 'A')],
        selectedPresets: const [],
        instance: instance(
          overrides: [ModEntry(key: 'mod.a', enabled: true, favorite: false, workshopName: 'Inst A')],
        ),
      );

      final v = views.singleWhere((e) => e.id == 'mod.a');
      expect(v.explicitEnabled, isTrue);
      expect(v.effectiveEnabled, isTrue);
      expect(v.favorite, isFalse);
    });

    test('Instance override: enabled=false → preset enable도 무력화', () {
      final preset = preset0(
        id: 'p1',
        name: 'P1',
        entries: [ModEntry(key: 'mod.a', enabled: true, favorite: false)],
      );

      final views = usecase(
        installedMods: [installed0(folder: 'mod.a', name: 'A')],
        selectedPresets: [preset],
        instance: instance(
          overrides: [ModEntry(key: 'mod.a', enabled: false, favorite: false)],
        ),
      );

      final v = views.singleWhere((e) => e.id == 'mod.a');
      expect(v.effectiveEnabled, isFalse, reason: 'instDisable이 우선');
      expect(v.explicitEnabled, isFalse);
      expect(v.enabledByPresets, contains('p1'));
    });

    test('즐겨찾기(favorite)는 Instance override만 반영', () {
      final preset = preset0(
        id: 'p1',
        name: 'P1',
        entries: [ModEntry(key: 'mod.a', enabled: true, favorite: true)], // preset favorite 무시
      );

      final views = usecase(
        installedMods: [installed0(folder: 'mod.a', name: 'A')],
        selectedPresets: [preset],
        instance: instance(
          overrides: [ModEntry(key: 'mod.a', enabled: null, favorite: true)],
        ),
      );

      final v = views.singleWhere((e) => e.id == 'mod.a');
      expect(v.favorite, isTrue);
      expect(v.effectiveEnabled, isTrue); // preset enable로 켜짐
      expect(v.explicitEnabled, isFalse); // instEnable이 아니므로
    });

    test('표시 이름 우선순위: installed > instance.workshopName > preset.workshopName > folder', () {
      // Case 1: installed 우선
      var views = usecase(
        installedMods: [installed0(folder: 'mod.a', name: 'Installed A')],
        selectedPresets: [
          preset0(id: 'p1', name: 'P1', entries: [ModEntry(key: 'mod.a', enabled: true, workshopName: 'Preset A')]),
        ],
        instance: instance(
          overrides: [ModEntry(key: 'mod.a', enabled: null, favorite: false, workshopName: 'Inst A')],
        ),
      );
      expect(views.single.displayName, 'Installed A');

      // Case 2: not installed → instance 이름
      views = usecase(
        installedMods: const [],
        selectedPresets: [
          preset0(id: 'p1', name: 'P1', entries: [ModEntry(key: 'mod.a', enabled: true, workshopName: 'Preset A')]),
        ],
        instance: instance(
          overrides: [ModEntry(key: 'mod.a', enabled: null, favorite: false, workshopName: 'Inst A')],
        ),
      );
      expect(views.single.displayName, 'Inst A');

      // Case 3: not installed & instance 이름 없음 → preset 이름
      views = usecase(
        installedMods: const [],
        selectedPresets: [
          preset0(id: 'p1', name: 'P1', entries: [ModEntry(key: 'mod.a', enabled: true, workshopName: 'Preset A')]),
        ],
        instance: instance(overrides: const []),
      );
      expect(views.single.displayName, 'Preset A');

      // Case 4: 모두 없으면 folderName(=id)
      views = usecase(
        installedMods: const [],
        selectedPresets: [
          preset0(id: 'p1', name: 'P1', entries: [ModEntry(key: 'mod.z', enabled: false)]),
        ],
        instance: instance(overrides: const []),
      );
      expect(views.single.displayName, 'mod.z');
    });

    test('여러 preset이 같은 모드를 enable → enabledByPresets에 모두 수집', () {
      final p1 = preset0(id: 'p1', name: 'P1', entries: [ModEntry(key: 'mod.a', enabled: true)]);
      final p2 = preset0(id: 'p2', name: 'P2', entries: [ModEntry(key: 'mod.a', enabled: true)]);

      final views = usecase(
        installedMods: [installed0(folder: 'mod.a', name: 'A')],
        selectedPresets: [p1, p2],
        instance: instance(),
      );

      final v = views.singleWhere((e) => e.id == 'mod.a');
      expect(v.enabledByPresets, containsAll(<String>{'p1', 'p2'}));
      expect(v.effectiveEnabled, isTrue);
    });

    test('미설치라도 preset/override로 enable 의도는 반영(isInstalled=false 별개)', () {
      final p1 = preset0(id: 'p1', name: 'P1', entries: [ModEntry(key: 'mod.a', enabled: true)]);
      final views = usecase(
        installedMods: const [], // 미설치
        selectedPresets: [p1],
        instance: instance(),
      );

      final v = views.single;
      expect(v.isInstalled, isFalse);
      expect(v.effectiveEnabled, isTrue, reason: '코어 로직은 설치 여부와 별개로 enable 의도를 표현');
    });
  });
}
