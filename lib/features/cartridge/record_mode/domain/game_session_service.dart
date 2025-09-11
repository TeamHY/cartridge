import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:week_of_year/date_week_extensions.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/cartridge/runtime/application/isaac_launcher_service.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

typedef NotifyFn = void Function(String title, String message);

class GameSessionServiceImpl implements GameSessionService {
  final SupabaseClient _sp;
  final IsaacEnvironmentService _env;
  final IsaacLauncherService _launcher;
  late Timer _ticker;
  final RecordModePresetService _presetService;
  final RecordModeAllowedPrefsService _allowedPrefs;
  final NotifyFn? _notify;

  GameSessionServiceImpl(this._sp, this._env, this._launcher, {
    required RecordModePresetService presetService,
    required RecordModeAllowedPrefsService allowedPrefs,
    NotifyFn? onNotify,
  }) : _presetService = presetService,
        _allowedPrefs = allowedPrefs,
        _notify = onNotify {
    _ticker = Timer.periodic(const Duration(milliseconds:200), (_) {
      if(_sw.isRunning) {
        _elapsed.add(_sw.elapsed);
      }
    });
    unawaited(_initLog());
  }

  final _sw = Stopwatch();
  final _elapsed = StreamController<Duration>.broadcast();
  late FileIsaacLogTail _logTail;
  StreamSubscription<IsaacLogMessage>? _logSub;
  RecorderState? _rec;
  String? _dailySeed;
  String? _weeklySeed;
  int? _weeklyCharacter;

  void dispose() {
    // 타이머 정리
    if (_ticker.isActive) {
      _ticker.cancel();
    }

    // 로그 tail 정지 + 구독 해제
    unawaited(_logTail.stop());
    _logSub?.cancel();
    _logSub = null;

    // 스톱워치/스트림 정리
    _sw..stop()..reset();
    // 마지막으로 0을 한번 흘려보내 UI 깔끔하게
    _elapsed.add(Duration.zero);
    _elapsed.close();
  }

  @override
  Stream<Duration> elapsed() => _elapsed.stream;

  @override
  Future<void> start() async {
    await _createRecorderMod();
    final entries = await _buildEntriesFromAllowedPrefs();
    await _launcher.launchIsaac(entries: entries);
    _sw..stop()..reset();
    _elapsed.add(Duration.zero);
  }

  Future<Map<String, ModEntry>> _buildEntriesFromAllowedPrefs() async {
    final view      = await _presetService.loadAllowedPresetView();
    final installed = await _env.getInstalledModsMap();
    final prefMap   = await _allowedPrefs.ensureInitialized(view.items);

    final map = <String, ModEntry>{};

    // 일반 허용 모드
    for (final r in view.items) {
      if (!r.allowed || !r.installed) continue;
      final key = r.key;
      if (key == null || key.isEmpty) continue;

      final want = r.alwaysOn ? true : (prefMap[_allowedPrefs.keyFor(r)] ?? true);
      if (want) {
        map[key] = ModEntry(
          key: key,
          workshopId: r.workshopId,
          workshopName: r.name,
          enabled: true,
        );
      }
    }

    // 🔒 Recorder 항상 ON (폴더 키 탐색)
    final recorderKey = installed.entries
        .firstWhere(
          (e) =>
      e.value.metadata.name.trim() == RecorderMod.name ||
          e.value.metadata.directory == RecorderMod.directory,
    )
        .key;
    map[recorderKey] = ModEntry(
      key: recorderKey,
      workshopName: RecorderMod.name,
      enabled: true,
    );

    return map;
  }

  @override
  Future<void> stop({required bool cleared}) async {
    if(!_sw.isRunning) {
      return;
    }
    _sw.stop();
    if(cleared && _rec != null ) {
      final ms = _sw.elapsedMilliseconds;
      final body={
        'time': ms,
        'seed': _rec!.seed,
        'character': _rec!.character,
        'data': _rec!.data,
      };
      if(_rec!.type == ChallengeType.daily) {
        await _sp.functions.invoke('daily-record', body: body);
      } else {
        await _sp.functions.invoke('weekly-record', body: body);
      }
    }
    _rec=null;
    _elapsed.add(Duration.zero);
  }


  Future<void> _initLog() async {
    final ini = await _env.resolveOptionsIniPath();
    if (ini == null) {
      return;
    }
    final dir = File(ini).parent.path;
    _logTail = FileIsaacLogTail('$dir\\log.txt');
    _logSub = _logTail.messages.listen((msg) {
      _onMessage(msg.topic, msg.parts);
    });
    // Fire and forget; service lifetime matches app/session
    unawaited(_logTail.start());
  }


  Future<void> _ensureAllowedModsetOrExit() async {
    final snapshot = await _snapshotModSets();
    final rogues = snapshot.rogues;
    if (rogues.isEmpty) return;

    // UI 알림
    final pretty = rogues.map((k) {
      final meta = snapshot.installed[k]?.metadata;
      return meta?.name ?? k;
    }).toList()
      ..sort();
    _notify?.call(
      '허용되지 않은 모드 감지',
      '허용 목록에 없는 모드가 활성화되어 게임을 종료합니다.\n${pretty.join(', ')}',
    );

    // Isaac 종료
    await _launcher.runtime.killIsaacIfRunning();

    // 타이머/상태 리셋
    _sw..stop()..reset();
    _rec = null;
    _elapsed.add(Duration.zero);
  }

  Future<({
  Set<String> expected,           // 허용되어야 할 활성 폴더 키
  Set<String> enabled,            // 실제 활성 폴더 키
  List<String> rogues,            // enabled - expected
  Map<String, InstalledMod> installed,
  })> _snapshotModSets() async {
    final installed = await _env.getInstalledModsMap();

    // 실제 활성 폴더키
    final enabled = <String>{
      for (final e in installed.entries)
        if (!e.value.disabled) e.key,
    };

    // 허용 프리셋 + 사용자 설정으로 만든 기대치
    final view    = await _presetService.loadAllowedPresetView();
    final prefs   = await _allowedPrefs.ensureInitialized(view.items);
    final expected = <String>{};

    for (final r in view.items) {
      if (!r.allowed || !r.installed) continue;
      final key = r.key;
      if (key == null || key.isEmpty) continue;

      final want = r.alwaysOn ? true : (prefs[_allowedPrefs.keyFor(r)] ?? true);
      if (want) expected.add(key);
    }

    // Recorder는 항상 ON
    final recorderKey = installed.entries
        .firstWhere(
          (e) =>
      e.value.metadata.name.trim() == RecorderMod.name ||
          e.value.metadata.directory == RecorderMod.directory,
      orElse: () => installed.entries.first, // 안전장치(없을 일은 거의 없음)
    )
        .key;
    expected.add(recorderKey);

    // 허용 밖 활성(rogues)
    final rogues = enabled.where((k) => !expected.contains(k)).toList();

    return (expected: expected, enabled: enabled, rogues: rogues, installed: installed);
  }


  Future<void> _createRecorderMod() async {
    final today=DateTime.now();
    final week=today.weekOfYear;
    final year = RecordId.compatYear(today, week);
    final daily = await _sp
        .from('daily_challenges')
        .select()
        .gte('date',today)
        .lte('date',today);
    final weekly = await _sp
        .from('weekly_challenges')
        .select()
        .eq('week',week)
        .eq('year',year);
    if(daily.isEmpty || weekly.isEmpty) {
      throw Exception('No challenge available');
    }
    final d=daily.first;
    final w=weekly.first;

    _dailySeed = (d['seed'] as String?)?.trim();
    _weeklySeed = (w['seed'] as String?)?.trim();
    _weeklyCharacter = w['character'] as int?;

    final modsRoot = await _env.resolveModsRoot();
    if (modsRoot == null) {
      throw Exception('Isaac mods directory not found');
    }
    final dir=Directory('$modsRoot\\cartridge-recorder');
    if(await dir.exists()) {
      await dir.delete(recursive:true);
    }
    await dir.create(recursive:true);
    final main = File('${dir.path}\\main.lua');
    await main.writeAsString(
        await RecorderMod.getModMain(
          d['seed'],
          d['boss'],
          d['character'] ?? 0,
          w['seed'],
          w['boss'],
          w['character'],
        )
    );
    final meta = File('${dir.path}\\metadata.xml');
    await meta.writeAsString(RecorderMod.modMetadata);
  }


  void _onMessage(String type, List<String> data) async {
    switch(type) {
      case 'LOAD':
        try{
          await _ensureAllowedModsetOrExit();
        } catch (_)
        { /* UI에서 다이얼로그 처리 */ } break;
      case 'RESET':
        _sw..stop()..reset();
        _rec = null;
        _elapsed.add(Duration.zero);
        break;
      case 'START':
        final t = data[0];
        final ch = int.parse(data[1]);
        final seed = data[2];

        final isDailyOK = (t == 'D') && (_dailySeed != null) && (seed == _dailySeed);
        final isWeeklyOK = (t == 'W') &&
            (_weeklySeed != null) &&
            (seed == _weeklySeed) &&
            (_weeklyCharacter == null || ch == _weeklyCharacter);

        if (isDailyOK || isWeeklyOK) {
          _sw
            ..reset()
            ..start();
          _rec = RecorderState(
            type: (t == 'D') ? ChallengeType.daily : ChallengeType.weekly,
            character: ch,
            seed: seed,
          );
        }
        break;

      case 'END': // data: [D|W, character, seed]
        final t2 = data[0];
        final ch2 = int.tryParse(data[1]) ?? 0;
        final seed2 = data[2].trim();

        final rec = _rec;
        if (rec != null && rec.isBossKilled) {
          final isDailyMatch =
              (rec.type == ChallengeType.daily) && (t2 == 'D') && (seed2 == _dailySeed);
          final isWeeklyMatch =
              (rec.type == ChallengeType.weekly) &&
                  (t2 == 'W') &&
                  (seed2 == _weeklySeed) &&
                  (_weeklyCharacter == null || ch2 == _weeklyCharacter);

          if (isDailyMatch || isWeeklyMatch) {
            final ms = _sw.elapsedMilliseconds;
            final body = {
              'time': ms,
              'seed': seed2,
              'character': ch2,
              'data': rec.data,
            };
            if (rec.type == ChallengeType.daily) {
              await _sp.functions.invoke('daily-record', body: body);
            } else {
              await _sp.functions.invoke('weekly-record', body: body);
            }
          }
        }

        _sw
          ..stop()
          ..reset();
        _rec = null;
        _elapsed.add(Duration.zero);
        break;

      case 'BOSS':
        _rec?.isBossKilled=true;
      break;
      case 'STAGE':
        _rec?.data.addAll({ _sw.elapsedMilliseconds.toString(): '스테이지 ${data[0]}.${data[1]} 입장' });
      break;
    }
  }
}


class RecorderState {
  ChallengeType type;
  int character;
  String seed;
  bool isBossKilled=false;
  Map<String,dynamic> data={};
  RecorderState({required this.type, required this.character, required this.seed});
}