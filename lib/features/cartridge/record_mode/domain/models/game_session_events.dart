import 'challenge_type.dart';

enum SessionPhase { idle, launching, validating, waitingChallenge, running, finished, aborted, error }
enum EndReason { success, aborted, disallowed }

sealed class GameSessionEvent {
  const GameSessionEvent();
}

class SessionPhaseChanged extends GameSessionEvent {
  final SessionPhase phase;
  const SessionPhaseChanged(this.phase);
}

class DisallowedModsFound extends GameSessionEvent {
  final List<String> names;
  const DisallowedModsFound(this.names);
}

class SessionStarted extends GameSessionEvent {
  final ChallengeType type;
  final String seed;
  final int character;
  const SessionStarted({required this.type, required this.seed, required this.character});
}

class StageEntered extends GameSessionEvent {
  final int chapter;
  final int stage;
  final int elapsedMs;
  const StageEntered(this.chapter, this.stage, this.elapsedMs);
}

class BossKilled extends GameSessionEvent {
  const BossKilled();
}

class SessionFinished extends GameSessionEvent {
  final EndReason reason;
  final int elapsedMs;
  final bool submitted;
  const SessionFinished({required this.reason, required this.elapsedMs, required this.submitted});
}

class SessionError extends GameSessionEvent {
  final String message;
  const SessionError(this.message);
}
