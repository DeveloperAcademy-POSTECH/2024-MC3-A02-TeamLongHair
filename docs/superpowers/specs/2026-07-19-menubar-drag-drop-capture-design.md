# 메뉴바 상주 + 브라우저 탭 드래그앤드롭 캡처 — 설계

**날짜:** 2026-07-19
**상태:** 승인 대기(사용자 검토)

## 배경 / 목적

현재 링크 캡처 경로는 하나뿐이다: 전역 단축키(⌘⇧G)로 플로팅 패널을 띄우고 AppleScript로 현재 탭 URL/제목을 자동 채운 뒤 저장. 이 경로는 **손쉬운 사용 + 자동화** 두 권한에 의존하며 OS 업데이트마다 권한 재부여가 필요하다.

이 기능은 **두 번째(그리고 권한이 필요 없는) 캡처 경로**를 추가한다: 브라우저 탭을 드래그해서

1. **메뉴바 아이콘**에 떨어뜨리거나(메인 창이 닫혀 있어도 동작), 또는
2. **캔버스**의 빈 공간/노드 위에 떨어뜨리면

곧바로 노드로 추가된다. 탭을 드래그하면 URL이 드래그 페이스트보드에 실려 오므로 브라우저를 제어할 필요가 없다 → **Accessibility/Automation 권한 불필요**. 기존 단축키 경로는 그대로 유지되며, 이 기능은 그것을 **대체가 아니라 보완**한다.

## 목표 / 비목표

**목표**
- 메뉴바 상주(NSStatusItem) + 클릭 시 팝오버(드롭존 / 현재 대상 표시 / 앱 열기)
- 메뉴바 아이콘에 **직접** 탭 드롭 → 마지막으로 본 프로젝트/페이지로 수집
- 캔버스에 탭 드롭 → 빈 곳이면 루트, 노드 위면 그 자식으로 추가(커서 아래 노드 하이라이트)
- **여러 탭 동시 드롭** 지원(모두 형제/루트로 추가)
- 드롭된 URL의 파비콘·썸네일·제목·설명 자동 취득(기존 `LinkMetadataApply` 재사용)
- 세 캡처 경로(플로팅 패널·메뉴바·캔버스)가 **하나의 수집 로직**을 공유
- 어디에 추가됐는지 사용자에게 피드백(토스트 + 팝오버 확인 문구)

**비목표(후속 v2)**
- 팝오버 내 "최근 수집" 목록/미니 미리보기
- 메뉴바 상주 on/off 설정
- 드롭 위치(x,y)를 노드 좌표로 정밀 배치(현재 레이아웃은 tidy-tree 자동 배치이므로 위치는 레이아웃이 결정)

## 아키텍처 개요

```
드래그 소스(브라우저 탭) ──▶ 드롭 표면
                              ├─ 메뉴바: StatusItemDropView(AppKit) ─┐
                              └─ 캔버스: CanvasDropDelegate(SwiftUI) ─┤
                                                                     ▼
                                            CaptureTarget.resolvePage(appState, context)  ← 대상 페이지 결정
                                                                     ▼
                                            LinkIngest.addLinks(urls, to: page, parent:)   ← 공용 수집
                                                                     ▼
                                            LinkMetadataApply.fetchAndApply(...)           ← 메타데이터(기존)
                                                                     ▼
                                            AppState.lastIngest = IngestReceipt(...)       ← 피드백 신호
```

핵심 공유물:
- **AppModelContainer.shared** — 단일 `ModelContainer`. App과 AppDelegate(메뉴바)가 같은 인스턴스를 써야 메뉴바 드롭이 열려 있는 창에 즉시 반영된다.
- **LinkIngest** — URL→노드 생성의 단일 출처. 플로팅 패널의 인라인 저장 로직도 이걸 쓰도록 리팩터.
- **CaptureTarget** — "지금 어느 페이지에 넣을지" 결정(순수 로직 + SwiftData 글루 분리).

## 컴포넌트 상세

### 1. AppModelContainer (신규, `Utils/AppModelContainer.swift`)

컨테이너 생성을 한 곳으로 모은다. 현재 `TeamLongHairApp`의 인라인 클로저를 이걸로 대체.

```swift
enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Project.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Could not create ModelContainer: \(error)") }
    }()
}
```

- `TeamLongHairApp`은 `.modelContainer(AppModelContainer.shared)` 사용(두 군데 모두 동일 인스턴스).
- 메뉴바 코드(AppDelegate 소유)는 `AppModelContainer.shared.mainContext`로 쓰기. mainContext는 SwiftData 기본 자동 저장이며, UI가 관찰하는 컨텍스트와 동일 → 드롭이 열린 창에 라이브 반영.
- 스키마 변경 없음(기존 `Schema([Project.self])` 그대로) → 데이터 마이그레이션 없음.

### 2. LinkIngest (신규, `Utils/LinkIngest.swift`)

세 경로가 공유하는 노드 생성 로직. `@MainActor`(SwiftData mainContext + LinkMetadataApply가 MainActor).

```swift
@MainActor
enum LinkIngest {
    /// URL 하나를 page(또는 parent 하위)에 노드로 추가하고 메타데이터 취득을 건다.
    /// title 미지정 시 빈 문자열로 두어 메타데이터가 실제 제목을 채우게 한다.
    @discardableResult
    static func addLink(url: URL, title: String = "",
                        to page: Page, parent: Link? = nil) -> Link {
        let detail = LinkDetail(URL: url.absoluteString, title: title)
        let siblings = parent?.sortedSubLinks ?? page.sortedLinks
        let link = Link(detail: detail, sortIndex: (siblings.last?.sortIndex ?? -1) + 1)
        if let parent { parent.subLinks.append(link) } else { page.links.append(link) }
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

- `FloatingPanelView`의 저장 블록(현재 `LinkDetail`/`Link` 직접 생성 + `targetPage.links.append` + `fetchAndApply`)을 `LinkIngest.addLink(url:title:to:)` 호출로 교체(제목은 패널 입력값 유지). 패널의 `panelURLText`는 `LinkMetadataParsing.normalizedURL(from:)`로 URL 변환 후 전달; 변환 실패 시 저장하지 않고 URL 필드로 포커스 되돌림.
- `Link`가 컨테이너에 속한 `page`/`parent`의 관계 배열에 append되면 컨텍스트에 삽입되므로 `LinkMetadataApply`의 `detail.modelContext != nil` 가드를 통과한다.

### 3. CaptureTarget (신규, `Utils/CaptureTarget.swift`)

"지금 어느 페이지에 넣을지"를 결정. **순수 리졸버**(테스트 가능)와 **SwiftData 글루**(기본 프로젝트 생성)를 분리.

```swift
// 순수 로직 — 테스트 대상
struct ProjectRef { let id: UUID; let pageIDs: [UUID] }

enum CaptureResolution: Equatable {
    case existing(projectIndex: Int, pageIndex: Int)
    case createDefault
}

enum CaptureTargetResolver {
    /// projects는 최근 편집 순(내림차순). 규칙:
    /// 1) currentProjectID가 매칭되면 그 프로젝트, 그 안에서 currentPageID 매칭 페이지;
    ///    페이지 미매칭이면 그 프로젝트의 0번 페이지.
    /// 2) currentProjectID 미매칭이면 0번(가장 최근) 프로젝트의 0번 페이지.
    /// 3) projects가 비면 createDefault.
    static func resolve(projects: [ProjectRef],
                        currentProjectID: UUID?,
                        currentPageID: UUID?) -> CaptureResolution {
        guard !projects.isEmpty else { return .createDefault }
        let pIndex = currentProjectID.flatMap { id in projects.firstIndex { $0.id == id } } ?? 0
        let pageIDs = projects[pIndex].pageIDs
        guard !pageIDs.isEmpty else { return .existing(projectIndex: pIndex, pageIndex: 0) }
        let pageIndex = currentPageID.flatMap { id in pageIDs.firstIndex(of: id) } ?? 0
        return .existing(projectIndex: pIndex, pageIndex: pageIndex)
    }
}
```

```swift
// SwiftData 글루 — 실제 Page 반환(필요 시 기본 프로젝트 생성)
@MainActor
enum CaptureTarget {
    static func resolvePage(appState: AppState, context: ModelContext) -> Page? {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.lastEditDate, order: .reverse)])
        let projects = (try? context.fetch(descriptor)) ?? []
        let refs = projects.map { ProjectRef(id: $0.id, pageIDs: $0.pages.map(\.id)) }
        switch CaptureTargetResolver.resolve(projects: refs,
                                             currentProjectID: appState.currentProjectID,
                                             currentPageID: appState.currentPageID) {
        case .existing(let pi, let gi):
            let project = projects[pi]
            let pages = project.pages
            guard pages.indices.contains(gi) else { return pages.first }
            return pages[gi]
        case .createDefault:
            let project = Project(title: "Untitled")   // init이 "Untitled" 페이지 1개 생성
            context.insert(project)
            return project.pages.first
        }
    }
}
```

- 주: `resolve`가 인덱스를 반환하고 글루가 같은 정렬된 배열로 역참조하므로 순서가 일치한다.
- `pageIDs`가 빈 프로젝트라는 상태는 정상 앱에서 발생하지 않지만(프로젝트는 항상 페이지≥1) 방어적으로 0번 폴백.

### 4. StatusBarController (신규, `Utils/StatusBarController.swift`, AppKit)

메뉴바 상주 + 아이콘 직접 드롭 + 클릭 팝오버. AppDelegate가 소유.

- `NSStatusItem`(`.variableLength`), 버튼 이미지는 템플릿 SF Symbol(예: `point.3.filled.connected.trianglepath.dotted` 또는 앱 심볼) → 메뉴바 라이트/다크 자동 대응.
- **직접 드롭**: 버튼 위에 `StatusItemDropView: NSView`를 얹어 `registerForDraggedTypes([.URL, .fileURL, .string])`. `draggingEntered`에서 `.copy` 반환 + 버튼 강조(선택), `performDragOperation`에서:
  1. `pasteboard.readObjects(forClasses: [NSURL.self])` → `[URL]`; 비면 `.string` → `LinkMetadataParsing.normalizedURL(from:)`로 폴백.
  2. http/https 스킴만 유지(무효/`chrome://` 등 제거).
  3. `CaptureTarget.resolvePage(appState:, context: AppModelContainer.shared.mainContext)`로 대상 페이지.
  4. `LinkIngest.addLinks(urls, to: page)` → 추가 개수.
  5. `AppState.shared.lastIngest = IngestReceipt(count:, targetName: "프로젝트/페이지")`.
  유효 URL이 0개면 아무 것도 하지 않음(크래시 없음).
- **클릭**: 버튼 액션이 `NSPopover` 토글. 팝오버 콘텐츠는 `NSHostingController(rootView: MenuBarPanelView().environment(AppState.shared).modelContainer(AppModelContainer.shared))`.
- **앱 열기 콜백**: `NSApp.activate(ignoringOtherApps: true)` + 첫 창 `makeKeyAndOrderFront`. 창이 하나뿐인 WindowGroup이므로 v1은 이 수준으로 충분(완전히 닫힌 창 복원은 v2).

### 5. MenuBarPanelView (신규, `FloatingPanel/MenuBarPanelView.swift`, SwiftUI)

팝오버 콘텐츠(고정 폭 ~300).

- 헤더: 앱 이름 + 아이콘.
- **드롭존**: 파선 테두리 카드 + "여기로 브라우저 탭을 끌어놓으세요". `.onDrop(of: [.url, .text], isTargeted: $isTargeted)`; 드롭 시 StatusBar와 동일 파이프라인(대상 해석 → LinkIngest → lastIngest). isTargeted면 강조.
- **현재 대상 표시**: `CaptureTarget`이 해석할 프로젝트/페이지 이름을 읽어 "→ 프로젝트 · 페이지"로 표시(어디로 갈지 미리 보임). `@Environment(\.modelContext)` + `AppState`로 계산.
- **확인 문구**: `appState.lastIngest`가 바뀌면 "N개 링크를 'OO'에 추가됨"을 잠깐 표시.
- **버튼**: "앱 열기"(StatusBarController의 콜백 호출).

### 6. CanvasDropDelegate + CanvasContentView 수정 (`Project/Page/Canvas/CanvasView.swift`)

외부 URL 드롭을 캔버스에서 받는다. `CanvasContentView`의 로컬 좌표계는 `scaleEffect`/`offset` 변환 **이전**의 콘텐츠 좌표이므로, `DropInfo.location`이 `layout.positions`와 같은 좌표계 → 기존 `nodeID(at:)`를 그대로 재사용(별도 역산 불필요).

```swift
struct CanvasDropDelegate: DropDelegate {
    let page: Page
    let layout: TreeLayoutResult
    let context: ModelContext
    @Binding var dropTargetID: UUID?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropTargetID = nodeID(at: info.location)   // 커서 아래 노드 하이라이트
        return DropProposal(operation: .copy)
    }
    func dropExited(info: DropInfo) { dropTargetID = nil }

    func performDrop(info: DropInfo) -> Bool {
        let parentID = nodeID(at: info.location)      // 있으면 그 자식, 없으면 루트
        let providers = info.itemProviders(for: [.url, .text])
        loadURLs(from: providers) { urls in           // @MainActor로 hop
            let parent = parentID.flatMap { findLink($0, in: page.links) }
            LinkIngest.addLinks(urls, to: page, parent: parent)
            AppState.shared.lastIngest = IngestReceipt(count: urls.count,
                                                       targetName: page.title)
        }
        dropTargetID = nil
        return !providers.isEmpty
    }
}
```

- `CanvasContentView`에 `.onDrop(of: [.url, .text], delegate: CanvasDropDelegate(...))` 부착. 기존 `dropTargetID @State`를 외부 드롭 하이라이트에도 재사용(노드 드래그와 시각적으로 일관).
- URL 로딩: `NSItemProvider`에서 `.url`은 `loadObject(ofClass: URL.self)`, 폴백으로 `.text`를 `normalizedURL(from:)`. http/https만 유지. 로딩 완료 후 MainActor에서 `LinkIngest` 호출.
- `nodeID(at:)`/`findLink`는 현재 `CanvasContentView`에 이미 있으므로 델리게이트에서 공유할 수 있게 파일 스코프 헬퍼로 노출하거나 델리게이트에 동일 로직을 둔다(DRY: `nodeID(at:in layout:excluding:)`를 파일 프라이빗 자유 함수로 추출해 뷰와 델리게이트가 공유).

### 7. 피드백: IngestReceipt + ToastView

- `AppState`에 추가: `var lastIngest: IngestReceipt?`.
  ```swift
  struct IngestReceipt: Equatable { let id = UUID(); let count: Int; let targetName: String }
  ```
- `ToastView`(신규, 소형): "N개 링크를 'OO'에 추가"를 하단에 잠깐 표시 후 자동 소멸. `ProjectView`(또는 `HomeView`)에 `.overlay`로 부착, `onChange(of: appState.lastIngest)`로 트리거. 창이 열려 있을 때만 보임(메뉴바 드롭은 팝오버 확인 문구가 보완).

### 8. 표시 폴백: LinkDetail.displayTitle (`Model/LinkModel.swift` + 순수 헬퍼)

드롭 직후~메타데이터 도착 전, 또는 메타데이터 실패 시 노드/리스트가 빈 제목으로 보이지 않게 한다.

- 순수 헬퍼(테스트 대상), `Utils/LinkMetadataParsing.swift`에 추가:
  ```swift
  static func displayTitle(title: String, urlString: String) -> String {
      let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
      if !t.isEmpty { return t }
      if let host = URL(string: urlString)?.host { return host }
      return urlString
  }
  ```
- `extension LinkDetail { var displayTitle: String { LinkMetadataParsing.displayTitle(title: title, urlString: URL) } }`
- `LinkNode`와 `LinkListView`가 `detail.title` 대신 `detail.displayTitle`을 표시(빈 제목 노드 방지).

## 데이터 흐름 요약

1. 사용자가 브라우저 탭을 드래그 → 페이스트보드에 URL(들).
2. 드롭 표면(메뉴바 `StatusItemDropView` / 캔버스 `CanvasDropDelegate`)이 URL 배열 추출, http/https만 통과.
3. 대상 페이지 결정: 메뉴바는 `CaptureTarget.resolvePage`(마지막 본 프로젝트/페이지, 폴백/기본생성), 캔버스는 현재 페이지 + 커서 아래 노드(있으면 부모).
4. `LinkIngest.addLinks` → `Link`/`LinkDetail` 생성, sortIndex 부여, 관계 배열 append, `LinkMetadataApply.fetchAndApply` 비동기 취득.
5. `AppState.lastIngest` 갱신 → 토스트/팝오버 확인.
6. 메타데이터 도착 시 파비콘/썸네일/제목/설명 반영, 노드/상세가 자동 갱신.

## 오류 처리

- 유효 URL 0개(빈/무효/비 http 스킴) → 무시, 크래시 없음.
- 대상 프로젝트/페이지 없음 → 기본 "Untitled" 프로젝트 자동 생성 후 수집.
- 메타데이터 취득 실패 → 기존대로 필드 nil 폴백(파비콘 globe, 제목은 `displayTitle`로 호스트 표시).
- 취득 중 URL 변경/모델 삭제 → 기존 `LinkMetadataApply` 가드가 오래된 쓰기 방지.
- `chrome://`, `about:` 등 비 http 스킴 → `LinkMetadataService`가 이미 nil 반환(크래시 방지). 드롭 단계에서도 스킴 필터로 제외.

## 테스트

**순수 로직(swiftc 로직 테스트, `scripts/run_canvas_tests.sh` 방식 확장)**
- `CaptureTargetResolver.resolve`:
  - current 프로젝트/페이지 모두 매칭 → 해당 인덱스.
  - current 페이지가 삭제됨(프로젝트만 매칭) → 그 프로젝트 0번 페이지.
  - current 프로젝트가 삭제됨 → 0번(최근) 프로젝트 0번 페이지.
  - current 둘 다 nil → 0번/0번.
  - projects 빈 배열 → `.createDefault`.
- `LinkMetadataParsing.displayTitle`:
  - 제목 있음 → 제목.
  - 제목 공백/빈 문자열 + 유효 URL → 호스트.
  - 제목 빈 + URL 파싱 실패 → 원본 문자열.

**수동 QA(SwiftData/AppKit — swiftc 불가)**
- 메뉴바 아이콘 등장, 클릭 시 팝오버(드롭존/현재 대상/앱 열기).
- 브라우저 탭 1개를 메뉴바 아이콘에 드롭 → 마지막 본 페이지에 노드 추가 + 확인 문구.
- 탭 여러 개 선택 후 메뉴바에 드롭 → 모두 추가.
- 캔버스 빈 곳 드롭 → 루트 노드, 노드 위 드롭 → 그 자식(드래그 중 대상 노드 하이라이트).
- 메인 창 닫은 상태에서 메뉴바 드롭 → 데이터 반영(다시 열어 확인).
- 프로젝트가 하나도 없을 때 메뉴바 드롭 → 기본 프로젝트 생성 후 추가.
- 플로팅 패널 저장이 리팩터 후에도 동일하게 동작(회귀 없음).
- 파비콘/썸네일/제목 자동 취득 반영.

## 파일 요약

| 파일 | 변경 |
|---|---|
| `Utils/AppModelContainer.swift` | 신규 — 공유 컨테이너 |
| `Utils/LinkIngest.swift` | 신규 — 공용 수집 |
| `Utils/CaptureTarget.swift` | 신규 — 순수 리졸버 + 글루 |
| `Utils/StatusBarController.swift` | 신규 — 메뉴바 + 아이콘 드롭 |
| `FloatingPanel/MenuBarPanelView.swift` | 신규 — 팝오버 콘텐츠 |
| `Project/.../ToastView.swift` | 신규 — 수집 피드백 |
| `Utils/LinkMetadataParsing.swift` | 수정 — `displayTitle` 추가 |
| `Model/LinkModel.swift` | 수정 — `LinkDetail.displayTitle` |
| `Utils/AppState.swift` | 수정 — `lastIngest`/`IngestReceipt` |
| `Utils/AppDelegate.swift` | 수정 — StatusBarController 생성/보유 |
| `TeamLongHairApp.swift` | 수정 — `AppModelContainer.shared` 사용 |
| `FloatingPanel/FloatingPanelView.swift` | 수정 — 저장을 `LinkIngest`로 |
| `Project/Page/Canvas/CanvasView.swift` | 수정 — `CanvasDropDelegate` + `.onDrop` |
| `Project/.../LinkNode.swift`, `LinkListView.swift` | 수정 — `displayTitle` 표시 |
| `scripts/` 로직 테스트 | 확장 — resolver/displayTitle |

**엔타이틀먼트/권한 변경 없음.** 드래그앤드롭·메뉴바 모두 추가 권한이 필요 없다.
