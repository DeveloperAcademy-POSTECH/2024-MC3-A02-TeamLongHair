# 캔버스 노드 리디자인 — 브라우저 탭(B안: 탭 바 통합) 설계

**날짜:** 2026-07-20
**상태:** 승인 대기(사용자 검토) — 시각 시안은 목업으로 승인됨

## 배경 / 목적

현재 캔버스 노드(`LinkNode`)는 얇은 색 테두리 안에 작은 파비콘 + 제목 + 태그가 좌상단에 몰려 있고 카드의 절반 이상이 비어 있어 밋밋하다. 앱은 이미 파비콘·도메인·설명(pageDescription)을 저장하는데 노드는 이를 거의 쓰지 않는다.

목표는 **각 노드를 "브라우저 탭"으로 도식화**하는 것이다. 신호등(빨·노·초)은 창(window) 단위 요소라 브라우저에 한 세트뿐이므로 노드마다 넣지 않는다. 대신 반복 요소인 **탭**을 노드의 형태로 삼는다: 상단에 **탭 바(탭 = 파비콘 + 제목 + ×)**, 그 아래 **주소창(도메인)**, 그 아래 **본문(설명 + 태그)**. 사용자가 고른 색(IconColor)은 **활성 탭 표시선**으로만 절제해서 드러낸다.

(목업에서 A/B/C 시안 중 **B안: 탭 바 통합**이 선택됨.)

## 목표 / 비목표

**목표**
- `LinkNode`를 "탭 바 + 주소창 + 본문" 카드로 재구성.
- 탭 바: 파비콘 + 제목(displayTitle) + ×(장식), 탭 상단에 IconColor **활성 표시선**.
- 주소창: 자물쇠/글로브 글리프 + 도메인(호스트, `www.` 제거). 도메인 없으면 주소창 숨김.
- 본문: 설명(pageDescription, 최대 2줄, 비면 숨김) + 태그 칩(있으면).
- 기존 선택(파랑 글로우)·드롭 대상(보라 글로우 + 확대) 강조 유지.
- 노드 크기 고정(244×118) — TreeLayout/캔버스 히트테스트 불변.
- 도메인 추출은 프레임워크 의존 없는 순수 함수로 두어 swiftc 테스트.

**비목표(YAGNI)**
- × 를 실제 삭제로 연결(오클릭 위험 — 삭제는 기존 우클릭 메뉴 유지).
- 가변 노드 높이(TreeLayout 수정), 본문 썸네일, 탭 돌출(A안)·알약(C안) 형태.
- 파비콘 캐싱/데이터 구조 변경(기존 `faviconData` 읽기만).

## 컴포넌트 상세

### 1. 순수 도메인 헬퍼 (`Utils/LinkMetadataParsing.swift` 수정 + `Model/LinkModel.swift` 확장)

`LinkMetadataParsing`(이미 Foundation-only, swiftc 테스트 대상)에 추가:

```swift
/// URL 문자열에서 표시용 호스트를 뽑는다. "www." 접두는 제거. host가 없으면 nil.
static func displayHost(fromURLString raw: String) -> String? {
    guard let url = normalizedURL(from: raw), var host = url.host else { return nil }
    if host.hasPrefix("www.") { host.removeFirst(4) }
    return host.isEmpty ? nil : host
}
```

`LinkModel.swift`(기존 `LinkDetail.displayTitle` 확장 옆)에 추가:

```swift
extension LinkDetail {
    /// 주소창 표시용 도메인. 없으면 빈 문자열.
    var displayDomain: String {
        LinkMetadataParsing.displayHost(fromURLString: URL) ?? ""
    }
}
```

### 2. LinkNode 재구성 (`Project/Page/Canvas/LinkNode.swift` 재작성)

고정 크기 244×118를 채우는 탭 카드. 기존 `sizeOfNode` 파라미터는 유지하고 스케일 `let s = sizeOfNode / 244`를 핵심 치수에 적용(현재 항상 기본값이라 s=1; API 호환 유지).

**구조(VStack, spacing 0):**

1. **탭 바** (상단, 높이 ~32·s):
   - 배경: 옅은 중립색(예 `.gray050`) — 탭이 놓인 "탭 바".
   - 그 위에 **탭 한 개**: 파비콘 + 제목 + ×.
     - 파비콘: `faviconData → NSImage`(`.aspectRatio(.fit)`), 실패 시 `globe`(SF Symbol, `.foregroundStyle(.secondary)`).
     - 제목: `link.detail.displayTitle`, `.system(size: 14·s, weight: .semibold)`, `lineLimit(1)`, truncation tail.
     - ×: `Image(systemName: "xmark")` 작게(`.secondary`, 장식 — 탭 존재만으로 클릭 동작 없음).
     - 탭 배경: 카드 표면색(`.bgPrimary`), 상단 모서리 라운드.
     - **활성 표시선**: 탭 상단에 두께 ~2.5·s 의 `link.detail.color.returnColor()` 막대(사용자 색).
2. **주소창** (높이 ~26·s):
   - pill(배경 `.bgSecondary` 또는 `.gray050`, 라운드): 자물쇠/글로브 글리프(`.secondary`) + 도메인(`displayDomain`, `.system(size: 11·s)`, `.secondary`, `lineLimit(1)`).
   - `displayDomain`이 빈 문자열이면 주소창 전체 숨김.
3. **본문** (남은 공간, 상단 정렬):
   - 설명: `link.detail.pageDescription`, `.system(size: 11·s)`, `.secondary`, `lineLimit(2)`, 비면 숨김.
   - 태그: 있으면 1줄 칩(`ForEach(tags)`), 채운 스타일(`.gray050` 배경 + `.secondary` 텍스트). 공간 부족 시 클립.

**카드 컨테이너:**
- `.background(.bgPrimary)`, `RoundedRectangle(cornerRadius: 11·s)`로 `.clipShape`, 얇은 중립 테두리(`.gray100` 등, 색은 이제 활성 표시선이 담당), 기존과 유사한 부드러운 그림자.
- **선택/드롭 오버레이는 기존 로직 유지**: 선택 → `.blue400` 글로우 테두리 + 그림자; 드롭 대상 → `.purple400` 글로우 + `scaleEffect(1.04)`; `.animation(.easeOut(0.12), value:)` 유지.

**높이 예산(244×118):** 탭 바 ~32 + 주소창 ~26 + 본문 ~60. 설명 2줄 + 태그가 모두 있으면 빡빡하므로 본문은 상단 정렬 + 클립으로 우아하게 처리(제목·주소·설명이 우선 보이고 태그가 넘치면 잘림).

### 3. 색의 역할

IconColor는 **탭 활성 표시선(작은 막대)** 에서만 드러난다. 카드 테두리·툴바는 중립색이라 캔버스에 노드가 많아도 무지개가 되지 않는다. 색 변화는 실제 파비콘이 자연스럽게 만든다. 선택/드롭 강조 색(파랑/보라)은 이와 분리된 상태 신호.

## 데이터 흐름

`CanvasContentView`가 각 링크에 대해 `LinkNode(link:isSelected:isDropTarget:)`를 기존과 동일한 시그니처로 렌더한다(캔버스 코드 변경 없음). `LinkNode`가 `link.detail`에서 favicon/displayTitle/displayDomain/pageDescription/tags/color를 읽어 탭 카드로 그린다.

## 오류 처리

- 파비콘 데이터 디코드 실패 → `globe` 폴백.
- 도메인 못 구함(스킴/호스트 없음, 로컬 메모 등) → 주소창 숨김(빈 pill 안 보임).
- 설명 없음 → 본문 설명 숨김.
- 제목 빈 문자열 → 기존 `displayTitle` 폴백(호스트/URL).
- 텍스트 오버플로우 → 말줄임/클립.

## 테스트

**순수 로직(swiftc, `scripts/run_canvas_tests.sh` 확장)**
- `LinkMetadataParsing.displayHost(fromURLString:)`:
  - `"https://www.developer.apple.com/swift"` → `"developer.apple.com"`.
  - `"https://youtube.com"` → `"youtube.com"`.
  - `"developer.apple.com/x"`(스킴 없음, normalizedURL이 https 보정) → `"developer.apple.com"`.
  - `""` → `nil`.
  - `"   "`(공백만) → `nil`.
  - `"no scheme with spaces"`(normalizedURL이 nil 반환하는 무효 입력) → `nil`.

**수동 QA(SwiftUI/이미지 — swiftc 불가)**
- 탭 바(파비콘+제목+×) + 주소창(도메인) + 본문(설명/태그)이 노드에 표시.
- 활성 표시선이 IconColor로, 카드/툴바는 중립.
- 파비콘 있는/없는(globe) 노드, 도메인 없는 노드(주소창 숨김), 설명 없는 노드.
- 선택(파랑 글로우)·드롭 대상(보라 글로우+확대) 기존과 동일.
- 캔버스 트리에서 여러 노드가 "탭"으로 읽히고 색이 과하지 않은지.
- 라이트/다크 대비.

## 파일 요약

| 파일 | 변경 |
|---|---|
| `Utils/LinkMetadataParsing.swift` | 수정 — `displayHost(fromURLString:)` 추가(순수, 테스트) |
| `Model/LinkModel.swift` | 수정 — `LinkDetail.displayDomain` 확장 |
| `Project/Page/Canvas/LinkNode.swift` | 재작성 — 탭 바 + 주소창 + 본문 카드, 선택/드롭 오버레이 유지 |
| `scripts/run_canvas_tests.sh`, `CanvasLogicTests/main.swift` | 확장 — `displayHost` 테스트 |

**엔타이틀먼트/스키마/CanvasMetrics 변경 없음.** 노드 크기 고정으로 캔버스 히트테스트·TreeLayout 불변.
