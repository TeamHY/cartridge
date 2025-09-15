import 'id_util.dart';
import 'interfaces.dart';

import 'models/challenge_type.dart';

class DefaultGameIndexService implements GameIndexService {
  @override
  Stream<String> currentGameId() async* {
    // 앱 구동 시 기본은 '주간'이라고 가정해 'currentFor(weekly)'를 흘려보냄
    yield await currentFor(ChallengeType.weekly);
  }

  // ── GameIndexService 구현 ───────────────────────────────────────────────────────────
  @override
  Future<({String? prev, String? next})> neighbors(String id) async {
    return RecordId.neighbors(id);
  }

  @override
  Future<String> currentFor(ChallengeType p) async {
    final now = DateTime.now();
    return p == ChallengeType.daily ? RecordId.dailyIdFrom(now) : RecordId.weeklyIdFrom(now);
  }

}