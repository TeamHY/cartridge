---
description: >
  Isaac Mod 모듈의 메타 파싱·설치 탐지·활성/비활성·즐겨찾기·뷰 투영 규칙을 정의한 개발 참고 문서입니다.
  metadata.xml 스키마, disable.it 정책, Installed/Entry/View 스키마, 서비스/리포지토리 계약과
  테스트/체크리스트를 포함합니다.
globs: /lib/features/isaac/mod/*
alwaysApply: false
---

# Isaac Mod — MDC

> AI/개발자가 `feature/isaac/mod`를 구현/확장할 때 따르는 **단일 기준**입니다. (Windows 전용)

## 1) 모듈 맵
- `mod_metadata.dart` — **Metadata**: `metadata.xml` → `ModMetadata`.
- `installed_mod.dart` — **Installed**: 메타 + 설치상태(disabled/경로/폴더명 파생).
- `mod_entry.dart` — **Entry**: 사용자 의사(직접 enabled/favorite) 영구 저장 레코드.
- `mod_view.dart` — **View**: 화면 투영 데이터(표시명/버전/상태/링크/태그 등).
- `mod_view_extensions.dart` — **View 확장**: 워크샵 URL, 텍스트 이니셜.
- `mods_repository.dart` — **Repository**: 디스크 스캔 + 파싱 + Installed 생성.
- `mods_service.dart` — **Service**: 스캔/Entry 병합/토글/정렬/뷰 프로젝션.
- `mod_view_projector.dart` — **Projector**: Installed×Entry→View 변환 규칙.
- `mod_visibility.dart` — **Enum**: `ModVisibility` 파싱.
- `mod_title_cell.dart`, `mod_row_status.dart`, `seed_mode.dart` — UI/상태 보조.

---

## 2) 스키마 — `ModMetadata` (metadata.xml)
**출처**: 각 모드 폴더의 `metadata.xml`.

| 필드           | 타입              | 필수 | 설명                              |
|--------------|-----------------|:--:|---------------------------------|
| `id`         | `String`        | ✅  | **Workshop ID** (비어 있으면 무시 대상). |
| `name`       | `String`        | ⭕  | 표시 이름(비어 있을 수 있음).              |
| `directory`  | `String`        | ⭕  | 런타임 디렉터리명(폴더 명의 베이스).           |
| `version`    | `String`        | ⭕  | 버전 문자열.                         |
| `visibility` | `ModVisibility` | ✅  | 공개 범위.                          |
| `tags`       | `List<String>`  | ✅  | `<tag id="..."/>`의 `id` 수집.     |

**파서 규칙**
- 태그는 **소문자** 기준(`<id>`, `<name>`, `<directory>`, `<version>`, `<visibility>`, `<tag id=".."/>`).
- `<tag>`는 `id` 속성만 채택, 본문 텍스트 무시.
- 누락 태그는 **빈 문자열**로 처리(visibility는 기본값→enum 파서에서 결정).

---

## 3) 스키마 — `InstalledMod`
| 필드            | 타입            | 필수 | 설명                    |
|---------------|---------------|:--:|-----------------------|
| `metadata`    | `ModMetadata` | ✅  | 메타데이터.                |
| `disabled`    | `bool`        | ✅  | `disable.it` 존재 여부.   |
| `installPath` | `String`      | ⭕  | 절대 경로(옵셔널, 빈 문자열 가능). |

**파생 필드/메서드**
- `version`, `directory`, `visibility`, `tags` → `metadata` 위임.
- `isEnabled = !disabled`, `isDisabled = disabled`.
- `folderName = "${metadata.directory}${metadata.id.isNotEmpty ? "_${metadata.id}" : ""}"`.

**정책**
- 비활성화는 **폴더 내 파일** `disable.it` 존재로 판단(내용 무관, 존재만으로 true).
- 설치 폴더 스캔 실패는 건너뛰되 로그로 남김(소프트 실패).

---

## 4) 스키마 — `ModEntry` (영구 저장)
> **사용자 의사**만 저장; 설치 상태는 저장하지 않습니다.

| 필드             | 타입          | 필수 | 설명                                              |
|----------------|-------------|:--:|-------------------------------------------------|
| `key`          | `String`    | ✅  | 실제 폴더명(= `InstalledMod.folderName`) — 공백 금지.    |
| `workshopId`   | `String?`   | ⭕  | 워크샵 ID(있으면 보관).                                 |
| `workshopName` | `String?`   | ⭕  | 표시 라벨(옵션).                                      |
| `enabled`      | `bool?`     | ⭕  | **직접 의사**: `true=ON`/`false=강제 OFF`/`null=미지정`. |
| `favorite`     | `bool`      | ✅  | 즐겨찾기(기본 false).                                 |
| `updatedAt`    | `DateTime?` | ⭕  | 마지막 갱신 시각.                                      |

**의미**
- 실제 활성 여부는 `InstalledMod.disabled`와 결합해 판단(Entry는 의사만).

---

## 5) 스키마 — `ModView` (화면 투영)
> 프로젝트의 `mod_view.dart`를 기준으로 **권장 필드 집합**.

| 필드            | 타입            | 설명                                            |
|---------------|---------------|-----------------------------------------------|
| `key`         | String        | 폴더 키(=Installed.folderName).                  |
| `displayName` | String        | 우선순위: `workshopName ?? metadata.name ?? key`. |
| `modId`       | String        | Workshop ID(없으면 빈 문자열).                       |
| `version`     | String        | 표시 버전.                                        |
| `enabled`     | bool          | 실제 활성 상태(Installed 기준).                       |
| `favorite`    | bool          | 즐겨찾기.                                         |
| `visibility`  | ModVisibility | 공개 범위.                                        |
| `tags`        | List<String>  | 태그.                                           |
| `installPath` | String        | 경로(표시/툴팁용).                                   |
| `statusLabel` | String        | `mod_row_status.dart` 규칙에 따라 생성.              |

**UI 확장**
- `workshopUrl`: `modId`가 있으면 `SteamUrls.workshopItem(modId)`.
- `displayInitial(fallback:'M')`: `displayName`에서 텍스트 이니셜 추출.

---

## 6) 리포지토리/서비스 계약(의사 코드)

### 6.1 Repository
```dart
abstract class ModsRepository {
  Future<List<InstalledMod>> scanInstalled();        // 디스크 → Installed 목록
  Future<void> setDisabled(String key, bool v);      // disable.it 생성/삭제
}
```

### 6.2 Service
```dart
abstract class ModsService {
  Future<List<InstalledMod>> scan();                 // scanInstalled 위임 + 정합성 점검
  Future<List<ModView>> listViews();                 // Installed × Entry → View
  Future<void> toggleEnabled(String key, bool on);   // disable.it 토글 + Entry.enabled 갱신
  Future<void> setFavorite(String key, bool on);     // Entry.favorite 갱신
}
```

**투영 규칙(요약)**
- `displayName`: `Entry.workshopName ?? Metadata.name ?? key`
- `enabled`: `!Installed.disabled` (Entry.enabled가 false면 UI에 “강제 OFF” 배지)
- 정렬: 즐겨찾기 우선 → enabled 우선 → 이름 오름차순(권장)

---

## 7) 동작 규칙/알고리즘

### 7.1 스캔
1) 모드 루트 디렉터리들을 열거
2) 각 폴더에서 `metadata.xml` 읽기 → `ModMetadata.fromXmlString()`
3) `disable.it` 존재 여부 확인 → `InstalledMod` 구성
4) 폴더명은 `InstalledMod.folderName` 규칙으로 결정

### 7.2 토글
- **활성 ON**: `disable.it` 삭제(존재하면)
- **활성 OFF**: `disable.it` 생성(빈 파일)
- 예외는 사용자에게 InfoBar로 안내하고 재시도 허용

---

## 8) 워크샵 링크/표시
- 링크 생성: `SteamUrls.workshopItem(modId)`
- `mod_view_extensions.dart`의 `workshopUrl` 사용(없으면 null 처리)
- 이니셜 아이콘: `displayInitial()`로 텍스트 기반 아바타 제공

---

## 9) 에러 매핑
- 파싱: `metadata_parse_error` / 파일: `io_error` / 권한: `permission_denied`
- 토글: `toggle_failed`(원인 포함) / 스캔: `scan_partial`(일부 실패 허용, 로그 남김)

---

## 10) 테스트 케이스
- “`metadata.xml` **파싱**이 누락 태그에서도 빈 문자열로 동작한다”
- “`folderName`이 `directory + "_" + id` 규칙을 따른다(id 없으면 directory)”
- “`disable.it` 생성/삭제로 **활성 상태**가 반영된다”
- “Entry 병합 시 `workshopName`/`enabled`/`favorite`가 **정확히 투영**된다”
- “`workshopUrl`이 `modId` 없을 때 **null**을 반환한다”
- “이니셜 표시가 **문자 범주**에 상관없이 한 글자 생성된다”

---

## 11) 체크리스트
- [ ] 디렉터리/파일 접근은 **예외 안전**(try/catch) + 소프트 실패 허용
- [ ] `metadata.xml` 인코딩/개행/공백 변형 허용(튼튼한 파서)
- [ ] `disable.it` 쓰기 시 **동시 접근** 고려(잠김/권한)
- [ ] Entry 저장소와 키(`folderName`)의 **동등성** 유지
- [ ] View 정렬/라벨 규칙을 **테스트로 고정**
