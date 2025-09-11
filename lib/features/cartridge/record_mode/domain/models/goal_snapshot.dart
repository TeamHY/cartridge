import 'package:cartridge/features/cartridge/record_mode/domain/models/challenge_type.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/models/record_goal.dart';

import 'game_character.dart';

class GoalSnapshot {
  final ChallengeType challengeType;
  final RecordGoal goal;
  final String seed;
  final GameCharacter character;
  const GoalSnapshot({
    required this.challengeType,
    required this.goal,
    required this.seed,
    required this.character
  });
}