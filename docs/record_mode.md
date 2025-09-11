---
description: >
  Cartridge Record Mode의 인증/목표/리더보드/세션(스톱워치·로그팔로우·업로드) 전체 계약과 규칙을 정리한 개발 참고 문서입니다.
  D-/W- 게임ID 규칙, ISO week 호환 연도, 프리셋 검증, Recorder 모드 생성, Supabase Functions 업로드 흐름을 표준화합니다.
globs: /lib/features/cartridge/record_mode/*
alwaysApply: false
---

# Record Mode — MDC

> AI/개발자가 `cartridge/record_mode`를 구현/확장할 때 따르는 **단일 기준**입니다. (Windows 전용)

## 1) 모듈 맵
- `domain/models/*.dart` — **모델 집합**: AuthUser, IsaacCharacter(+이미지/로컬라이즈), RecordGoal(+id↔enum/에셋), GoalSnapshot, LeaderboardEntry, ChallengeType.
- `domain/interfaces.dart` — **인터페이스**: `AuthService/GoalReadService/LeaderboardService/GameIndexService/GameSessionService`.
- `domain/repositories/*.dart` — **저장소 계약**: `AuthRepository/LeaderboardRepository`.
- `infra/supabase_auth_repository.dart` — **AuthRepository(Supabase)**: users 테이블 연결.
- `infra/supabase_leaderboard_repository.dart` — **LeaderboardRepository(Supabase)**: challengeId 조회 + Functions 호출.
- `infra/recorder_mod.dart` — **Recorder 모드 템플릿 로더**: `.env(RECORDER_MOD_URL)`에서 lua 템플릿 획득/치환.
- `domain/supabase_auth_service.dart` — **AuthService 구현**: auth 상태/프로필 하이드레이트/닉네임 변경.
- `domain/supabase_goal_service.dart` — **GoalReadService 구현**: 일일/주간 현재/지정 조회.
- `domain/leaderboard_service_impl.dart` — **LeaderboardService 구현**: ID 파싱→정렬→에러 내성.
- `domain/game_index_service.dart` — **GameIndexService 구현**: ID 생성/이웃 탐색/호환연도.
- `domain/game_session_service.dart` — **GameSessionService 구현**: 프리셋 검증→Recorder 생성→런치→로그팔로우→업로드.

---

## 2) 모델 스키마

### 2.1 Auth/사용자
- `AuthUser { uid:String, nickname:String, isAdmin:bool }` — 닉네임은 users.email 또는 수동 변경값.

### 2.2 캐릭터
- `IsaacCharacter` — **DB 인덱스와 1:1** enum; `_kCharacterImageFiles.length == values.length` **assert**; `imageAsset`, `localizedName(loc)` 게터.
- `GameCharacter(id:int)` → 안전 enum 매핑 + `LocalizedGameCharacter` 생성.

### 2.3 목표(보스)
- `RecordGoalId` ↔ `idString`(예: `mega_satan`)·`localizedTitle(loc)`·`imageAsset` 매핑.
- `RecordGoal(id:String)` — 안전 기본값(`perfection`), `localized(context)`로 확정 값 제공.

### 2.4 스냅샷/리더보드
- `GoalSnapshot { challengeType:ChallengeType, goal:RecordGoal, seed:String, character:GameCharacter }`
- `LeaderboardEntry { rank:int, nickname:String, clearTime:Duration?, createdAt:DateTime }`

---

## 3) 게임ID 규칙/이웃
- **Daily**: `D-YYYYMMDD`, **Weekly**: `W-YYYY-W` (0패딩 없음, Supabase 저장된 ID 규칙).
- **호환연도 규칙**: `year = (day>15 && week==1) ? year+1 : year` (레거시 유지).
- **이웃 탐색**: Weekly는 해당 **월요일 anchor** ± 7일, Daily는 ± 1일.

---

## 4) 서비스 계약(요약)

### 4.1 Auth
```dart
abstract class AuthService {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<void> signInWithPassword(String email, String password);
  Future<void> signUpWithPassword(String email, String password);
  Future<void> signOut();
  Future<void> changeNickname(String nickname);
}
```
- **SupabaseAuthService**: 로그인 상태/프로필 하이드레이트, users 테이블에 **upsert**.

### 4.2 목표 조회
```dart
abstract class GoalReadService {
  Stream<GoalSnapshot?> current(ChallengeType challengeType);
  Future<GoalSnapshot?> byGameId(String gameId);
}
```
- **SupabaseGoalReadService**: `daily_challenges`/`weekly_challenges`에서 seed/boss/character → `GoalSnapshot`.

### 4.3 리더보드
```dart
abstract class LeaderboardService { Future<List<LeaderboardEntry>> fetchAll({required String gameId}); }
```
- **입력**: `D-YYYYMMDD | W-YYYY-W` → **challengeId 조회** → `functions: daily-record/{id} | weekly-record/{id}` GET
- **정렬**: `time(ms)` 오름차순 → `rank = index+1`.

### 4.4 게임ID/이웃
```dart
abstract class GameIndexService {
  Stream<String> currentGameId();
  Future<({String? prev, String? next})> neighbors(String id);
  Future<String> currentFor(ChallengeType challengeType);
}
```
- **DefaultGameIndexService**: ISO week 기반, “예전 규칙” 연도 보정.

### 4.5 세션/업로드
```dart
abstract class GameSessionService {
  Stream<Duration> elapsed();
  Future<void> start();
  Future<void> stop({required bool cleared});
}
```
- **GameSessionServiceImpl**: 프리셋 검증 → Recorder 모드 생성 → Isaac 런치 → 로그 팔로우 → 종료 시 Functions 업로드.

---

## 5) 프리셋 검증/Recorder 모드 생성
- **프리셋 검증**: `.env(RECORD_PRESET_URL)`에서 프리셋 JSON 다운로드 → 설치 모드(`env.getInstalledModsMap`)의 **활성 집합**이 **프리셋 허용 집합**의 부분집합인지 확인(**추가 모드 금지**).
- **Recorder 생성**: `.env(RECORDER_MOD_URL)` 템플릿 main.lua를 받아 **%DAILY\_\*% / %WEEKLY\_\*%** 자리표시자 치환 → `modsRoot\cartridge-recorder\{main.lua, metadata.xml}` 재생성.

**치환 키**
```
%DAILY_SEED%  %DAILY_BOSS%  %DAILY_CHARACTER%
%WEEKLY_SEED% %WEEKLY_BOSS% %WEEKLY_CHARACTER%
```

---

## 6) 로그 이벤트/스톱워치/업로드
- **소스**: `FileIsaacLogTail('\log.txt')` 메시지(topic, parts)
- **처리**:
    - `LOAD` → 프리셋 재검증(실패 시 UI에서 안내)
    - `RESET` → 스톱워치 초기화
    - `START (D|W, character, seed)` → DB seed 일치 시 스톱워치 시작 + `RecorderState{type,character,seed}`
    - `BOSS` → `isBossKilled=true`
    - `STAGE a.b` → `elapsedMs: "스테이지 a.b 입장"` 로그 축적
    - `END (D|W, ch, seed)` → **보스킬**이면 `{time,seed,character,data}`로 `functions.invoke('daily-record'| 'weekly-record')`

- **타이머**: 200ms 주기로 `Stopwatch.elapsed`를 스트림으로 방출.

---

## 7) 저장소/함수 계약

### 7.1 AuthRepository (Supabase)
```dart
fetchProfile(uid) -> {displayName?, isAdmin}
upsertDisplayName(uid, displayName)
```
- **users** 테이블: `id`, `email(표시명)`, `is_tester(관리자)`

### 7.2 LeaderboardRepository (Supabase)
```dart
findWeeklyChallengeId(year, week) -> String?
findDailyChallengeId(date) -> String?
fetchWeeklyRecords(challengeId) -> List<Map>
fetchDailyRecords(challengeId) -> List<Map>
```
- **Functions**: `weekly-record/{id}` / `daily-record/{id}` (GET), `weekly-record` / `daily-record` (POST 업로드)

---

## 8) 에러 매핑/내성
| 영역            | 코드/상황                    | 처리             |
|---------------|--------------------------|----------------|
| 프리셋 검증        | `invalid_mod_set`        | 런치 중단/다이얼로그 안내 |
| 챌린지 조회        | `no_challenge_available` | 시작 중단/안내       |
| 템플릿/프리셋 HTTP  | `http_error/status!=200` | 예외 → UI 안내     |
| 로그 파일         | `not_found/locked`       | 재시도/빈 스트림      |
| Functions 업로드 | `network_error`          | 재시도/토스트 안내     |
| 리더보드 조회       | `bad_game_id/empty`      | 빈 리스트/로그       |

---

## 9) 보안/UX/성능
- **사용자 트리거 우선**, 관리자 권한 불요, 네트워크/파일 I/O는 **예외 안전**; 실패는 가능하면 **부분 성공** 유지.
- 로그 파싱/디렉터리 작업은 **UI 차단 금지**(필요 시 Isolate), 스트림 구독 해제 시 자원 정리.

---

## 10) 테스트 케이스(AAA)
- “`W-YYYY-W`/`D-YYYYMMDD` **생성/이웃**이 규칙을 따른다”
- “일일/주간 **현재 목표**가 올바른 seed/캐릭터로 매핑된다”
- “리더보드가 **시간 오름차순**으로 정렬된다”
- “프리셋 검증이 **허용 외 모드**를 차단한다”
- “Recorder 모드가 **플레이스홀더 정확**히 치환된다”
- “`START/BOSS/END` 흐름에서 **업로드 조건**이 충족될 때만 전송된다”
- “로그 파일 부재/잠김에서 **내성 처리**한다”

---

## 11) 체크리스트
- [ ] `.env`의 `RECORDER_MOD_URL`, `RECORD_PRESET_URL` 설정 확인
- [ ] users/daily\_challenges/weekly\_challenges 테이블/함수 **권한/정책** 점검
- [ ] 스톱워치/타이머/스트림 **해제** 누수 방지
- [ ] 게임ID 파서가 **두 형식(D-YYYYMMDD, D-YYYY-MM-DD)** 모두 수용
- [ ] 지역화 키(AppLocalizations) 누락/미번역 점검
- [ ] 실패 경로에서 **친절한 안내(InfoBar/Toast)** 제공
