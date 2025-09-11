---
description: >
  Steam News 모듈의 API/리포지토리/서비스/프로바이더 계약과 정책을 한 눈에 보는 개발 참고 문서입니다.
  count=10·maxlength=1·제목/게시일/대표 이미지 중심·web_preview 워밍업 연동·캐시/새로고침 규칙을 정의합니다.
globs: /lib/features/steam_news/*
alwaysApply: false
---

# Steam News — MDC

> AI/개발자가 Steam 뉴스 기능을 구현/확장할 때 따르는 **단일 기준 문서**입니다.

## 1) 모듈 맵
- `steam_news_api.dart` — `GetNewsForApp` 호출/파싱, **고정 파라미터** 적용.
- `steam_news_repository.dart` — 목록 정제·**중복 제거**·정렬·캐싱·키 정규화.
- `steam_news_service.dart` — **web_preview(imageOnly) 워밍업** 포함 UI 지향 유스케이스.
- `steam_news_item.dart` — **도메인 엔티티**(앱ID, gid, 제목, URL, 게시일 등).
- `steam_news_defaults.dart` — 기본 상수(**count=10**, **maxlength=1**, TTL 등).
- `steam_news_providers.dart` — Riverpod providers(앱ID family, DI 연결).

---

## 2) API 파라미터 규칙
- 엔드포인트: `ISteamNews/GetNewsForApp/v0002`
- 쿼리:
    - `appid=<int>` (필수)
    - `count=10` (**고정**)
    - `maxlength=1` (**고정**, 본문 로드 억제)
    - 추가 파라미터 사용 금지(언어/피드필터 등은 현재 비활성화 정책)

**예시**  
`https://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/?appid={appId}&count=10&maxlength=1`

---

## 3) 원본 API 스키마(요약이 아닌 **필드 전개**)
응답 루트는 `{ appnews: { appid: number, newsitems: NewsItem[], count: number } }`.

| 필드                        | 타입          | 필수 | 예시/설명                          |
|---------------------------|-------------|:--:|--------------------------------|
| `appnews.appid`           | number      | ✅  | 요청한 appId                      |
| `appnews.count`           | number      | ✅  | 반환된 아이템 개수                     |
| `appnews.newsitems[].gid` | string      | ✅  | 전역 ID(중복 제거 1순위 키)             |
| `...[].title`             | string      | ✅  | 뉴스 제목                          |
| `...[].url`               | string(URL) | ✅  | 원문 URL(외부/내부 혼재)               |
| `...[].is_external_url`   | boolean     | ✅  | 외부 링크 여부                       |
| `...[].author`            | string      | ⭕  | 작성자(없을 수 있음)                   |
| `...[].contents`          | string      | ⭕  | 본문(현재 `maxlength=1`로 사실상 미사용)  |
| `...[].feedlabel`         | string      | ⭕  | 피드 레이블                         |
| `...[].feedname`          | string      | ⭕  | 피드 내부 이름                       |
| `...[].feed_type`         | number      | ⭕  | 피드 타입(정수 코드)                   |
| `...[].date`              | number      | ✅  | 게시 시각(Unix epoch seconds)      |
| `...[].appid`             | number      | ⭕  | 일부 응답에 존재할 수 있음(일관적이지 않을 수 있음) |

**정규화 규칙**
- `date`: `DateTime.fromMillisecondsSinceEpoch(date*1000, isUtc:true).toLocal()`로 변환.
- `url`: 트래킹 파라미터 제거(예: `utm_*`, `fbclid`, `gclid`, `ref`, `ref_src`), fragment 제거.
- `title/author/feed*`: trim 및 내부 다중 공백 단일화.

---

## 4) 도메인 엔티티 스키마 `SteamNewsItem`
**목표**: UI에 필요한 최소/핵심 정보를 보전하면서 **키/시간/링크**를 명확히 유지.

| 필드                | 타입       | 필수 | 설명                                      |
|-------------------|----------|:--:|-----------------------------------------|
| `appId`           | int      | ✅  | 요청 appId(루트에서 전파)                       |
| `gid`             | String   | ✅  | 전역 ID(중복 제거 1순위)                        |
| `title`           | String   | ✅  | 제목(정규화됨)                                |
| `url`             | Uri      | ✅  | 정규화된 최종 URL                             |
| `isExternalUrl`   | bool     | ✅  | 외부 링크 여부                                |
| `publishedAt`     | DateTime | ✅  | 로컬 타임존으로 변환된 게시 시각                      |
| `author`          | String?  | ⭕  | 선택 필드                                   |
| `feedLabel`       | String?  | ⭕  | 표시용 레이블                                 |
| `feedName`        | String?  | ⭕  | 내부 구분용                                  |
| `feedType`        | int?     | ⭕  | 정수 코드                                   |
| `previewImageUrl` | Uri?     | ⭕  | **web_preview(imageOnly)** 결과(og:image) |
| `fetchedAt`       | DateTime | ✅  | API 수집 시각                               |
| `sourceHash`      | String   | ✅  | (옵션) 원문 URL+gid 해시(무결성/변경 감지)           |

파생/도움 메서드
- `String get publishedDateLabel()` — 로컬 날짜 라벨(예: `YYYY-MM-DD`).
- `bool get hasImage` — `previewImageUrl != null`.

---

## 5) 서비스 ViewModel(화면 투영 스키마)
> UI에서 바로 쓰기 쉬운 **얇은 투영**. (선택적)

| 필드          | 타입     | 설명                      |
|-------------|--------|-------------------------|
| `title`     | String | 제목                      |
| `subtitle`  | String | `feedLabel` 또는 `author` |
| `dateLabel` | String | 포맷된 날짜                  |
| `imageUrl`  | Uri?   | 미리보기 이미지                |
| `openUrl`   | Uri    | 열기 대상 URL               |
| `debugMeta` | Map?   | 필요 시 디버그용 부가정보          |

---

## 6) 캐시 스키마(메모리/선택적 디스크)
키 정규화: **`gid` 우선**, 없거나 비정상일 때 `canonical(url)` 대체.

| 필드          | 타입            | 설명                                   |
|-------------|---------------|--------------------------------------|
| `key`       | String        | `gid` 또는 canonical(url)              |
| `item`      | SteamNewsItem | 정규화된 도메인 아이템                         |
| `expiresAt` | DateTime      | TTL 만료 시각(`steam_news_defaults.ttl`) |
| `createdAt` | DateTime      | 기록 생성 시각                             |
| `hitCount`  | int           | LRU/통계용                              |
| `error`     | String?       | 최근 실패 사유(미리보기 실패 등은 **허용 실패**)       |

**정책**
- TTL 만료 시 **재호출**; 성공하면 교체, 실패면 기존 캐시 유지(소프트 만료).
- 선택적 디스크 보존(원한다면 SQLite/JSON) — 구조 동일.

---

## 7) 정렬/중복 제거 알고리즘
```dart
// 입력: List<SteamNewsItem> raw
// 출력: 최신순 정렬 + 중복 제거 목록
final map = <String, SteamNewsItem>{}; // key: gid or canonical(url)
for (final x in raw) {
  final key = x.gid.isNotEmpty ? x.gid : canonical(x.url);
  // 이미 존재하면 더 최신(publishedAt)인 것으로 교체
  final prev = map[key];
  if (prev == null || x.publishedAt.isAfter(prev.publishedAt)) {
    map[key] = x;
  }
}
final deduped = map.values.toList()
  ..sort((a,b) => b.publishedAt.compareTo(a.publishedAt)); // DESC
```

---

## 8) 이미지 정책(web_preview 연동)
- `web_preview(imageOnly)`로 **og:image**만 선점(타임아웃 짧게, 실패 허용).
- 이미지 URL은 `previewImageUrl`에 저장(없어도 아이템 채택).
- 뉴스 목록은 **텍스트 우선**·이미지 **보조** 정책(이미지 실패가 전체 실패를 막지 않음).

---

## 9) 에러 매핑
- API: `network_error`, `timeout`, `parse_error`, `unexpected_shape`
- 캐시: `cache_miss`(내부), `stale_but_usable`(소프트 만료)
- 미리보기: `preview_timeout`, `preview_parse_error` (UI는 무시/대체 이미지)

UI 반영 가이드: InfoBar로 “불러오기 실패 · 다시 시도” 버튼 노출.

---

## 10) 프로바이더 계약
```dart
/// 앱별 뉴스 10건을 비동기로 제공.
final steamNewsProvider = FutureProvider.autoDispose
  .family<List<SteamNewsItem>, int>((ref, appId) async {
    final svc = ref.watch(steamNewsServiceProvider);
    return svc.fetchNews(appId);
  });

/// DI
final steamNewsServiceProvider = Provider<SteamNewsService>((ref) => ...);
final steamNewsRepositoryProvider = Provider<SteamNewsRepository>((ref) => ...);
final steamNewsApiProvider = Provider<SteamNewsApi>((ref) => ...);
```

---

## 11) 상수(`steam_news_defaults.dart`)
- `defaultCount = 10`
- `defaultMaxlength = 1`
- `ttl = Duration(/* 프로젝트 기본값: 예 24h or 7d */)`  
  ↳ **실제 값은 소스 상수를 기준**으로 하며, 문서와 불일치 시 **소스가 우선**.

---

## 12) 테스트 케이스
- “API 파라미터가 **count=10, maxlength=1**로 고정된다”
- “`gid` 기준으로 **중복 제거**된다(부재 시 canonical(url))”
- “정렬은 **publishedAt DESC**로 적용된다”
- “TTL 만료 시 **재호출** 후 캐시가 **갱신**된다(실패 시 소프트 만료 유지)”
- “web_preview **imageOnly** 연동: 실패해도 아이템은 유지된다”
- “`date`(epoch) → `DateTime(local)` 변환이 정확하다”

---

## 13) 확장 포인트
- 앱별 `count` 커스터마이징, 언어 필터 적용(추후 정책 확정 시)
- 디스크 캐시(SQLite)로 오프라인 뷰 지원
- 이미지 프리로드 전략(동시성/타임아웃 별도 상수)
- 웹 프리뷰 실패시 **대체 이미지**(앱 아이콘/플레이스홀더) 적용
