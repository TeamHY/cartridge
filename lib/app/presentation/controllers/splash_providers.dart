// splash_providers.dart (예: app/presentation/)
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 스플래시 최소 노출 시간 (테스트에서 0으로 오버라이드 가능)
final splashMinDurationProvider = Provider<Duration>(
      (_) => const Duration(milliseconds: 700),
);

/// 지정한 시간만큼 지연이 끝났는지 여부
final splashMinHoldProvider = FutureProvider<void>((ref) async {
  final d = ref.watch(splashMinDurationProvider);
  await Future.delayed(d);
});
