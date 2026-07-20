# 노드 브라우저 탭 리디자인 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 캔버스 노드를 "브라우저 탭"(탭 바 + 주소창 + 본문) 카드로 재구성하고, 색은 탭 활성 표시선으로만 절제한다.

**Architecture:** 순수 도메인 추출(`displayHost`)을 swiftc로 테스트하고, `LinkNode`를 탭 바(파비콘+제목+×) / 주소창(도메인) / 본문(설명+태그) 구조로 재작성한다. 노드 크기는 244×118 고정이라 캔버스/TreeLayout은 건드리지 않는다.

**Tech Stack:** macOS 14+, SwiftUI(UnevenRoundedRectangle), SwiftData, AppKit(NSImage), swiftc 기반 순수 로직 테스트.

## Global Constraints

- 각 노드 = 하나의 탭. 신호등(창 단위)은 넣지 않는다.
- 탭 바: 파비콘 + 제목(`displayTitle`) + ×(장식, 클릭 동작 없음). 삭제는 기존 우클릭 메뉴 유지.
- 색(IconColor, `link.detail.color.returnColor()`)은 **탭 활성 표시선(얇은 막대)** 에서만 드러낸다. 카드 테두리·탭 바는 중립색.
- 주소창: 도메인(`www.` 제거). 도메인이 없으면 주소창 숨김.
- 본문: 설명(`pageDescription`, 최대 2줄, 비면 숨김) + 태그 칩(있으면).
- 기존 선택(파랑 글로우)·드롭 대상(보라 글로우 + `scaleEffect(1.04)`) 강조 유지.
- 노드 크기 고정 244×118 — `CanvasMetrics`/TreeLayout/히트테스트 변경 없음.
- 순수 로직(`displayHost`)은 프레임워크 의존 없는 파일(`LinkMetadataParsing.swift`)에 두어 `scripts/run_canvas_tests.sh`(swiftc)로 테스트.
- 스키마/엔타이틀먼트 변경 없음(기존 `faviconData`/`URL` 읽기만).
- 앱 빌드 검증: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build` → `** BUILD SUCCEEDED **`.

---

## 파일 구조

**수정만 (신규 파일 없음 → xcodeproj 등록 불필요)**
- `TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift` — `displayHost(fromURLString:)` 추가(순수, 테스트)
- `TeamLongHair/TeamLongHair/Model/LinkModel.swift` — `LinkDetail.displayDomain` 확장
- `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` — 탭 카드로 재작성
- `CanvasLogicTests/main.swift` — `displayHost` 테스트

---

### Task 1: 순수 도메인 헬퍼 displayHost + displayDomain (TDD)

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift` (enum 내부, `normalizedURL` 아래에 정적 함수 추가)
- Modify: `TeamLongHair/TeamLongHair/Model/LinkModel.swift` (파일 끝, `extension LinkDetail { var displayTitle ... }` 옆/아래에 `displayDomain` 추가)
- Test: `CanvasLogicTests/main.swift` (파일 끝 `if failures > 0` 직전에 케이스 추가)

**Interfaces:**
- Consumes: 기존 `LinkMetadataParsing.normalizedURL(from:) -> URL?`.
- Produces: `LinkMetadataParsing.displayHost(fromURLString:) -> String?`, `LinkDetail.displayDomain: String`.

- [ ] **Step 1: 테스트 추가 (실패 확인용)**

`CanvasLogicTests/main.swift`의 맨 끝, `if failures > 0 { ... }` 줄 **바로 위**에 추가한다:

```swift
// MARK: - displayHost tests
expect(LinkMetadataParsing.displayHost(fromURLString: "https://www.developer.apple.com/swift") == "developer.apple.com",
       "www. 접두 제거")
expect(LinkMetadataParsing.displayHost(fromURLString: "https://youtube.com") == "youtube.com",
       "일반 호스트")
expect(LinkMetadataParsing.displayHost(fromURLString: "developer.apple.com/x") == "developer.apple.com",
       "스킴 없으면 normalizedURL이 https 보정 후 호스트 추출")
expect(LinkMetadataParsing.displayHost(fromURLString: "") == nil, "빈 문자열 → nil")
expect(LinkMetadataParsing.displayHost(fromURLString: "   ") == nil, "공백만 → nil")
expect(LinkMetadataParsing.displayHost(fromURLString: "no scheme with spaces") == nil, "무효 입력 → nil")
```

- [ ] **Step 2: 테스트 실행 → 컴파일 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: FAIL — `error: type 'LinkMetadataParsing' has no member 'displayHost'`

- [ ] **Step 3: displayHost 구현**

`TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift`의 `normalizedURL(from:)` 정적 함수 **바로 아래**(같은 `enum LinkMetadataParsing` 내부)에 추가:

```swift
    /// URL 문자열에서 표시용 호스트를 뽑는다. "www." 접두는 제거. host가 없으면 nil.
    static func displayHost(fromURLString raw: String) -> String? {
        guard let url = normalizedURL(from: raw), var host = url.host else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return host.isEmpty ? nil : host
    }
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: PASS — 마지막 줄 `ALL TESTS PASSED`

- [ ] **Step 5: LinkDetail.displayDomain 추가**

`TeamLongHair/TeamLongHair/Model/LinkModel.swift` 파일 끝의 `extension LinkDetail { ... }` 안(기존 `displayTitle` 아래)에 추가한다. (기존 확장 블록이 있으면 그 안에, 없으면 새 확장을 추가):

```swift
    /// 주소창 표시용 도메인. 없으면 빈 문자열.
    var displayDomain: String {
        LinkMetadataParsing.displayHost(fromURLString: URL) ?? ""
    }
```

- [ ] **Step 6: 앱 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift \
        TeamLongHair/TeamLongHair/Model/LinkModel.swift \
        CanvasLogicTests/main.swift
git commit -m "feat: Add displayHost/displayDomain for node address bar"
```

---

### Task 2: LinkNode 탭 카드 재작성

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` (전체 교체)

**Interfaces:**
- Consumes: `LinkDetail.displayDomain`(Task 1), 기존 `LinkDetail.displayTitle`/`pageDescription`/`tags`/`faviconData`/`color`, `IconColor.returnColor()`, `CanvasMetrics.nodeWidth`, 색 에셋(`.bgPrimary`, `.gray050`, `.gray100`, `.blue400`, `.purple400`, `.lbPrimary`, `.lbTertiary`, `.lbQuaternary`).
- Produces: 동일 공개 시그니처 `LinkNode(link:sizeOfNode:isSelected:isDropTarget:)` — 캔버스 호출부 변경 없음.

- [ ] **Step 1: LinkNode.swift 전체 교체**

`TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift`:

```swift
//
//  LinkNode.swift
//  TeamLongHair
//
//  캔버스 노드를 "브라우저 탭"으로 도식화: 탭 바(파비콘+제목+×) / 주소창(도메인) / 본문(설명+태그).
//  색(IconColor)은 탭 활성 표시선으로만 드러낸다.
//

import AppKit
import SwiftUI

struct LinkNode: View {
    var link: Link
    var sizeOfNode: CGFloat = CanvasMetrics.nodeWidth
    var isSelected: Bool
    /// 드래그로 연결하려는 대상(부모 후보)일 때 강조 표시.
    var isDropTarget: Bool = false

    private var s: CGFloat { sizeOfNode / 244 }
    private var accent: Color { link.detail.color.returnColor() }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar
            if !link.detail.displayDomain.isEmpty {
                addressBar
            }
            bodyArea
            Spacer(minLength: 0)
        }
        .frame(width: sizeOfNode, height: 118 * s, alignment: .topLeading)
        .background(.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 11 * s))
        .overlay {
            RoundedRectangle(cornerRadius: 11 * s).stroke(Color.gray100, lineWidth: 1)
        }
        .contentShape(Rectangle())
        // 선택 강조: 파랑 글로우
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 11 * s).stroke(Color.blue400, lineWidth: 3.5 * s)
            }
        }
        // 드롭 대상 강조: 보라 글로우(드래그 중, 선택보다 위)
        .overlay {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 11 * s).stroke(Color.purple400, lineWidth: 4 * s)
            }
        }
        .shadow(color: isDropTarget ? Color.purple400.opacity(0.6)
                    : (isSelected ? Color.blue400.opacity(0.55) : accent.opacity(0.12)),
                radius: (isDropTarget || isSelected) ? 10 : 6, x: 0, y: 4)
        .scaleEffect(isDropTarget ? 1.04 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isDropTarget)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }

    // MARK: - 탭 바 (활성 표시선 + 파비콘 + 제목 + ×)
    private var tabBar: some View {
        VStack(spacing: 0) {
            accent.frame(height: 2.5 * s)
            HStack(spacing: 6 * s) {
                favicon.frame(width: 15 * s, height: 15 * s)
                Text(link.detail.displayTitle)
                    .font(.system(size: 14 * s, weight: .semibold))
                    .foregroundStyle(.lbPrimary)
                    .lineLimit(1)
                Spacer(minLength: 4 * s)
                Image(systemName: "xmark")
                    .font(.system(size: 9 * s, weight: .semibold))
                    .foregroundStyle(.lbQuaternary)
            }
            .padding(.horizontal, 10 * s)
            .padding(.vertical, 6 * s)
            .background(.bgPrimary)
        }
        // 탭이 바 폭을 채우게 하여 긴 제목이 카드를 넘지 않고 말줄임되도록 한다.
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 9 * s, topTrailingRadius: 9 * s))
        .padding(.top, 5 * s)
        .padding(.horizontal, 6 * s)
        .background(.gray050)
    }

    // MARK: - 주소창 (도메인)
    private var addressBar: some View {
        HStack(spacing: 5 * s) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8 * s))
                .foregroundStyle(.lbTertiary)
            Text(link.detail.displayDomain)
                .font(.system(size: 11 * s))
                .foregroundStyle(.lbTertiary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8 * s)
        .padding(.vertical, 4 * s)
        .background(RoundedRectangle(cornerRadius: 6 * s).fill(.gray050))
        .padding(.horizontal, 10 * s)
        .padding(.top, 7 * s)
    }

    // MARK: - 본문 (설명 + 태그)
    private var bodyArea: some View {
        VStack(alignment: .leading, spacing: 4 * s) {
            if !link.detail.pageDescription.isEmpty {
                Text(link.detail.pageDescription)
                    .font(.system(size: 11 * s))
                    .foregroundStyle(.lbTertiary)
                    .lineLimit(2)
            }
            if !link.detail.tags.isEmpty {
                HStack(spacing: 4 * s) {
                    ForEach(link.detail.tags, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12 * s)
        .padding(.top, 6 * s)
    }

    // MARK: - 조각
    private var favicon: some View {
        Group {
            if let data = link.detail.faviconData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "globe").resizable().foregroundStyle(.lbTertiary)
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 10 * s))
            .foregroundStyle(.lbTertiary)
            .padding(.horizontal, 7 * s)
            .padding(.vertical, 2 * s)
            .background(RoundedRectangle(cornerRadius: 5 * s).fill(.gray050))
    }
}

#Preview {
    LinkNode(
        link: .init(detail: .init(URL: "https://developer.apple.com", title: "스위프트")),
        isSelected: false
    )
    .padding()
}
```

- [ ] **Step 2: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`
(`UnevenRoundedRectangle`은 macOS 13+ SwiftUI에 존재. `.lbPrimary`/`.lbTertiary`/`.lbQuaternary`/`.gray050`/`.gray100`/`.bgPrimary`/`.blue400`/`.purple400`는 기존 앱에서 쓰는 색 에셋이라 풀 빌드에서 해석된다. 만약 특정 색 심볼이 빌드에서 없다고 나오면, 앱에서 실제 사용 중인 인접 대체 심볼(예: `.lbSecondary`, `.bgSecondary`)로 바꾸고 리포트에 남긴다.)

- [ ] **Step 3: 수동 QA(참고 — GUI 실행 불가)**

정적으로 확인: `LinkNode` 시그니처가 그대로라 `CanvasContentView` 호출부 변경이 없고, 탭 바/주소창(도메인 있을 때만)/본문/활성 표시선/선택·드롭 오버레이가 배선됐는지. 실기기 QA는 종료 후 사용자 이관: 파비콘 있는/없는 노드, 도메인 없는 노드(주소창 숨김), 설명 없는 노드, 선택·드롭 강조, 244×118 안에서 클립 상태, 라이트/다크 대비.

- [ ] **Step 4: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift
git commit -m "feat: Redesign LinkNode as a browser-tab card (tab bar + address bar + body)"
```

---

## 실행 순서/의존성 요약

1. **Task 1** — 순수 `displayHost` + `displayDomain`(swiftc 테스트) → Task 2가 주소창에 사용.
2. **Task 2** — `LinkNode` 탭 카드 재작성.

Task 1은 로직 테스트 + 빌드로, Task 2는 빌드 + 수동 QA로 게이트한다(SwiftUI/이미지 렌더는 swiftc 불가 — 이 코드베이스의 알려진 제약). 전체 완료 후 사용자 실기기 QA: 각 노드가 "탭"으로 읽히는지, 색이 탭 표시선으로만 절제되는지, 여러 노드가 있는 캔버스가 차분한지, 도메인/설명/파비콘 폴백, 선택·드롭 강조, 라이트/다크.
