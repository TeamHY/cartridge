import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/models/game_session_events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// 타이머 스트림
final recordModeElapsedProvider = StreamProvider.autoDispose<Duration>(
      (ref) => ref.watch(recordModeSessionProvider).elapsed(),
);

// 이벤트 스트림
final recordModeEventsProvider = StreamProvider.autoDispose<GameSessionEvent>(
      (ref) => ref.watch(recordModeSessionProvider).events(),
);
