import 'dart:async';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/features/steam_news/steam_news.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';


class SteamNewsService {
  static const _tag = 'SteamNewsService';

  final SteamNewsRepository repo;
  final SteamNewsApi api;
  final WebPreviewCache preview;

  // 최소 재요청 간격(너무 자주 호출 방지)
  static const Duration _minRefreshInterval = Duration(hours: 12);

  SteamNewsService({
    required this.repo,
    required this.api,
    required this.preview,
  });

  Stream<void> get changes => repo.changes;

  /// 캐시 우선 조회 + (필요시) 신선 데이터로 갱신
  Future<List<SteamNewsItem>> getLatest() async {
    final cached = await repo.load();
    final now = DateTime.now();

    // 1) 캐시가 있고, 쿨다운 내면 API를 치지 않음
    final canSkipNetwork = cached.lastFetch != null &&
        now.difference(cached.lastFetch!) < _minRefreshInterval &&
        cached.items.isNotEmpty;

    if (canSkipNetwork) {
      _warmPreviews(cached.items);
      return cached.items;
    }

    // 2) 네트워크 시도. 실패하면 캐시 반환
    try {
      final fresh = await api.fetch(); // count=10, maxlength=0 기본값 사용
      if (fresh.isNotEmpty) {
        await repo.save(SteamNewsState(lastFetch: now, items: fresh));

        // 웹프리뷰 링크를 "현재 news"에 맞춰 동기화(이게 중요)
        await _unlinkRemovedOnly(fresh).catchError((e, st) {
          logE(_tag, 'unlink failed', e, st);
        });

        _warmPreviews(fresh);
        return fresh;
      }
    } catch (e, st) {
      logE(_tag, 'refresh failed', e, st);
    }

    // 3) 네트워크 실패 or 빈 응답이면 캐시 반환(있다면)
    _warmPreviews(cached.items);
    return cached.items;
  }

  Future<void> _unlinkRemovedOnly(List<SteamNewsItem> items) async {
    final current = items.map((e) => e.url).toSet();
    final prev = (await preview.repo.allUrlsFor('steam_news')).toSet();
    final toRemove = prev.difference(current);
    for (final url in toRemove) {
      await preview.repo.unlink('steam_news', url);
    }
    // 추가 링크는 _warmPreviews에서 처리
  }

  /// 뉴스 URL들의 WebPreview warm-up (동시성 제한)
  void _warmPreviews(List<SteamNewsItem> items) {
    const int maxConcurrent = 3; // 제한 동시성
    final it = items.iterator;

    Future<void> worker() async {
      while (true) {
        SteamNewsItem? n;
        // 간단 잠금 없이 순차 이동(단일 isolate이므로 OK)
        if (it.moveNext()) {
          n = it.current;
        } else {
          break;
        }
        try {
          await preview.getOrFetch(
            n.url,
            policy: const RefreshPolicy.ttl(Duration(hours: 24)),
            source: 'steam_news',
            sourceId: n.url,
            targetMaxWidth: 256,
            targetMaxHeight: 180,
            jpegQuality: 85,
          );
          await preview.repo
              .link('steam_news', n.url, n.url)
              .catchError((e, st) => logE(_tag, 'link failed', e, st));
        } catch (e, st) {
          // 썸네일 fetch 실패는 무시하지만, 로깅은 해둡니다.
          logE(_tag, 'warm failed for ${n.url}', e, st);
        }
      }
    }

    // maxConcurrent 만큼 워커 기동
    for (int i = 0; i < maxConcurrent; i++) {
      unawaited(worker());
    }
  }
}
