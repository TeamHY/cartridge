---
description: >
  Slot Machine 모듈의 도메인/서비스/컨트롤러/저장소 Interface과 동작 규칙을 정리한 개발 참고 문서입니다.
  정렬 보존, 트랜잭션, 재현성(RNG 주입), 단순·균등 스핀(비영속)을 기준으로 합니다.
globs: /lib/features/cartridge/slot_machine/**
alwaysApply: false
---

# Slot Machine

> 본 문서는 `features/cartridge/slot_machine` 구현의 **단일 기준(Single Source of Truth)** 입니다.

## 1) 도메인 스키마

### 1.1 `Slot`
| 필드      | 타입           | 필수 | 설명            |
|---------|--------------|:--:|---------------|
| `id`    | String       | ✅  | 슬롯 식별자        |
| `items` | List<String> | ✅  | 슬롯의 아이템 라벨 목록 |

- 아이템은 **문자열 라벨**만 가진다(가중치/활성/통계 없음).

---

## 2) SQLite 스키마

```sql
-- 슬롯 메타 (정렬 pos)
CREATE TABLE IF NOT EXISTS slots (
  id  TEXT PRIMARY KEY,
  pos INTEGER NOT NULL
);

-- 슬롯 아이템 (순서 position, 내용 content)
CREATE TABLE IF NOT EXISTS slot_items (
  slot_id  TEXT    NOT NULL,
  position INTEGER NOT NULL,
  content  TEXT    NOT NULL
);

-- 정렬 조회 최적화
CREATE INDEX IF NOT EXISTS idx_slots_pos ON slots(pos ASC);
CREATE INDEX IF NOT EXISTS idx_slot_items_slot_pos ON slot_items(slot_id, position ASC);
````

* **원자성**: `upsert`는 트랜잭션으로 `slots`·`slot_items`를 갱신.
* **정렬 보존**: `pos`는 `reorderByIds`로 갱신, `listAll()`은 `pos ASC`로 조회.

---

## 3) 저장소 Interface

```dart
abstract class ISlotMachineRepository {
  Future<List<Slot>> listAll();
  Future<Slot?> findById(String id);
  Future<void> upsert(Slot slot);
  Future<void> removeById(String id);
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true});
}
```

* `strict=true`일 때, `orderedIds`는 현재 슬롯 집합의 **순열**이어야 하며 위반 시 `ArgumentError`.

---

## 4) 서비스 규칙

### 4.1 Use cases

* 슬롯 좌/우 추가, 삭제
* 슬롯 아이템 일괄 교체, 단건 추가/수정/삭제
* 정렬 영속화
* 스핀(비영속): `(index, value)` 반환

### 4.2 규칙

* **빈 아이템**으로 교체하면 **해당 슬롯 삭제**
* 인덱스 범위 밖 업데이트/삭제는 **무시(변화 없음)**
* 스핀은 **균등 랜덤**(가중치 없음), 빈 슬롯은 `null` 반환
* RNG는 **주입(Random?) 가능** → 테스트에서 **결정적** 수행 가능

### 4.3 주요 시그니처

```dart
class SlotMachineService {
  Future<List<Slot>> listAll();
  Future<List<Slot>> createLeft({String defaultText = 'Item'});
  Future<List<Slot>> createRight({String defaultText = 'Item'});
  Future<List<Slot>> delete(String slotId);

  Future<List<Slot>> setItems(String slotId, List<String> items);
  Future<List<Slot>> addItem(String slotId, String text);
  Future<List<Slot>> updateItem(String slotId, int index, String text);
  Future<List<Slot>> removeItem(String slotId, int index);

  Future<void>       persistOrder(List<String> orderedIds, {bool strict = true});

  (int index, String value)? spinOne(Slot slot, {Random? rng});
  List<(int index, String value)?> spinAll(List<Slot> slots, {Random? rng});
}
```

---

## 5) 컨트롤러 상태/행동

* 타입: `AsyncNotifier<List<Slot>>`
* 책임:

    1. 초기 로드 및 새로고침(`listAll`)
    2. 모든 CRUD 호출을 **서비스에 위임**하고, **서비스가 반환한 최신 리스트**로 상태 갱신
    3. 오류는 `AsyncValue.guard`로 **AsyncError**에 래핑
* 프리젠테이션 보조 상태:

    * `spinAllTickProvider: StateProvider<int>` → 스핀 브로드캐스트(뷰 로직용)

---

## 6) UI 규칙

* `SlotMachinePage`

    * 중앙 정렬 + 좌/우 슬롯 추가 버튼, 가로 스크롤, 전체 스핀 버튼
* `SlotView`

    * `ListWheelScrollView` 기반, hover 시 컨트롤(스핀/편집/삭제)
    * `withAlpha` 기반 오버레이, AppRadius/Spacing/semantic colors 사용
* `SlotDialog`

    * 문자열 리스트 편집(Enter로 행 추가, 빈 행 Backspace 삭제, 멀티라인 붙여넣기 분해)
* `DesktopGrid`

    * 토큰 기반(breakpoints/spacing/radius), full-row 지원, 뷰포트/컨테이너 기준 선택 가능

---

## 7) 에러 정책

* 저장/정렬 실패: 저장소 예외 전파 → 컨트롤러에서 `AsyncError`로 노출
* 잘못된 정렬 요청(strict): `ArgumentError`
* 스핀: 빈 슬롯 → `null` (예외 아님)

---

## 8) 성능/동시성

* 저장 경로는 DB 트랜잭션으로 최소화
* 조회는 인덱스(`pos`, `slot_id, position`) 활용
* 스핀은 계산만 수행(I/O 없음)

---

## 9) 테스트 케이스(현행 코드 기준)

* **Repository (SQLite FFI, 인메모리)**

    * `upsert` 신규/교체(pos 보존)
    * `listAll`/`findById` 정확도
    * `reorderByIds(strict)` 순열 검증/예외
    * `removeById` 삭제
* **Service (메모리 FakeRepo)**

    * 좌/우 추가 → 위치 확인
    * `setItems([])` → 슬롯 삭제
    * 업데이트 경계(음수/초과 인덱스) 무시
    * `removeItem` 마지막 제거 시 슬롯 삭제
    * `persistOrder` 위임(strict=false)
    * `spinOne/All` 결정적 RNG·빈 슬롯 null
* **Controller (mocktail)**

    * 초기 로드 → `AsyncData`
    * 성공/실패 전이(AsyncValue.guard) 검증
    * 모든 CRUD 후 **최신 리스트**로 갱신
* **Widget/Golden**

    * 다이얼로그: `showDialog(useRootNavigator:false)`, bounded pump
    * Clipboard mock + `Actions.invoke(PasteTextIntent)` 경로
    * Golden: NavigationView/ScaffoldPage 배제, 셀 높이 확보, 폰트 로드

---

## 10) 체크리스트

* [x] RNG 주입 가능(테스트 재현성)
* [x] 빈 아이템 → 슬롯 삭제 규칙
* [x] 정렬 보존(pos)/엄격 검증(strict)
* [x] 컨트롤러 모든 액션 후 최신 리스트로 상태 갱신
* [x] 테마 토큰(AppRadius/Spacing/semantic) 적용
* [x] 안정 테스트 패턴(Clipboard mock, bounded pump, dialog overlay)
