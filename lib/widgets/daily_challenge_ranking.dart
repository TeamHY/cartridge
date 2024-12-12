import 'package:flutter/material.dart';

class DailyChallengeRanking extends StatelessWidget {
  const DailyChallengeRanking({
    super.key,
    required this.date,
    required this.seed,
    required this.boss,
  });

  final String date;

  final String seed;

  final String boss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Challenge',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Date: $date',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Seed: $seed',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Boss: $boss',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class DailyChallengeRankingItem extends StatelessWidget {
  const DailyChallengeRankingItem({
    super.key,
    required this.time,
    required this.character,
    required this.nickname,
  });

  final String time;

  final String character;

  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          time,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(width: 8),
        Text(
          character,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(width: 8),
        Text(
          nickname,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
