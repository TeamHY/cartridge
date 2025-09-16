import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:week_of_year/date_week_extensions.dart';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/cartridge/runtime/application/isaac_launcher_service.dart';
import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/runtime/isaac_runtime.dart';

import 'models/game_session_events.dart';

class GameSessionServiceImpl implements GameSessionService {
  static const _tag = 'GameSessionService';

  final SupabaseClient _sp;
  final IsaacEnvironmentService _env;
  final IsaacLauncherService _launcher;
  final RecordModePresetService _presetService;
  final RecordModeAllowedPrefsService _allowedPrefs;

  GameSessionServiceImpl(
      this._sp,
      this._env,
      this._launcher, {
        required RecordModePresetService presetService,
        required RecordModeAllowedPrefsService allowedPrefs,
      })  : _presetService = presetService,
        _allowedPrefs = allowedPrefs {
    logI(_tag, 'init');
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_sw.isRunning) _elapsed.add(_sw.elapsed);
    });
    unawaited(_initLog());
  }

  // ── runtime state
  late Timer _ticker;
  final _sw = Stopwatch();
  final _elapsed = StreamController<Duration>.broadcast();
  final _events = StreamController<GameSessionEvent>.broadcast();
  late FileIsaacLogTail _logTail;
  StreamSubscription<IsaacLogMessage>? _logSub;

  RecorderState? _rec;
  String? _dailySeed;
  String? _weeklySeed;
  int? _weeklyCharacter;

  void _emit(GameSessionEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  @override
  Stream<Duration> elapsed() => _elapsed.stream;

  @override
  Stream<GameSessionEvent> events() => _events.stream;

  // ── public API ──────────────────────────────────────────────────────────
  @override
  Future<void> startSession() async {
    logI(_tag, 'startSession()');
    _emit(SessionPhaseChanged(SessionPhase.launching));
    try {
      await _createRecorderMod();
      final entries = await _buildEntriesFromAllowedPrefs();
      logI(_tag, 'launch Isaac | entries=${entries.length}');
      await _launcher.launchIsaac(entries: entries);
      _sw..stop()..reset();
      _elapsed.add(Duration.zero);
      _emit(SessionPhaseChanged(SessionPhase.waitingChallenge));
      logI(_tag, 'waiting for challenge START');
    } catch (e, st) {
      logE(_tag, 'launch failed', e, st);
      _emit(SessionError('launch failed'));
      _emit(SessionPhaseChanged(SessionPhase.error));
      rethrow;
    }
  }

  @override
  Future<void> cancelSession({bool killGame = false}) async {
    logI(_tag, 'cancelSession(killGame=$killGame)');
    if (killGame) {
      await _launcher.runtime.killIsaacIfRunning();
    }
    await finishSession(EndReason.aborted);
  }

  @override
  Future<void> finishSession(EndReason reason) async {
    final elapsedMs = _sw.elapsedMilliseconds;
    logI(_tag, 'finishSession(reason=$reason, elapsed=${elapsedMs}ms)');
    _sw..stop()..reset();
    final rec = _rec;
    _rec = null;
    _elapsed.add(Duration.zero);

    var submitted = false;
    if (reason == EndReason.success && rec != null) {
      final body = {
        'time': elapsedMs,
        'seed': rec.seed,
        'character': rec.character,
        'data': rec.data,
      };
      try {
        if (rec.type == ChallengeType.daily) {
          await _sp.functions.invoke('daily-record', body: body);
        } else {
          await _sp.functions.invoke('weekly-record', body: body);
        }
        submitted = true;
        logI(_tag, 'record submitted: type=${rec.type.name} time=${elapsedMs}ms');
      } catch (e, st) {
        submitted = false;
        logE(_tag, 'record submit failed', e, st);
      }
    }

    _emit(SessionFinished(reason: reason, elapsedMs: elapsedMs, submitted: submitted));
    _emit(SessionPhaseChanged(
      reason == EndReason.success ? SessionPhase.finished : SessionPhase.aborted,
    ));
  }

  // ── internals ───────────────────────────────────────────────────────────
  Future<void> _initLog() async {
    final ini = await _env.resolveOptionsIniPath();
    if (ini == null) {
      logW(_tag, 'log init skipped: options.ini not found');
      return;
    }
    final dir = File(ini).parent.path;
    final path = '$dir\\log.txt';
    logI(_tag, 'bind log tail: $path');
    _logTail = FileIsaacLogTail(path);
    _logSub = _logTail.messages.listen((msg) => _onMessage(msg.topic, msg.parts));
    unawaited(_logTail.start());
  }

  Future<void> _ensureAllowedModsetOrExit() async {
    _emit(SessionPhaseChanged(SessionPhase.validating));
    final snapshot = await _snapshotModSets();
    final rogues = snapshot.rogues;
    if (rogues.isEmpty) return;

    final pretty = rogues
        .map((k) => snapshot.installed[k]?.metadata.name ?? k)
        .toList()
      ..sort();
    logW(_tag, 'disallowed mods detected: ${pretty.join(", ")}');

    _emit(DisallowedModsFound(pretty));
    await _launcher.runtime.killIsaacIfRunning();
    await finishSession(EndReason.disallowed);
  }

  Future<Map<String, ModEntry>> _buildEntriesFromAllowedPrefs() async {
    final view = await _presetService.loadAllowedPresetView();
    final installed = await _env.getInstalledModsMap();
    final prefMap = await _allowedPrefs.ensureInitialized(view.items);

    final map = <String, ModEntry>{};

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

    final recorderKey = installed.entries
        .firstWhere(
          (e) =>
      e.value.metadata.name.trim() == RecorderMod.name ||
          e.value.metadata.directory == RecorderMod.directory,
    )
        .key;
    map[recorderKey] = ModEntry(
      key: 'cartridge-recorder',
      workshopName: RecorderMod.name,
      enabled: true,
    );

    logI(_tag, 'entries prepared: ${map.length}');
    return map;
  }

  Future<({
  Set<String> expected,
  Set<String> enabled,
  List<String> rogues,
  Map<String, InstalledMod> installed,
  })> _snapshotModSets() async {
    final installed = await _env.getInstalledModsMap();
    final enabled = <String>{
      for (final e in installed.entries) if (!e.value.disabled) e.key,
    };

    final view = await _presetService.loadAllowedPresetView();
    final prefs = await _allowedPrefs.ensureInitialized(view.items);
    final expected = <String>{};

    for (final r in view.items) {
      if (!r.allowed || !r.installed) continue;
      final key = r.key;
      if (key == null || key.isEmpty) continue;
      final want = r.alwaysOn ? true : (prefs[_allowedPrefs.keyFor(r)] ?? true);
      if (want) expected.add(key);
    }

    final recorderKey = installed.entries
        .firstWhere(
          (e) =>
      e.value.metadata.name.trim() == RecorderMod.name ||
          e.value.metadata.directory == RecorderMod.directory,
      orElse: () => installed.entries.first,
    )
        .key;
    expected.add(recorderKey);

    final rogues = enabled.where((k) => !expected.contains(k)).toList();
    if (rogues.isNotEmpty) {
      logW(_tag, 'rogues=${rogues.length} enabled=${enabled.length} expected=${expected.length}');
    }
    return (expected: expected, enabled: enabled, rogues: rogues, installed: installed);
  }

  Future<void> _createRecorderMod() async {
    final today = DateTime.now();
    final week = today.weekOfYear;
    final year = RecordId.compatYear(today, week);
    logI(_tag, 'prepare recorder mod | week=$week year=$year');

    final daily = await _sp.from('daily_challenges').select().gte('date', today).lte('date', today);
    final weekly = await _sp.from('weekly_challenges').select().eq('week', week).eq('year', year);
    if (daily.isEmpty || weekly.isEmpty) {
      logW(_tag, 'no challenge available (daily=${daily.isNotEmpty}, weekly=${weekly.isNotEmpty})');
      throw Exception('No challenge available');
    }
    final d = daily.first;
    final w = weekly.first;

    _dailySeed = (d['seed'] as String?)?.trim();
    _weeklySeed = (w['seed'] as String?)?.trim();
    _weeklyCharacter = w['character'] as int?;
    logI(_tag, 'challenge seeds ready (daily=$_dailySeed, weekly=$_weeklySeed, weeklyChar=$_weeklyCharacter)');

    final modsRoot = await _env.resolveModsRoot();
    if (modsRoot == null) {
      logE(_tag, 'Isaac mods directory not found');
      throw Exception('Isaac mods directory not found');
    }

    final dir = Directory('$modsRoot\\cartridge-recorder');
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final main = File('${dir.path}\\main.lua');
    await main.writeAsString(await RecorderMod.getModMain(
      d['seed'],
      d['boss'],
      d['character'] ?? 0,
      w['seed'],
      w['boss'],
      w['character'],
    ));
    final meta = File('${dir.path}\\metadata.xml');
    await meta.writeAsString(RecorderMod.modMetadata);
    logI(_tag, 'recorder mod written at ${dir.path}');
  }

  void _onMessage(String type, List<String> data) async {
    switch (type) {
      case 'LOAD':
        logI(_tag, 'msg:LOAD');
        try {
          await _ensureAllowedModsetOrExit();
        } catch (_) {/* UI에서 처리 */}
        break;

      case 'RESET':
        logI(_tag, 'msg:RESET → stopwatch reset');
        _sw..stop()..reset();
        _rec = null;
        _elapsed.add(Duration.zero);
        _emit(SessionPhaseChanged(SessionPhase.waitingChallenge));
        break;

      case 'START': {
        final t = data[0]; // 'D' | 'W'
        final ch = int.parse(data[1]);
        final seed = data[2];
        logI(_tag, 'msg:START type=$t ch=$ch seed=$seed');

        final dailyOK  = (t == 'D') && (_dailySeed != null) && (seed == _dailySeed);
        final weeklyOK = (t == 'W') && (_weeklySeed != null) && (seed == _weeklySeed)
            && (_weeklyCharacter == null || ch == _weeklyCharacter);

        if (dailyOK || weeklyOK) {
          _sw..reset()..start();
          _rec = RecorderState(
            type: (t == 'D') ? ChallengeType.daily : ChallengeType.weekly,
            character: ch, seed: seed,
          );
          _emit(SessionStarted(type: _rec!.type, seed: seed, character: ch));
          _emit(SessionPhaseChanged(SessionPhase.running));
          logI(_tag, 'session running');
        } else {
          logW(_tag, 'START ignored: seed/character not matched');
        }
        break;
      }

      case 'BOSS':
        _rec?.isBossKilled = true;
        _emit(const BossKilled());
        logI(_tag, 'msg:BOSS → bossKilled=true');
        break;

      case 'STAGE': {
        final chapter = int.tryParse(data[0]) ?? 0;
        final stage   = int.tryParse(data[1]) ?? 0;
        _rec?.data[_sw.elapsedMilliseconds.toString()] = '스테이지 $chapter.$stage 입장';
        _emit(StageEntered(chapter, stage, _sw.elapsedMilliseconds));
        logI(_tag, 'msg:STAGE $chapter.$stage @${_sw.elapsedMilliseconds}ms');
        break;
      }

      case 'END': {
        final t2    = data[0];
        final ch2   = int.tryParse(data[1]) ?? 0;
        final seed2 = data[2].trim();
        logI(_tag, 'msg:END type=$t2 ch=$ch2 seed=$seed2');

        var reason = EndReason.aborted;
        final rec = _rec;
        if (rec != null && rec.isBossKilled) {
          final dailyOK  = (rec.type == ChallengeType.daily)  && (t2 == 'D') && (seed2 == _dailySeed);
          final weeklyOK = (rec.type == ChallengeType.weekly) && (t2 == 'W') && (seed2 == _weeklySeed)
              && (_weeklyCharacter == null || ch2 == _weeklyCharacter);
          if (dailyOK || weeklyOK) reason = EndReason.success;
        }
        await finishSession(reason);
        break;
      }
    }
  }

  @override
  void dispose() {
    logI(_tag, 'dispose');
    if (_ticker.isActive) _ticker.cancel();
    unawaited(_logTail.stop());
    _logSub?.cancel();
    _sw..stop()..reset();
    _elapsed.add(Duration.zero);
    _elapsed.close();
    _events.close();
  }
}

class RecorderState {
  ChallengeType type;
  int character;
  String seed;
  bool isBossKilled = false;
  Map<String, dynamic> data = {};
  RecorderState({required this.type, required this.character, required this.seed});
}
