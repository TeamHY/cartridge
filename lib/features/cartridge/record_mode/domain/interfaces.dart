import 'models/auth_user.dart';
import 'models/challenge_type.dart';
import 'models/game_session_events.dart';
import 'models/goal_snapshot.dart';
import 'models/leaderboard_entry.dart';

abstract class AuthService {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<void> signInWithPassword(String email, String password);
  Future<void> signUpWithPassword(String email, String password);
  Future<void> signOut();
  Future<void> changeNickname(String nickname);
}

abstract class GoalReadService {
  Stream<GoalSnapshot?> current(ChallengeType challengeType);
  Future<GoalSnapshot?> byGameId(String gameId);
}

abstract class LeaderboardService {
  Future<List<LeaderboardEntry>> fetchAll({required String gameId});
}

abstract class GameIndexService {
  Stream<String> currentGameId();
  Future<({String? prev, String? next})> neighbors(String gameId);
  Future<String> currentFor(ChallengeType challengeType);
}

abstract class GameSessionService {
  Stream<Duration> elapsed();
  Stream<GameSessionEvent> events();
  Future<void> startSession();
  Future<void> cancelSession({bool killGame = false});
  Future<void> finishSession(EndReason reason);
  void dispose();
}