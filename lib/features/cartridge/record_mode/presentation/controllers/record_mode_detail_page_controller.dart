import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/record_mode/record_mode.dart';
import 'package:cartridge/core/service_providers.dart';

// Delegate Record Mode UI providers to app-wide DI providers
final recordModeGoalReadProvider = Provider<GoalReadService>((ref) => ref.read(recordModeGoalReadServiceProvider));
final recordModeLeaderboardProvider = Provider<LeaderboardService>((ref) => ref.read(recordModeLeaderboardServiceProvider));
final recordModeGameIndexProvider = Provider<GameIndexService>((ref) => ref.read(recordModeGameIndexServiceProvider));
final recordModeSessionProvider = Provider<GameSessionService>((ref) => ref.read(recordModeSessionServiceProvider));

const _unset = Object();

class RecordModeUiState {
  final ChallengeType challengeType;
  final String? gameId;
  final bool loadingMore;
  final int page;
  final List<LeaderboardEntry> entries;
  final ({String? prev, String? next})? neighbors;
  final GoalSnapshot? goal;
  final bool loadingGoal;
  final bool loadedAll;
  final GamePresetView? preset;
  final bool loadingPreset;

  const RecordModeUiState({
    required this.challengeType,
    required this.gameId,
    required this.loadingMore,
    required this.page,
    required this.entries,
    required this.neighbors,
    required this.goal,
    required this.loadingGoal,
    required this.loadedAll,
    required this.preset,
    required this.loadingPreset,
  });

  static RecordModeUiState initial()=>const RecordModeUiState(
    challengeType: ChallengeType.weekly,
    gameId: null,
    loadingMore: false,
    page: 0,
    entries: [],
    neighbors: null,
    goal: null,
    loadingGoal: false,
    loadedAll: false,
    preset: null,
    loadingPreset: false,
  );
  RecordModeUiState copyWith({
    ChallengeType? challengeType,
    String? gameId,
    bool? loadingMore,
    int? page,
    List<LeaderboardEntry>? entries,
    ({String? prev, String? next})? neighbors,
    Object? goal = _unset,
    bool? loadingGoal,
    bool? loadedAll,
    Object? preset = _unset,
    bool? loadingPreset,
  })=>RecordModeUiState(
    challengeType: challengeType ?? this.challengeType,
    gameId: gameId ?? this.gameId,
    loadingMore: loadingMore ?? this.loadingMore,
    page: page ?? this.page,
    entries: entries ?? this.entries,
    neighbors: neighbors ?? this.neighbors,
    goal: identical(goal, _unset) ? this.goal : goal as GoalSnapshot?,
    loadingGoal: loadingGoal ?? this.loadingGoal,
    loadedAll: loadedAll ?? this.loadedAll,
    preset: identical(preset, _unset) ? this.preset : preset as GamePresetView?,
    loadingPreset : loadingPreset ?? this.loadingPreset,
  );
}

final recordModeUiControllerProvider =
StateNotifierProvider.autoDispose<RecordModeUiController, RecordModeUiState>((ref) {
  final c = RecordModeUiController(ref);
  c._sub = ref.read(recordModeGameIndexProvider).currentGameId().listen(c._setGame);
  ref.onDispose(() => c._sub?.cancel());
  return c;
});

final recordModeIsPastProvider = Provider.autoDispose<bool>((ref) {
  final ui = ref.watch(recordModeUiControllerProvider);
  final id = ui.gameId;
  return id != null && RecordId.temporalOf(id) == ContestTemporal.past;
});

class RecordModeUiController extends StateNotifier<RecordModeUiState> {
  final Ref ref;
  StreamSubscription<String>? _sub;
  RecordModeUiController(this.ref) : super(RecordModeUiState.initial());
  int _seq = 0;

  Future<void> _setGame(String id) async {
    final seq = ++_seq;
    state = state.copyWith(
      gameId: id,
      page: 0,
      entries: [],
      loadedAll: false,
      loadingGoal: true,
      goal: null,
      challengeType: _challengeTypeFromGameId(id),
    );
    await _loadNeighbors(id, seq);
    await _loadGoalFor(id, seq);
    unawaited(_loadAllowedPreset());
    await _fetchMoreGuarded(reset: true, expectId: id, seq: seq);
  }

  Future<void> _loadAllowedPreset() async {
    state = state.copyWith(loadingPreset: true, preset: null);
    try {
      final svc = ref.read(recordModePresetServiceProvider);
      final view = await svc.loadAllowedPresetView();
      if (!mounted) return;
      state = state.copyWith(loadingPreset: false, preset: view);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loadingPreset: false, preset: null);
    }
  }

  Future<void> setChallengeType(ChallengeType p) async {
    if (state.challengeType == p) return;
    // 선택된 기간의 "현재" gameId 획득
    final id = await ref.read(recordModeGameIndexProvider).currentFor(p);
    // gameId 세팅 및 neighbors/goal/entries 재로딩
    await _setGame(id);
  }

  Future<void> navPrev() async {
    final p = state.neighbors?.prev;
    if (p == null) return;
    await _setGame(p);
  }

  Future<void> navNext() async {
    final n = state.neighbors?.next;
    if (n == null) return;
    await _setGame(n);
  }

  Future<void> _loadNeighbors(String id, int seq) async {
    final ns = await ref.read(recordModeGameIndexProvider).neighbors(id);
    if (!mounted || seq != _seq || state.gameId != id) return;
    state = state.copyWith(neighbors: ns);
  }


  ChallengeType _challengeTypeFromGameId(String id) =>
      RecordId.isWeekly(id) ? ChallengeType.weekly : ChallengeType.daily;

  Future<void> _loadGoalFor(String id, int seq) async {
    final snap = await ref.read(recordModeGoalReadProvider).byGameId(id);
    if (!mounted || seq != _seq || state.gameId != id) return;
    state = state.copyWith(loadingGoal: false, goal: snap);
  }

  Future<void> _fetchMoreGuarded({required bool reset, required String expectId, required int seq}) async {
    final g = state.gameId;
    if (g == null || state.loadingMore || state.loadedAll) return;

    state = state.copyWith(loadingMore: true);
    final all = await ref.read(recordModeLeaderboardProvider).fetchAll(gameId: g);
    if (!mounted || seq != _seq || state.gameId != expectId) return; // ⬅ 가드

    state = state.copyWith(
      loadingMore: false,
      page: reset ? 1 : state.page + 1,
      entries: reset ? all : [...state.entries, ...all],
      loadedAll: true,
    );
  }

  Future<void> fetchMore({bool reset = false}) async {
    final g = state.gameId;
    if (g == null) return;
    await _fetchMoreGuarded(reset: reset, expectId: g, seq: _seq);
  }

  Future<void> refreshAllowedPreset() => _loadAllowedPreset();
}


String getTimeString(Duration time) {
  final hours = time.inHours.toString().padLeft(2, '0');
  final minutes = (time.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (time.inSeconds % 60).toString().padLeft(2, '0');
  final milliseconds =
  ((time.inMilliseconds % 1000) / 10).floor().toString().padLeft(2, '0');

  return '$hours:$minutes:$seconds.$milliseconds';
}