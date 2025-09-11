import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/steam_news/steam_news.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';

/// 뉴스 + 썸네일까지 담는 간단한 VM
class SteamNewsCardVM {
  final SteamNewsItem item;
  final String? thumbPath;
  const SteamNewsCardVM(this.item, this.thumbPath);
}

final steamNewsCardsProvider =
StreamProvider<List<SteamNewsCardVM>>((ref) async* {
  final svc = ref.watch(steamNewsServiceProvider);
  final cache = ref.watch(webPreviewCacheProvider);

  Future<List<SteamNewsCardVM>> buildFromRepo() async {
    final state = await svc.repo.load();
    final previews = await Future.wait(
      state.items.map((it) => cache.repo.find(it.url)),
      eagerError: false,
    );
    return [
      for (int i = 0; i < state.items.length; i++)
        SteamNewsCardVM(state.items[i], previews[i]?.imagePath),
    ];
  }

  // 1) 초기 한 번 (캐시 비어 있으면 []일 수 있음)
  yield await buildFromRepo();
  unawaited(
      svc.getLatest().catchError((e, st) {
        logE("SteamNewsProviders", 'failed', e, st);
        return const <SteamNewsItem>[];
      })
  );
  // 2) 서비스/레포 변경 스트림을 구독해 재방출
  await for (final _ in svc.changes) {
    yield await buildFromRepo();
  }
});
