<h1 align="center">
  <br>
  <a href="https://github.com/TeamHY/cartridge"><img src="/assets/images/Cartridge_icon_200_200.png" alt="cartridge" width="200"></a>
  <br>
  Cartridge — Developer Setup
  <br>
</h1>

<h4 align="center">Flutter 기반의 Isaac 프리셋 매니저 데스크톱 앱 (Windows) · 개발 환경 초기 세팅 가이드</h4>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows-blue" alt="Platform">
  <img src="https://img.shields.io/badge/runtime-Flutter%20SDK-02569B" alt="Flutter">
  <img src="https://img.shields.io/badge/docs-Developer%20Setup-success" alt="Docs">
</p>

---

<a id="개발자-빠른-시작"></a>

## 개발자 빠른 시작 (TL;DR)

```bash
# 0) (최초 1회) Windows 데스크톱 타깃 활성화
flutter config --enable-windows-desktop

# 1) 저장소 클론
git clone https://github.com/TeamHY/cartridge.git
cd cartridge

# 2) 패키지 의존성 설치
flutter pub get

# 2-1) (최초/의존성 또는 모델 변경 시) 코드 생성
# Freezed/JsonSerializable 기반 모델 생성 파일(*.freezed.dart, *.g.dart) 생성
dart run build_runner build --delete-conflicting-outputs
# 또는 자동 감지 모드:
# dart run build_runner watch --delete-conflicting-outputs

# 3) 환경 변수 파일 생성 (.env)
#   - 프로젝트 관리자에게 .env 내용을 요청하여
#     프로젝트 루트에 .env 파일로 저장

# 4) 앱 실행 (엔트리포인트: lib/main.dart)
flutter run -d windows -t lib/main.dart
```

---

<a id="요구사항"></a>

## ✅ 요구사항

* **OS**: Windows 10/11 (x64)
* **필수 도구**: Git, Flutter SDK
* **권장**: Visual Studio의 **Desktop development with C++** 워크로드 (Windows 데스크톱 빌드 도구)
* 환경 점검: `flutter doctor`

```bash
flutter doctor
```

---

<a id="의존성-설치"></a>

## 의존성 설치

클론 직후 의존성 패키지를 내려받습니다.

```bash
flutter pub get
```

> **참고**: 이 프로젝트는 데이터 모델을 **Freezed/JsonSerializable**로 생성합니다.
> 의존성 설치 후 한 번은 반드시 [코드 생성](#freezed-setup)을 실행하세요.

---

<a id="env-설정"></a>

## 🔐 환경 변수 파일 (.env) 설정

* **위치**: 프로젝트 **루트**
* **내용**: 프로젝트 관리자에게 요청하여 전달받은 값을 그대로 입력

---

<a id="윈도우-실행"></a>

## 💻 Windows에서 실행

엔트리포인트는 `lib/main.dart` 입니다.

```bash
flutter run -d windows -t lib/main.dart
```

VS Code를 사용할 경우 **Run and Debug**에서 디바이스를 **Windows**로 선택한 뒤 `lib/main.dart`로 실행해도 됩니다.

---

<a id="freezed-setup"></a>

## 🧩 모델 코드 생성(Freezed / JsonSerializable)

Cartridge는 모델을 **Freezed**(불변/union) + **JsonSerializable**(fromJson/toJson)로 관리합니다.
생성 파일(`*.freezed.dart`, `*.g.dart`)은 저장소에 커밋하지 않고 **로컬/CI에서 생성**합니다.

### 실행 방법

* 최초 클론 후 1회, 그리고 **모델 파일/애노테이션/의존성 변경 시** 실행:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
* 개발 중 자동 감지 모드:

  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```

### 최소 예시

```dart
// 예: lib/features/slot_machine/domain/slot_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'slot_item.freezed.dart';
part 'slot_item.g.dart';

@freezed
class SlotItem with _$SlotItem {
  const factory SlotItem({
    required String id,
    required String name,
  }) = _SlotItem;

  factory SlotItem.fromJson(Map<String, dynamic> json) => _$SlotItemFromJson(json);
}
```

### 자주 발생하는 오류와 해결

* **The part '\*.freezed.dart' was not found**
  → 코드 생성 미실행. 위의 `build_runner build` 실행.
* **Conflicting outputs**
  → 생성 파일 충돌. `--delete-conflicting-outputs` 옵션으로 재생성.
* **fromJson/toJson 심볼이 없음**
  → `part 'xxx.g.dart';` 누락 또는 `json_serializable` 미생성. 위 명령 재실행.
