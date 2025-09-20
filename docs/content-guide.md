<h1 align="center">
  <br>
  <a href="https://github.com/TeamHY/cartridge"><img src="/assets/images/Cartridge_icon_200_200.png" alt="cartridge" width="200"></a>
  <br>
  Cartridge — Content Author Guide
  <br>
</h1>

<h4 align="center">쉽게 컨텐츠를 추가할 수 있는 가이드 (목록은 YAML, 상세는 Markdown)</h4>

---

## 빠른 시작 (TL;DR)

1. 이미지(썸네일) 준비 → `assets/content/` 폴더에 넣기
2. 상세페이지라면 마크다운 작성 → `assets/content/`에 넣기
3. 목록에 항목 추가 → `assets/content/index.yaml` 한 블록 추가
4. 앱을 다시 실행하면 목록에 노출됩니다

---

## 파일 위치

```
assets/content/
  index.yaml                 # ← 컨텐츠 목록 (필수)
  {컨텐츠 명}.md              # ← type: detail 인 경우 (선택)
  {컨텐츠 섬네일}.png         # ← 썸네일(선택)
```

> 폴더/파일명은 **영문, 숫자, 하이픈(-)** 권장 (예: `battle`, `record`, `info-isaacguru`)

---

## 1) 목록 작성 — `index.yaml`

### 항목 종류 (type)

* `detail` : **마크다운(detail.md)** 상세 페이지로 연결
* `link` : **외부 링크**로 바로 열기
* `custom` : 앱이 제공하는 **특수 페이지**로 연결 (직접 개발해서 추가할때)

### 카테고리 (category)

* `hyZone` : 아이작 오헌영/커뮤니티 관련
* `info` : 정보/도움말 등

### 템플릿 (복사해서 채우기)

```yaml
- id: your-id-here
  category: hyZone            # hyZone | info
  type: detail                # custom | detail | link
  title: { ko: 한글 제목, en: English Title }
  description:
    ko: 간단한 설명을 적어 주세요
    en: Write a short description
  image: assets/content/your-id-here/thumb.png

  # type == detail 인 경우
  markdown: assets/content/your-id-here/detail.md

  # type == link 인 경우 (둘 중 하나)
  # url: https://example.com
  # url: { ko: https://ko.example.com, en: https://en.example.com }
```

### 실제 예시

```yaml
- id: battle
  category: hyZone
  type: detail
  title: { ko: 대결모드, en: Battle Mode }
  description:
    ko: 오헌영과 아이작 대결해 보세요
    en: Go head-to-head with Hy in Isaac.
  image: assets/content/battle/thumb.png
  markdown: assets/content/battle/detail.md

- id: info-isaacguru
  category: info
  type: link
  title: { ko: Isaac Guru Laboratory, en: Isaac Guru Laboratory }
  description:
    ko: 아이템 정보를 빠르게 찾아보세요
    en: Look up item info fast.
  image: assets/content/info/isaacguru.jpg
  url: https://isaacguru.com/

- id: record
  category: hyZone
  type: custom
  title: { ko: 시참대회, en: Record Showdown }
  description:
    ko: 오헌영의 아이작 기록 경쟁
    en: Hy's Isaac record challenge.
  image: assets/content/record/thumb.png
```

> **주의**
>
> * 들여쓰기는 **스페이스 2칸** (탭 X)
> * `:` 뒤에는 **반드시 공백** 한 칸
> * 큰따옴표/작은따옴표는 보통 필요 없습니다(특수문자 많을 때만 사용)

---

## 2) 상세 작성 — Markdown (type: detail)

한 파일에 한국어/영어를 함께 적고, **언어 블록**으로 감싸 주세요.

```markdown
<!-- lang:ko -->
# 대결모드
친구와 실력 대결을 즐겨보세요.
- 준비물: 컨트롤러 2개
- 추천: 씨드 OFF
<!-- /lang -->

<!-- lang:en -->
# Battle Mode
Face off with your friend.
- Requirements: 2 controllers
- Recommended: Seed OFF
<!-- /lang -->
```

* 블록이 없으면 **파일 전체**가 그대로 보여집니다(실수해도 안전).
* 이미지/링크도 일반 Markdown 문법 그대로 사용 가능합니다.

---

## 3) 썸네일/이미지

* 썸네일은 `image:` 경로로 연결됩니다 (권장 16:9, 320×180 이상).
* 이미지는 `assets/content/<컨텐츠 섬네일>.png` 같은 경로로 두기.

---

## 4) 체크리스트

* [ ] `id`는 고유/영문-소문자-하이픈
* [ ] `type`은 `custom`/`detail`/`link` 중 하나
* [ ] `title`/`description`에 ko/en 중 **최소 한 언어**는 채웠는가
* [ ] `image` 경로가 맞는가 (철자, 확장자)
* [ ] `detail`이면 `markdown` 경로 존재하는가
* [ ] `link`이면 `url`이 문자열 또는 ko/en 맵인가
* [ ] YAML 문법 오류 없는가 (공백/들여쓰기)

---

## 5) 자주 묻는 질문

**Q. 영어가 아직 없어요. 비워도 되나요?**
네. 한쪽 언어만 있어도 동작합니다. 나중에 영어를 채워 주세요.

**Q. 링크가 언어별로 달라요.**
`url: { ko: ..., en: ... }`처럼 언어별로 적어 주세요.

**Q. Markdown 미리보기는 어떻게 해요?**
일반 문서 편집기(예: VS Code 등)에서 미리 볼 수 있어요. 앱에선 자동으로 현재 언어만 표시됩니다.

**Q. 추가했는데 앱에 안 보여요.**
경로 오타(대소문자, 확장자)를 먼저 확인해 주세요. 문제가 지속되면 관리자에게 문의하세요.

**Q. 특수 페이지(예: 시참대회)로 보내려면?**
`type: custom`로 지정하고 페이지를 개발한 뒤 `content_page.dart`에 분기점을 추가해주세요.

---

## 7) 예시로 한 번에 만들기

1. 썸네일 넣기

    ```
    assets/content/my-thumb.png
    ```

2. 상세 작성

    ```
    assets/content/my-detail.md
    ```

    (위의 lang 블록 템플릿을 복사해 내용을 채워 넣으세요.)

3. `index.yaml`에 블록 추가

    ```yaml
    - id: my-content
      category: hyZone
      type: detail
      title: { ko: 나의 컨텐츠, en: My Content }
      description:
        ko: 새롭게 컨텐츠를 추가해보세요.
        en: Add a new content.
      image: assets/content/my-thumb.png
      markdown: assets/content/my-detail.md
    ```

    완료입니다. 앱을 다시 실행하면 목록에 나타납니다.
