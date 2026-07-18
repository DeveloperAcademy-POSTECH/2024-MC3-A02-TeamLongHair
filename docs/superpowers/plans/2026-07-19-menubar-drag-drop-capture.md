# 메뉴바 드래그앤드롭 캡처 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 브라우저 탭을 메뉴바 아이콘 또는 캔버스에 드래그해서 곧바로 노드로 추가하는, 권한이 필요 없는 두 번째 캡처 경로를 추가한다.

**Architecture:** 단일 공유 `ModelContainer`를 도입해 앱과 메뉴바(AppDelegate)가 같은 컨텍스트를 공유한다. URL→노드 생성을 `LinkIngest` 한 곳으로 모으고(플로팅 패널도 리팩터), 대상 페이지 결정을 순수 리졸버 + SwiftData 글루로 분리한다. 드롭 표면은 두 개다: AppKit `NSStatusItem`(메뉴바 아이콘 직접 드롭 + 클릭 팝오버)와 SwiftUI `DropDelegate`(캔버스, 커서 아래 노드 하이라이트).

**Tech Stack:** macOS 14+, SwiftUI, SwiftData(@Model/@Observable), AppKit(NSStatusItem/NSPopover/NSHostingController), LinkPresentation(기존 `LinkMetadataApply` 재사용), swiftc 기반 순수 로직 테스트.

## Global Constraints

- 앱은 **비샌드박스**이며 이 기능은 **엔타이틀먼트/권한 변경이 전혀 없다**(드래그앤드롭·메뉴바 모두 추가 권한 불필요).
- SwiftData 스키마는 기존 `Schema([Project.self])` 그대로 — **마이그레이션 없음**.
- 앱 전체가 **하나의 `ModelContainer` 인스턴스**(`AppModelContainer.shared`)를 공유해야 한다(메뉴바 드롭이 열린 창에 즉시 반영되도록).
- 수집되는 URL은 **http/https 스킴만** 허용(무효/`chrome://`/`about:` 등 제외).
- 메타데이터 취득은 기존 `LinkMetadataApply.fetchAndApply(to:)`를 **재사용**한다(중복 구현 금지).
- 순수 로직(리졸버, displayTitle)은 **프레임워크 의존 없는 파일**에 두어 `scripts/run_canvas_tests.sh`(swiftc)로 테스트 가능해야 한다.
- 새 Swift 파일은 반드시 `ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj <Group> <File.swift>`로 Xcode 프로젝트에 등록한다(등록 안 하면 앱 빌드에서 누락됨). 파일은 먼저 해당 그룹 폴더에 디스크로 존재해야 한다.
- 앱 빌드 검증 명령: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build` → 기대 출력 `** BUILD SUCCEEDED **`.

---

## 파일 구조

**신규**
- `TeamLongHair/TeamLongHair/Utils/CaptureTargetResolver.swift` — 순수 리졸버(Foundation only, swiftc 테스트 대상)
- `TeamLongHair/TeamLongHair/Utils/AppModelContainer.swift` — 공유 컨테이너
- `TeamLongHair/TeamLongHair/Utils/LinkIngest.swift` — 공용 수집 로직
- `TeamLongHair/TeamLongHair/Utils/DroppedURLLoader.swift` — NSItemProvider→[URL] 로더(캔버스·팝오버 공유)
- `TeamLongHair/TeamLongHair/Utils/CaptureTarget.swift` — SwiftData 글루(대상 Page 해석/기본 프로젝트 생성)
- `TeamLongHair/TeamLongHair/Utils/StatusBarController.swift` — 메뉴바 상주 + 아이콘 드롭 + 팝오버
- `TeamLongHair/TeamLongHair/FloatingPanel/MenuBarPanelView.swift` — 팝오버 콘텐츠
- `TeamLongHair/TeamLongHair/Project/ToastView.swift` — 수집 피드백 오버레이

**수정**
- `TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift` — `displayTitle(title:urlString:)` 추가
- `TeamLongHair/TeamLongHair/Model/LinkModel.swift` — `LinkDetail.displayTitle` 확장
- `TeamLongHair/TeamLongHair/Utils/AppState.swift` — `IngestReceipt` + `lastIngest`
- `TeamLongHair/TeamLongHair/TeamLongHairApp.swift` — `AppModelContainer.shared` 사용
- `TeamLongHair/TeamLongHair/Utils/AppDelegate.swift` — `StatusBarController` 생성/보유
- `TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift` — 저장을 `LinkIngest`로
- `TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasView.swift` — `CanvasDropDelegate` + `.onDrop`
- `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` — `displayTitle` 표시
- `TeamLongHair/TeamLongHair/Project/LinkPanel/LinkListView.swift` — `displayTitle` 표시
- `TeamLongHair/TeamLongHair/Project/ProjectView.swift` — ToastView 오버레이
- `scripts/run_canvas_tests.sh` — 순수 리졸버 컴파일 추가
- `CanvasLogicTests/main.swift` — 리졸버/displayTitle 테스트

---

### Task 1: 순수 로직 — CaptureTargetResolver + displayTitle (TDD)

프레임워크 의존이 없는 순수 함수 두 개. 유일하게 완전한 TDD가 가능한 태스크다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/CaptureTargetResolver.swift`
- Modify: `TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift` (파일 끝, `decodeEntities` 뒤 `enum` 내부에 정적 함수 추가)
- Modify: `scripts/run_canvas_tests.sh` (swiftc 입력에 `CaptureTargetResolver.swift` 추가)
- Test: `CanvasLogicTests/main.swift` (파일 끝 `if failures > 0` 직전에 케이스 추가)

**Interfaces:**
- Produces:
  - `struct ProjectRef { let id: UUID; let pageIDs: [UUID]; init(id: UUID, pageIDs: [UUID]) }`
  - `enum CaptureResolution: Equatable { case existing(projectIndex: Int, pageIndex: Int); case createDefault }`
  - `enum CaptureTargetResolver { static func resolve(projects: [ProjectRef], currentProjectID: UUID?, currentPageID: UUID?) -> CaptureResolution }`
  - `LinkMetadataParsing.displayTitle(title: String, urlString: String) -> String`

- [ ] **Step 1: 테스트 추가 (실패 확인용)**

`CanvasLogicTests/main.swift`의 맨 끝, `if failures > 0 { ... }` 줄 **바로 위**에 다음을 추가한다:

```swift
// MARK: - CaptureTargetResolver tests
do {
    let p0 = UUID(); let p0g0 = UUID(); let p0g1 = UUID()
    let p1 = UUID(); let p1g0 = UUID()
    let projects = [
        ProjectRef(id: p0, pageIDs: [p0g0, p0g1]),  // index 0 = 가장 최근
        ProjectRef(id: p1, pageIDs: [p1g0]),
    ]
    // 1) current 프로젝트/페이지 모두 매칭
    expectEqual(CaptureTargetResolver.resolve(projects: projects, currentProjectID: p1, currentPageID: p1g0),
                .existing(projectIndex: 1, pageIndex: 0), "현재 프로젝트/페이지 매칭")
    // 2) 프로젝트만 매칭, 페이지는 삭제됨 → 그 프로젝트 0번 페이지
    expectEqual(CaptureTargetResolver.resolve(projects: projects, currentProjectID: p0, currentPageID: UUID()),
                .existing(projectIndex: 0, pageIndex: 0), "페이지 미매칭이면 0번 페이지")
    // 2b) 프로젝트 매칭 + 두 번째 페이지 매칭
    expectEqual(CaptureTargetResolver.resolve(projects: projects, currentProjectID: p0, currentPageID: p0g1),
                .existing(projectIndex: 0, pageIndex: 1), "두 번째 페이지 매칭")
    // 3) 프로젝트가 삭제됨 → 0번(최근) 프로젝트 0번 페이지
    expectEqual(CaptureTargetResolver.resolve(projects: projects, currentProjectID: UUID(), currentPageID: nil),
                .existing(projectIndex: 0, pageIndex: 0), "프로젝트 미매칭이면 최근 프로젝트 0번")
    // 4) current 둘 다 nil → 0번/0번
    expectEqual(CaptureTargetResolver.resolve(projects: projects, currentProjectID: nil, currentPageID: nil),
                .existing(projectIndex: 0, pageIndex: 0), "current 둘 다 nil")
    // 5) projects 빈 배열 → createDefault
    expectEqual(CaptureTargetResolver.resolve(projects: [], currentProjectID: p0, currentPageID: p0g0),
                .createDefault, "프로젝트 없으면 createDefault")
}

// MARK: - displayTitle tests
expect(LinkMetadataParsing.displayTitle(title: "실제 제목", urlString: "https://a.com") == "실제 제목",
       "제목 있으면 제목")
expect(LinkMetadataParsing.displayTitle(title: "   ", urlString: "https://youtube.com/watch") == "youtube.com",
       "제목 공백이면 호스트")
expect(LinkMetadataParsing.displayTitle(title: "", urlString: "not a url") == "not a url",
       "제목 빈 + URL 파싱 실패면 원본 문자열")
```

- [ ] **Step 2: 테스트 실행 → 컴파일 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: FAIL — `error: cannot find 'CaptureTargetResolver' in scope` / `type 'LinkMetadataParsing' has no member 'displayTitle'`

- [ ] **Step 3: CaptureTargetResolver.swift 작성**

`TeamLongHair/TeamLongHair/Utils/CaptureTargetResolver.swift`:

```swift
//
//  CaptureTargetResolver.swift
//  TeamLongHair
//
//  "지금 어느 페이지에 수집할지" 결정하는 순수 로직. 프레임워크 의존 없음(swiftc 테스트 대상).
//  SwiftData 글루는 CaptureTarget.swift가 담당한다.
//

import Foundation

/// 리졸버 입력용 프로젝트 요약(id + 페이지 id 순서).
struct ProjectRef {
    let id: UUID
    let pageIDs: [UUID]
    init(id: UUID, pageIDs: [UUID]) {
        self.id = id
        self.pageIDs = pageIDs
    }
}

/// 리졸버 결과. 인덱스는 입력 projects 배열 기준(같은 정렬 배열로 역참조).
enum CaptureResolution: Equatable {
    case existing(projectIndex: Int, pageIndex: Int)
    case createDefault
}

enum CaptureTargetResolver {
    /// projects는 최근 편집 순(내림차순)이라고 가정한다.
    /// 1) currentProjectID 매칭 → 그 프로젝트, 그 안에서 currentPageID 매칭 페이지(미매칭이면 0번).
    /// 2) currentProjectID 미매칭 → 0번(가장 최근) 프로젝트의 0번 페이지.
    /// 3) projects 비면 → createDefault.
    static func resolve(projects: [ProjectRef],
                        currentProjectID: UUID?,
                        currentPageID: UUID?) -> CaptureResolution {
        guard !projects.isEmpty else { return .createDefault }
        let projectIndex = currentProjectID
            .flatMap { id in projects.firstIndex(where: { $0.id == id }) } ?? 0
        let pageIDs = projects[projectIndex].pageIDs
        guard !pageIDs.isEmpty else { return .existing(projectIndex: projectIndex, pageIndex: 0) }
        let pageIndex = currentPageID
            .flatMap { id in pageIDs.firstIndex(of: id) } ?? 0
        return .existing(projectIndex: projectIndex, pageIndex: pageIndex)
    }
}
```

- [ ] **Step 4: displayTitle 추가**

`TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift`에서 `parseDescription(fromHTML:)` 정적 함수 **바로 아래**(같은 `enum LinkMetadataParsing` 내부)에 추가:

```swift
    /// 노드/리스트 표시용 제목 폴백. 제목이 비면 URL 호스트, 그것도 안 되면 원본 문자열.
    static func displayTitle(title: String, urlString: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let host = URL(string: urlString)?.host { return host }
        return urlString
    }
```

- [ ] **Step 5: 테스트 러너에 순수 파일 등록**

`scripts/run_canvas_tests.sh`의 `swiftc -o "$OUT" \` 블록에서 `LinkMetadataParsing.swift` 줄 바로 아래에 한 줄 추가:

```bash
  TeamLongHair/TeamLongHair/Utils/CaptureTargetResolver.swift \
```

(결과적으로 컴파일 목록은 TreeLayout.swift, DropValidator.swift, LinkMetadataParsing.swift, CaptureTargetResolver.swift, CanvasLogicTests/main.swift 순.)

- [ ] **Step 6: 테스트 실행 → 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: PASS — 마지막 줄 `ALL TESTS PASSED`

- [ ] **Step 7: 앱 프로젝트에 파일 등록**

Run:
```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils CaptureTargetResolver.swift
```
Expected: `Added CaptureTargetResolver.swift to group Utils`

- [ ] **Step 8: 앱 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/CaptureTargetResolver.swift \
        TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift \
        scripts/run_canvas_tests.sh CanvasLogicTests/main.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add CaptureTargetResolver and displayTitle pure logic with tests"
```

---

### Task 2: 공유 컨테이너 + LinkIngest + URL 로더 + displayTitle 확장

수집 파이프라인의 뼈대. SwiftData/AppKit 의존이라 유닛 테스트는 없고 빌드로 검증한다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/AppModelContainer.swift`
- Create: `TeamLongHair/TeamLongHair/Utils/LinkIngest.swift`
- Create: `TeamLongHair/TeamLongHair/Utils/DroppedURLLoader.swift`
- Modify: `TeamLongHair/TeamLongHair/Model/LinkModel.swift` (파일 끝 `extension Link` 뒤에 `extension LinkDetail` 추가)
- Modify: `TeamLongHair/TeamLongHair/TeamLongHairApp.swift` (인라인 컨테이너 → 공유 컨테이너)

**Interfaces:**
- Consumes: `LinkMetadataParsing.normalizedURL(from:)`, `LinkMetadataParsing.displayTitle(title:urlString:)`(Task 1), `LinkMetadataApply.fetchAndApply(to:)`(기존), `Link(detail:sortIndex:)`, `LinkDetail(URL:title:)`, `Page.sortedLinks`, `Link.sortedSubLinks`.
- Produces:
  - `enum AppModelContainer { static let shared: ModelContainer }`
  - `@MainActor enum LinkIngest { @discardableResult static func addLink(url: URL, title: String = "", to page: Page, parent: Link? = nil) -> Link; @discardableResult static func addLinks(_ urls: [URL], to page: Page, parent: Link? = nil) -> Int }`
  - `enum DroppedURLLoader { static func load(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) }`
  - `extension LinkDetail { var displayTitle: String }`

- [ ] **Step 1: AppModelContainer.swift 작성**

`TeamLongHair/TeamLongHair/Utils/AppModelContainer.swift`:

```swift
//
//  AppModelContainer.swift
//  TeamLongHair
//
//  앱 전체가 공유하는 단일 ModelContainer. App과 AppDelegate(메뉴바)가 같은 인스턴스를
//  써야 메뉴바 드롭이 열려 있는 창에 즉시 반영된다.
//

import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Project.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
```

- [ ] **Step 2: LinkIngest.swift 작성**

`TeamLongHair/TeamLongHair/Utils/LinkIngest.swift`:

```swift
//
//  LinkIngest.swift
//  TeamLongHair
//
//  URL → 노드 생성의 단일 출처. 플로팅 패널·메뉴바·캔버스 드롭이 모두 이걸 쓴다.
//

import SwiftData

@MainActor
enum LinkIngest {
    /// URL 하나를 page(또는 parent 하위)에 노드로 추가하고 메타데이터 취득을 건다.
    /// title 미지정 시 빈 문자열로 두어 LinkMetadataApply가 실제 제목을 채우게 한다.
    @discardableResult
    static func addLink(url: URL, title: String = "",
                        to page: Page, parent: Link? = nil) -> Link {
        let detail = LinkDetail(URL: url.absoluteString, title: title)
        let siblings = parent?.sortedSubLinks ?? page.sortedLinks
        let link = Link(detail: detail, sortIndex: (siblings.last?.sortIndex ?? -1) + 1)
        if let parent {
            parent.subLinks.append(link)
        } else {
            page.links.append(link)
        }
        LinkMetadataApply.fetchAndApply(to: detail)
        return link
    }

    /// 여러 URL을 같은 대상에 추가하고 추가된 개수를 반환.
    @discardableResult
    static func addLinks(_ urls: [URL], to page: Page, parent: Link? = nil) -> Int {
        for url in urls { addLink(url: url, to: page, parent: parent) }
        return urls.count
    }
}
```

- [ ] **Step 3: DroppedURLLoader.swift 작성**

`TeamLongHair/TeamLongHair/Utils/DroppedURLLoader.swift`:

```swift
//
//  DroppedURLLoader.swift
//  TeamLongHair
//
//  드롭된 NSItemProvider 배열에서 http/https URL을 비동기로 모아 메인 액터로 돌려준다.
//  캔버스 DropDelegate와 메뉴바 팝오버가 공유한다.
//

import Foundation

enum DroppedURLLoader {
    /// providers에서 .url을 우선 로드하고, 없으면 텍스트를 normalizedURL로 보정한다.
    /// http/https 스킴만 통과시키며, 완료 콜백은 항상 메인 액터에서 호출된다.
    static func load(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        // provider 순서를 보존하기 위해 인덱스별 슬롯에 담는다.
        var slots = [URL?](repeating: nil, count: providers.count)

        for (index, provider) in providers.enumerated() {
            group.enter()
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    slots[index] = url
                    group.leave()
                }
            } else if provider.canLoadObject(ofClass: String.self) {
                _ = provider.loadObject(ofClass: String.self) { string, _ in
                    if let string { slots[index] = LinkMetadataParsing.normalizedURL(from: string) }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let urls = slots.compactMap { $0 }.filter { $0.scheme == "http" || $0.scheme == "https" }
            completion(urls)
        }
    }
}
```

- [ ] **Step 4: LinkDetail.displayTitle 확장 추가**

`TeamLongHair/TeamLongHair/Model/LinkModel.swift` 파일 끝(`extension Link { ... }` 다음 줄)에 추가:

```swift
extension LinkDetail {
    /// 제목이 비었을 때 호스트/URL로 폴백하는 표시용 제목.
    var displayTitle: String {
        LinkMetadataParsing.displayTitle(title: title, urlString: URL)
    }
}
```

- [ ] **Step 5: TeamLongHairApp이 공유 컨테이너를 쓰도록 수정**

`TeamLongHair/TeamLongHair/TeamLongHairApp.swift`에서 `var modelContainer: ModelContainer = { ... }()` 프로퍼티(22–31행) 전체를 다음 한 줄로 교체:

```swift
    var modelContainer: ModelContainer { AppModelContainer.shared }
```

(`.floatingPanel`과 `HomeView`에 붙은 `.modelContainer(modelContainer)` 두 곳은 그대로 두면 동일 인스턴스를 참조한다.)

- [ ] **Step 6: 새 파일 3개 프로젝트 등록**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils AppModelContainer.swift
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils LinkIngest.swift
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils DroppedURLLoader.swift
```
Expected: 각각 `Added <file> to group Utils`

- [ ] **Step 7: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/AppModelContainer.swift \
        TeamLongHair/TeamLongHair/Utils/LinkIngest.swift \
        TeamLongHair/TeamLongHair/Utils/DroppedURLLoader.swift \
        TeamLongHair/TeamLongHair/Model/LinkModel.swift \
        TeamLongHair/TeamLongHair/TeamLongHairApp.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add shared container, LinkIngest, URL drop loader, displayTitle"
```

---

### Task 3: CaptureTarget 글루 + AppState.lastIngest + 플로팅 패널 리팩터

대상 페이지를 실제로 해석하고(필요 시 기본 프로젝트 생성), 수집 피드백 신호를 추가하고, 기존 플로팅 패널 저장을 공용 로직으로 옮긴다(회귀 없이).

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/CaptureTarget.swift`
- Modify: `TeamLongHair/TeamLongHair/Utils/AppState.swift` (프로퍼티 추가 + 파일 내 struct)
- Modify: `TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift` (저장 블록)

**Interfaces:**
- Consumes: `CaptureTargetResolver.resolve(...)`, `ProjectRef`, `CaptureResolution`(Task 1); `LinkIngest.addLink(url:title:to:)`(Task 2); `LinkMetadataParsing.normalizedURL(from:)`(기존); `Project(title:)`, `FetchDescriptor<Project>`.
- Produces:
  - `@MainActor enum CaptureTarget { static func resolvePage(appState: AppState, context: ModelContext) -> Page?; static func targetDescription(appState: AppState, context: ModelContext) -> String }`
  - `struct IngestReceipt: Equatable { let id: UUID; let count: Int; let targetName: String; init(count: Int, targetName: String) }`
  - `AppState.lastIngest: IngestReceipt?`

- [ ] **Step 1: CaptureTarget.swift 작성**

`TeamLongHair/TeamLongHair/Utils/CaptureTarget.swift`:

```swift
//
//  CaptureTarget.swift
//  TeamLongHair
//
//  CaptureTargetResolver(순수)를 SwiftData에 붙인다. 실제 Page를 돌려주고,
//  프로젝트가 하나도 없으면 기본 프로젝트를 생성한다.
//

import SwiftData

@MainActor
enum CaptureTarget {
    /// 수집 대상 Page. 프로젝트가 없으면 기본 "Untitled" 프로젝트를 생성해 그 첫 페이지를 반환.
    static func resolvePage(appState: AppState, context: ModelContext) -> Page? {
        let projects = fetchProjects(context)
        switch resolve(projects: projects, appState: appState) {
        case .existing(let pi, let gi):
            let pages = projects[pi].pages
            guard pages.indices.contains(gi) else { return pages.first }
            return pages[gi]
        case .createDefault:
            let project = Project(title: "Untitled")   // init이 "Untitled" 페이지 1개를 생성
            context.insert(project)
            return project.pages.first
        }
    }

    /// 팝오버에 "어디로 갈지" 미리 보여주기 위한 읽기 전용 설명(부수효과 없음).
    static func targetDescription(appState: AppState, context: ModelContext) -> String {
        let projects = fetchProjects(context)
        switch resolve(projects: projects, appState: appState) {
        case .existing(let pi, let gi):
            let project = projects[pi]
            let pageTitle = project.pages.indices.contains(gi) ? project.pages[gi].title
                          : (project.pages.first?.title ?? "")
            return "\(project.title) · \(pageTitle)"
        case .createDefault:
            return "새 프로젝트가 생성됩니다"
        }
    }

    // MARK: - Helpers

    private static func fetchProjects(_ context: ModelContext) -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.lastEditDate, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func resolve(projects: [Project], appState: AppState) -> CaptureResolution {
        let refs = projects.map { ProjectRef(id: $0.id, pageIDs: $0.pages.map(\.id)) }
        return CaptureTargetResolver.resolve(projects: refs,
                                             currentProjectID: appState.currentProjectID,
                                             currentPageID: appState.currentPageID)
    }
}
```

- [ ] **Step 2: AppState에 IngestReceipt + lastIngest 추가**

`TeamLongHair/TeamLongHair/Utils/AppState.swift`에서 `var currentPageID: UUID?`(24행) 바로 아래에 추가:

```swift
    /// 최근 드롭 수집 결과(토스트/팝오버 확인용). 매번 새 id라 변경이 항상 감지된다.
    var lastIngest: IngestReceipt?
```

그리고 같은 파일 맨 끝(`}` 클래스 닫힘 뒤)에 struct 추가:

```swift
struct IngestReceipt: Equatable {
    let id: UUID
    let count: Int
    let targetName: String
    init(count: Int, targetName: String) {
        self.id = UUID()
        self.count = count
        self.targetName = targetName
    }
}
```

- [ ] **Step 3: 플로팅 패널 저장을 LinkIngest로 교체**

`TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift`의 `.onChange(of: appState.shouldSaveDataToggle)` 블록(106–123행) 안에서, `else if let targetPage = resolvedTargetPage()` 분기 본문을 교체한다. 기존:

```swift
                } else if let targetPage = resolvedTargetPage() {
                    let newLinkDetail = LinkDetail(URL: panelURLText, title: panelTitleText)
                    let newLink = Link(detail: newLinkDetail,
                                       sortIndex: (targetPage.sortedLinks.last?.sortIndex ?? -1) + 1)
                    targetPage.links.append(newLink)
                    LinkMetadataApply.fetchAndApply(to: newLinkDetail)

                    appState.isPanelPresented = false
                    resetPanelInput()
                }
```

교체 후:

```swift
                } else if let targetPage = resolvedTargetPage(),
                          let url = LinkMetadataParsing.normalizedURL(from: panelURLText) {
                    LinkIngest.addLink(url: url, title: panelTitleText, to: targetPage)
                    appState.isPanelPresented = false
                    resetPanelInput()
                } else {
                    // URL 정규화 실패 → URL 필드로 되돌려 사용자가 고치게 한다.
                    focusedField = .url
                    fieldState = .url
                }
```

- [ ] **Step 4: 파일 등록**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils CaptureTarget.swift
```
Expected: `Added CaptureTarget.swift to group Utils`

- [ ] **Step 5: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: 수동 확인(회귀) — 실행 후 플로팅 패널 저장**

앱을 실행(Xcode Run)해 ⌘⇧G로 패널을 열고 URL/제목 입력 후 Enter → 링크가 현재 페이지에 추가되는지 확인. (자동 테스트 불가한 SwiftData/AppKit 경로.)

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/CaptureTarget.swift \
        TeamLongHair/TeamLongHair/Utils/AppState.swift \
        TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add CaptureTarget glue, ingest receipt, route floating panel through LinkIngest"
```

---

### Task 4: 메뉴바 상주 + 아이콘 드롭 + 팝오버

AppKit `NSStatusItem`으로 메뉴바에 상주하고, 아이콘에 직접 탭을 드롭하면 마지막 본 페이지로 수집한다. 클릭하면 SwiftUI 팝오버가 뜬다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/StatusBarController.swift`
- Create: `TeamLongHair/TeamLongHair/FloatingPanel/MenuBarPanelView.swift`
- Modify: `TeamLongHair/TeamLongHair/Utils/AppDelegate.swift`

**Interfaces:**
- Consumes: `AppModelContainer.shared`(Task 2), `CaptureTarget.resolvePage/targetDescription`(Task 3), `LinkIngest.addLinks`(Task 2), `DroppedURLLoader.load`(Task 2), `LinkMetadataParsing.normalizedURL(from:)`, `AppState.shared`, `IngestReceipt`(Task 3).
- Produces:
  - `@MainActor final class StatusBarController { init(); func openApp() }`
  - `struct MenuBarPanelView: View`

- [ ] **Step 1: StatusBarController.swift 작성**

`TeamLongHair/TeamLongHair/Utils/StatusBarController.swift`:

```swift
//
//  StatusBarController.swift
//  TeamLongHair
//
//  메뉴바 상주(NSStatusItem). 아이콘에 브라우저 탭을 직접 드롭하면 마지막 본 페이지로
//  수집하고, 클릭하면 팝오버(MenuBarPanelView)를 띄운다. AppDelegate가 소유한다.
//

import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var dropView: StatusItemDropView?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "point.3.filled.connected.trianglepath.dotted",
                                   accessibilityDescription: "TeamLongHair")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self

            // 버튼 위에 드롭 전용 뷰를 얹어 아이콘 직접 드롭을 받는다.
            let drop = StatusItemDropView(frame: button.bounds)
            drop.autoresizingMask = [.width, .height]
            drop.onDropURLs = { [weak self] urls in self?.ingest(urls) }
            button.addSubview(drop)
            dropView = drop
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPanelView(onOpenApp: { [weak self] in self?.openApp() })
                .environment(AppState.shared)
                .modelContainer(AppModelContainer.shared)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    /// 팝오버의 "앱 열기" 및 아이콘 클릭에서 메인 창을 앞으로.
    func openApp() {
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
    }

    /// 드롭된 URL을 대상 페이지로 수집하고 피드백 신호를 남긴다.
    private func ingest(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let context = AppModelContainer.shared.mainContext
        guard let page = CaptureTarget.resolvePage(appState: AppState.shared, context: context) else { return }
        let name = CaptureTarget.targetDescription(appState: AppState.shared, context: context)
        let count = LinkIngest.addLinks(urls, to: page)
        AppState.shared.lastIngest = IngestReceipt(count: count, targetName: name)
    }
}

/// 메뉴바 버튼 위에 얹혀 URL/문자열 드롭을 받는 뷰.
final class StatusItemDropView: NSView {
    var onDropURLs: (([URL]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.URL, .fileURL, .string])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        var urls: [URL] = []
        if let objects = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            urls = objects
        }
        if urls.isEmpty, let text = pasteboard.string(forType: .string),
           let url = LinkMetadataParsing.normalizedURL(from: text) {
            urls = [url]
        }
        urls = urls.filter { $0.scheme == "http" || $0.scheme == "https" }
        guard !urls.isEmpty else { return false }
        onDropURLs?(urls)
        return true
    }
}
```

- [ ] **Step 2: MenuBarPanelView.swift 작성**

`TeamLongHair/TeamLongHair/FloatingPanel/MenuBarPanelView.swift`:

```swift
//
//  MenuBarPanelView.swift
//  TeamLongHair
//
//  메뉴바 아이콘 클릭 시 뜨는 팝오버. 드롭존 + 현재 대상 미리보기 + 앱 열기.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MenuBarPanelView: View {
    var onOpenApp: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TeamLongHair")
                .font(.system(size: 14, weight: .bold))

            // 드롭존
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(isTargeted ? Color.purple400 : Color.lbQuaternary)
                .frame(height: 96)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 20))
                        Text("여기로 브라우저 탭을 끌어놓으세요")
                            .font(.system(size: 12))
                            .foregroundStyle(.lbTertiary)
                    }
                }
                .background(isTargeted ? Color.purple400.opacity(0.08) : .clear)
                .onDrop(of: [.url, .text], isTargeted: $isTargeted) { providers in
                    DroppedURLLoader.load(from: providers) { urls in ingest(urls) }
                    return true
                }

            // 현재 대상 미리보기
            HStack(spacing: 4) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.lbTertiary)
                Text(CaptureTarget.targetDescription(appState: appState, context: context))
                    .font(.system(size: 12))
                    .foregroundStyle(.lbSecondary)
                    .lineLimit(1)
            }

            // 최근 수집 확인
            if let receipt = appState.lastIngest {
                Text("\(receipt.count)개 링크를 '\(receipt.targetName)'에 추가")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
                    .lineLimit(2)
            }

            Divider()

            Button {
                onOpenApp()
            } label: {
                HStack {
                    Image(systemName: "macwindow")
                    Text("앱 열기")
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 300)
    }

    private func ingest(_ urls: [URL]) {
        guard !urls.isEmpty,
              let page = CaptureTarget.resolvePage(appState: appState, context: context) else { return }
        let name = CaptureTarget.targetDescription(appState: appState, context: context)
        let count = LinkIngest.addLinks(urls, to: page)
        appState.lastIngest = IngestReceipt(count: count, targetName: name)
    }
}
```

- [ ] **Step 3: AppDelegate가 StatusBarController를 생성/보유하도록 수정**

`TeamLongHair/TeamLongHair/Utils/AppDelegate.swift`에서 `private var globalKeyMonitor: Any?`(15행) 아래에 프로퍼티 추가:

```swift
    private var statusBarController: StatusBarController?
```

그리고 `applicationDidFinishLaunching`의 `startMonitoringKeys()` 호출 **아래**에 추가:

```swift
        statusBarController = StatusBarController()
```

- [ ] **Step 4: 파일 등록**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils StatusBarController.swift
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj FloatingPanel MenuBarPanelView.swift
```
Expected: `Added StatusBarController.swift to group Utils` / `Added MenuBarPanelView.swift to group FloatingPanel`

- [ ] **Step 5: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: 수동 QA**

Xcode Run 후:
1. 메뉴바에 아이콘이 뜨는지.
2. 아이콘 클릭 → 팝오버(드롭존/현재 대상/앱 열기)가 뜨는지.
3. 브라우저 탭 1개를 아이콘에 드롭 → 마지막 본 페이지에 노드가 추가되고 팝오버에 확인 문구가 뜨는지.
4. 탭 여러 개를 선택해 드롭 → 모두 추가되는지.
5. 메인 창을 닫은 상태에서 드롭 → 다시 열었을 때 반영돼 있는지.
6. "앱 열기" 버튼이 메인 창을 앞으로 가져오는지.

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/StatusBarController.swift \
        TeamLongHair/TeamLongHair/FloatingPanel/MenuBarPanelView.swift \
        TeamLongHair/TeamLongHair/Utils/AppDelegate.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add menu-bar status item with tab drop and popover"
```

---

### Task 5: 캔버스 외부 드롭 (DropDelegate)

캔버스에 탭을 드롭하면 빈 곳은 루트, 노드 위는 그 자식으로 추가한다. 드래그 중 커서 아래 노드를 하이라이트한다. `CanvasContentView`의 로컬 좌표계가 이미 콘텐츠 좌표이므로 기존 히트테스트를 재사용한다.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasView.swift`

**Interfaces:**
- Consumes: `DroppedURLLoader.load`(Task 2), `LinkIngest.addLinks`(Task 2), `AppState.shared`, `IngestReceipt`(Task 3), 기존 `TreeLayoutResult`, `CanvasMetrics`, `page.title`, `page.links`.
- Produces: 파일 프라이빗 자유 함수 `canvasNodeID(at:in:excluding:)`, `canvasFindLink(_:in:)`; `struct CanvasDropDelegate: DropDelegate`.

- [ ] **Step 1: 파일 프라이빗 히트테스트 자유 함수 추가**

`TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasView.swift`의 `import` 구문들 아래, `struct CanvasView` 정의 **위**에 추가:

```swift
/// 콘텐츠 좌표의 한 점을 포함하는 노드 id(excluding은 제외, 없으면 nil).
/// 뷰와 CanvasDropDelegate가 공유한다.
private func canvasNodeID(at point: CGPoint, in layout: TreeLayoutResult, excluding: UUID?) -> UUID? {
    for (id, pos) in layout.positions where id != excluding {
        let frame = CGRect(x: pos.x, y: pos.y,
                           width: CanvasMetrics.nodeWidth, height: CanvasMetrics.nodeHeight)
        if frame.contains(point) { return id }
    }
    return nil
}

/// 페이지 트리에서 id로 Link를 찾는다.
private func canvasFindLink(_ id: UUID, in links: [Link]) -> Link? {
    for link in links {
        if link.id == id { return link }
        if let found = canvasFindLink(id, in: link.subLinks) { return found }
    }
    return nil
}
```

- [ ] **Step 2: 기존 `nodeID(at:layout:excluding:)`를 자유 함수로 위임**

같은 파일 `CanvasContentView`의 `private func nodeID(at point:...)`(195–202행) 본문을 교체:

```swift
    private func nodeID(at point: CGPoint, layout: TreeLayoutResult, excluding: UUID) -> UUID? {
        canvasNodeID(at: point, in: layout, excluding: excluding)
    }
```

- [ ] **Step 3: CanvasDropDelegate 추가**

같은 파일 맨 끝(`struct CanvasContentView { ... }` 닫힘 뒤)에 추가:

```swift
/// 브라우저 탭(URL) 외부 드롭을 캔버스에서 받는다. DropInfo.location은 CanvasContentView의
/// 로컬 좌표(=콘텐츠 좌표)라 layout.positions와 같은 좌표계다.
struct CanvasDropDelegate: DropDelegate {
    let page: Page
    let layout: TreeLayoutResult
    @Binding var dropTargetID: UUID?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropTargetID = canvasNodeID(at: info.location, in: layout, excluding: nil)
        return DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) { dropTargetID = nil }

    func performDrop(info: DropInfo) -> Bool {
        let parentID = canvasNodeID(at: info.location, in: layout, excluding: nil)
        let providers = info.itemProviders(for: [.url, .text])
        let page = self.page
        DroppedURLLoader.load(from: providers) { urls in
            guard !urls.isEmpty else { return }
            let parent = parentID.flatMap { canvasFindLink($0, in: page.links) }
            let count = LinkIngest.addLinks(urls, to: page, parent: parent)
            AppState.shared.lastIngest = IngestReceipt(count: count, targetName: page.title)
        }
        dropTargetID = nil
        return !providers.isEmpty
    }
}
```

- [ ] **Step 4: CanvasContentView 본문에 `.onDrop` 부착**

같은 파일 `CanvasContentView`의 `body`에서, `.coordinateSpace(.named(Self.canvasSpace))`(128행) **바로 아래** 줄에 추가:

```swift
        .onDrop(of: [.url, .text], delegate: CanvasDropDelegate(page: page, layout: layout, dropTargetID: $dropTargetID))
```

파일 상단에 `import UniformTypeIdentifiers`가 없으면 `import SwiftUI` 아래에 추가한다(`.url`/`.text` UTType 사용).

- [ ] **Step 5: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: 수동 QA**

Xcode Run 후:
1. 브라우저 탭을 캔버스 빈 곳에 드롭 → 루트 노드 추가.
2. 탭을 기존 노드 위에 드롭 → 그 노드의 자식으로 추가(드래그 중 대상 노드가 보라색으로 강조).
3. 탭 여러 개 드롭 → 모두 같은 대상으로 추가.
4. 드롭 후 파비콘/제목이 자동으로 채워지는지.

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasView.swift
git commit -m "feat: Accept browser-tab URL drops on the canvas with node highlight"
```

---

### Task 6: 피드백 토스트 + 빈 제목 표시 폴백

수집 결과를 메인 창에 잠깐 알리고, 메타데이터 도착 전/실패 시 노드·리스트가 빈 제목으로 보이지 않게 한다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Project/ToastView.swift`
- Modify: `TeamLongHair/TeamLongHair/Project/ProjectView.swift`
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift`
- Modify: `TeamLongHair/TeamLongHair/Project/LinkPanel/LinkListView.swift`

**Interfaces:**
- Consumes: `IngestReceipt`(Task 3), `AppState.shared`, `LinkDetail.displayTitle`(Task 2).
- Produces: `struct ToastView: View`.

- [ ] **Step 1: ToastView.swift 작성**

`TeamLongHair/TeamLongHair/Project/ToastView.swift`:

```swift
//
//  ToastView.swift
//  TeamLongHair
//
//  드롭 수집 결과를 하단에 잠깐 표시하는 토스트.
//

import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.lbPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule().fill(.bgSecondary)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
        }
    }
}
```

- [ ] **Step 2: ProjectView에 토스트 상태 + 오버레이 추가**

`TeamLongHair/TeamLongHair/Project/ProjectView.swift`에서 `@State private var focusRequest: UUID?`(17행) 아래에 추가:

```swift
    @State private var appState = AppState.shared
    @State private var toastText: String?
```

`body`의 `NavigationSplitView { ... } detail: { ... }` 전체에 붙은 `.toolbar { ... }` 뒤(즉 `.onAppear` 위)에 오버레이와 onChange를 추가한다. `.toolbar { ... }` 블록 닫힘 **바로 아래**에 삽입:

```swift
        .overlay(alignment: .bottom) {
            if let toastText {
                ToastView(text: toastText)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: appState.lastIngest) { _, receipt in
            guard let receipt else { return }
            withAnimation { toastText = "\(receipt.count)개 링크를 '\(receipt.targetName)'에 추가" }
            let shownID = receipt.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                // 그 사이 새 수집이 없었을 때만 숨긴다.
                if appState.lastIngest?.id == shownID {
                    withAnimation { toastText = nil }
                }
            }
        }
```

- [ ] **Step 3: LinkNode가 displayTitle을 쓰도록 수정**

`TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` 36행:

```swift
                        Text("\(link.detail.title)")
```
를
```swift
                        Text(link.detail.displayTitle)
```
로 교체.

- [ ] **Step 4: LinkListView가 displayTitle을 쓰도록 수정**

`TeamLongHair/TeamLongHair/Project/LinkPanel/LinkListView.swift` 63행:

```swift
            Text(link.detail.title)
```
를
```swift
            Text(link.detail.displayTitle)
```
로 교체.

- [ ] **Step 5: 파일 등록**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Project ToastView.swift
```
Expected: `Added ToastView.swift to group Project`

- [ ] **Step 6: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: 수동 QA**

Xcode Run 후:
1. 캔버스/메뉴바 드롭 시 하단에 "N개 링크를 'OO'에 추가" 토스트가 잠깐 뜨고 사라지는지.
2. 드롭 직후(메타데이터 도착 전) 노드/리스트가 빈 제목이 아니라 호스트(예: youtube.com)로 보이는지.
3. 메타데이터 도착 후 실제 제목으로 바뀌는지.

- [ ] **Step 8: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Project/ToastView.swift \
        TeamLongHair/TeamLongHair/Project/ProjectView.swift \
        TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift \
        TeamLongHair/TeamLongHair/Project/LinkPanel/LinkListView.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add ingest toast feedback and blank-title display fallback"
```

---

## 실행 순서/의존성 요약

1. **Task 1** — 순수 로직(리졸버 + displayTitle), 유일한 완전 TDD. 이후 모든 태스크의 기반.
2. **Task 2** — 공유 컨테이너, LinkIngest, URL 로더, displayTitle 확장.
3. **Task 3** — CaptureTarget 글루, lastIngest, 플로팅 패널 리팩터(회귀 확인).
4. **Task 4** — 메뉴바(StatusBarController + 팝오버).
5. **Task 5** — 캔버스 드롭.
6. **Task 6** — 토스트 + 표시 폴백.

각 태스크는 빌드 성공(그리고 Task 1은 로직 테스트 통과)으로 게이트한다. SwiftData/AppKit 경로(Task 3–6)는 자동 테스트가 불가하므로 명시된 수동 QA로 검증한다 — 이는 이 코드베이스의 알려진 제약이다.
