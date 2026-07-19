# 프로젝트 카드 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 프로젝트 카드의 빈 회색 커버를 파비콘 모자이크(없으면 제목 색조 모노그램)로 바꾸고, 개수·상대날짜 메타·hover·빈 상태를 추가한다.

**Architecture:** 순수 포맷팅(`ProjectCardFormatting` — 색조/모노그램/상대날짜)은 프레임워크 의존 없이 swiftc로 테스트하고, `Project` 확장이 파비콘/개수를 뽑는다. `ProjectCoverView`가 파비콘 유무로 모자이크/모노그램을 선택 렌더하며, `ProjectGallery`가 카드·hover·메뉴·빈 상태를 구성한다.

**Tech Stack:** macOS 14+, SwiftUI, SwiftData, AppKit(NSImage), swiftc 기반 순수 로직 테스트.

## Global Constraints

- 커버: 파비콘이 있으면 **파비콘 모자이크**(host 기준 중복 제거, 최대 9개), 없으면 **제목 색조 그라데이션 + 첫 글자 모노그램**.
- 색조는 **결정적 해시**로 산출한다(Swift 기본 `Hasher`는 실행마다 시드가 달라 색이 바뀌므로 금지). FNV-1a를 유니코드 스칼라에 적용.
- 상대 날짜 카피: 같은 날 "오늘 편집", 하루 전 "어제 편집", 그 외 "N일 전 편집"(미래 날짜는 "오늘 편집").
- 순수 로직(색조·모노그램·상대날짜)은 프레임워크 의존 없는 파일에 두어 `scripts/run_canvas_tests.sh`(swiftc)로 테스트 가능해야 한다.
- 기존 `LinkDetail.faviconData`를 읽기만 한다(스키마/엔타이틀먼트 변경 없음).
- 새 Swift 파일은 `ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Home <File.swift>`로 등록한다(파일은 먼저 `TeamLongHair/TeamLongHair/Home/` 폴더에 존재해야 함).
- 앱 빌드 검증: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build` → `** BUILD SUCCEEDED **`.

---

## 파일 구조

**신규**
- `TeamLongHair/TeamLongHair/Home/ProjectCardFormatting.swift` — 순수 색조/모노그램/상대날짜(Foundation only, swiftc 테스트)
- `TeamLongHair/TeamLongHair/Home/ProjectCardData.swift` — `Project` 확장(totalLinkCount, mosaicFavicons)
- `TeamLongHair/TeamLongHair/Home/ProjectCoverView.swift` — ProjectCoverView + FaviconMosaic + MonogramCover

**수정**
- `TeamLongHair/TeamLongHair/Home/ProjectGallery.swift` — 카드 재구성, hover, 메뉴 한글화, 빈 상태, 그리드, createProject 콜백
- `TeamLongHair/TeamLongHair/Home/HomeView.swift` — 헤더 색, createProject 전달
- `scripts/run_canvas_tests.sh`, `CanvasLogicTests/main.swift` — 포맷팅 테스트

---

### Task 1: 순수 포맷팅 ProjectCardFormatting (TDD)

프레임워크 의존이 없는 순수 함수. 유일하게 완전 TDD가 가능한 태스크.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Home/ProjectCardFormatting.swift`
- Modify: `scripts/run_canvas_tests.sh` (swiftc 입력에 파일 추가)
- Test: `CanvasLogicTests/main.swift` (파일 끝 `if failures > 0` 직전에 케이스 추가)

**Interfaces:**
- Produces: `enum ProjectCardFormatting { static func stableHue(for: String) -> Double; static func monogram(for: String) -> String; static func relativeEditLabel(from: Date, now: Date, calendar: Calendar = .current) -> String }`

- [ ] **Step 1: 테스트 추가 (실패 확인용)**

`CanvasLogicTests/main.swift`의 맨 끝, `if failures > 0 { ... }` 줄 **바로 위**에 추가한다:

```swift
// MARK: - ProjectCardFormatting tests
do {
    // stableHue: 결정적 + 0..<1 범위
    let h1 = ProjectCardFormatting.stableHue(for: "MC3테스트")
    let h2 = ProjectCardFormatting.stableHue(for: "MC3테스트")
    expect(h1 == h2, "stableHue 결정적")
    expect(h1 >= 0.0 && h1 < 1.0, "stableHue 0..<1 범위")

    // monogram
    expectEqual(ProjectCardFormatting.monogram(for: "MC3테스트"), "M", "monogram 첫 글자 대문자")
    expectEqual(ProjectCardFormatting.monogram(for: "일본취업"), "일", "monogram 한글 첫 글자")
    expectEqual(ProjectCardFormatting.monogram(for: "  abc"), "A", "monogram trim + 대문자")
    expectEqual(ProjectCardFormatting.monogram(for: ""), "?", "monogram 빈 문자열 → ?")
    expectEqual(ProjectCardFormatting.monogram(for: "   "), "?", "monogram 공백 → ?")

    // relativeEditLabel: 고정 UTC 달력 + 명시적 날짜로 결정적 검증
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneDay = now.addingTimeInterval(-24 * 3600)
    let threeDays = now.addingTimeInterval(-3 * 24 * 3600)
    let future = now.addingTimeInterval(24 * 3600)
    expectEqual(ProjectCardFormatting.relativeEditLabel(from: now, now: now, calendar: cal), "오늘 편집", "같은 시각 → 오늘")
    expectEqual(ProjectCardFormatting.relativeEditLabel(from: oneDay, now: now, calendar: cal), "어제 편집", "하루 전 → 어제")
    expectEqual(ProjectCardFormatting.relativeEditLabel(from: threeDays, now: now, calendar: cal), "3일 전 편집", "3일 전")
    expectEqual(ProjectCardFormatting.relativeEditLabel(from: future, now: now, calendar: cal), "오늘 편집", "미래 → 오늘")
}
```

- [ ] **Step 2: 테스트 실행 → 컴파일 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: FAIL — `error: cannot find 'ProjectCardFormatting' in scope`

- [ ] **Step 3: ProjectCardFormatting.swift 작성**

`TeamLongHair/TeamLongHair/Home/ProjectCardFormatting.swift`:

```swift
//
//  ProjectCardFormatting.swift
//  TeamLongHair
//
//  프로젝트 카드용 순수 포맷팅(색조/모노그램/상대날짜). 프레임워크 의존 없음(swiftc 테스트 대상).
//

import Foundation

enum ProjectCardFormatting {
    /// 제목을 결정적 해시(FNV-1a)로 0.0..<1.0 색조로 변환. Swift 기본 Hasher는 실행마다
    /// 시드가 달라 색이 바뀌므로 쓰지 않는다.
    static func stableHue(for title: String) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for scalar in title.unicodeScalars {
            hash ^= UInt64(scalar.value)
            hash = hash &* 0x100000001b3
        }
        return Double(hash % 360) / 360.0
    }

    /// 표시용 첫 글자(대문자). 공백/빈 문자열이면 "?".
    static func monogram(for title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    /// 상대 편집 라벨. now를 주입받아 테스트 가능. 달력 일자 경계(자정) 기준.
    /// 같은 날 → "오늘 편집", 하루 전 → "어제 편집", 그 외 → "N일 전 편집". 미래는 "오늘 편집".
    static func relativeEditLabel(from date: Date, now: Date,
                                  calendar: Calendar = .current) -> String {
        let startOfDate = calendar.startOfDay(for: date)
        let startOfNow = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0
        switch days {
        case ..<1: return "오늘 편집"
        case 1:    return "어제 편집"
        default:   return "\(days)일 전 편집"
        }
    }
}
```

- [ ] **Step 4: 테스트 러너에 순수 파일 등록**

`scripts/run_canvas_tests.sh`의 `swiftc -o "$OUT" \` 블록에서 `HotKeyModifiers.swift` 줄 바로 아래에 한 줄 추가:

```bash
  TeamLongHair/TeamLongHair/Home/ProjectCardFormatting.swift \
```

- [ ] **Step 5: 테스트 실행 → 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: PASS — 마지막 줄 `ALL TESTS PASSED`

- [ ] **Step 6: 앱 프로젝트에 파일 등록**

Run:
```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Home ProjectCardFormatting.swift
```
Expected: `Added ProjectCardFormatting.swift to group Home`

- [ ] **Step 7: 앱 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Home/ProjectCardFormatting.swift \
        scripts/run_canvas_tests.sh CanvasLogicTests/main.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add ProjectCardFormatting pure logic with tests"
```

---

### Task 2: ProjectCardData (Project 확장)

프로젝트에서 카드 렌더용 파생값을 뽑는다. SwiftData 접근이라 유닛 테스트 없이 빌드로 검증.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Home/ProjectCardData.swift`

**Interfaces:**
- Consumes: 기존 `Page.allLinks`, `LinkDetail.faviconData`, `LinkDetail.URL`.
- Produces: `extension Project { var totalLinkCount: Int; func mosaicFavicons(max: Int = 9) -> [Data] }`

- [ ] **Step 1: ProjectCardData.swift 작성**

`TeamLongHair/TeamLongHair/Home/ProjectCardData.swift`:

```swift
//
//  ProjectCardData.swift
//  TeamLongHair
//
//  프로젝트 카드 렌더에 필요한 파생값(전체 링크 수, 커버용 파비콘)을 뽑는다.
//

import Foundation

extension Project {
    /// 모든 페이지의 링크 트리를 평탄화한 전체 링크 수.
    var totalLinkCount: Int {
        pages.reduce(0) { $0 + $1.allLinks.count }
    }

    /// 커버 모자이크용 파비콘. host 기준 중복 제거 후 정렬 순서로 최대 max개.
    /// host를 못 구하면 URL 문자열을 키로 사용한다.
    func mosaicFavicons(max: Int = 9) -> [Data] {
        var seenKeys = Set<String>()
        var result: [Data] = []
        for page in pages {
            for link in page.allLinks {
                guard let data = link.detail.faviconData else { continue }
                let key = URL(string: link.detail.URL)?.host ?? link.detail.URL
                if seenKeys.contains(key) { continue }
                seenKeys.insert(key)
                result.append(data)
                if result.count >= max { return result }
            }
        }
        return result
    }
}
```

- [ ] **Step 2: 파일 등록**

Run:
```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Home ProjectCardData.swift
```
Expected: `Added ProjectCardData.swift to group Home`

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Home/ProjectCardData.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add Project card-data derivation (link count, mosaic favicons)"
```

---

### Task 3: ProjectCoverView (모자이크 + 모노그램)

커버 렌더. 파비콘이 유효하면 모자이크, 아니면 모노그램.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Home/ProjectCoverView.swift`

**Interfaces:**
- Consumes: `ProjectCardFormatting.stableHue(for:)`/`monogram(for:)`(Task 1), `Project.mosaicFavicons(max:)`(Task 2), 기존 `.gray050` 색 에셋.
- Produces: `struct ProjectCoverView: View { let project: Project }`

- [ ] **Step 1: ProjectCoverView.swift 작성**

`TeamLongHair/TeamLongHair/Home/ProjectCoverView.swift`:

```swift
//
//  ProjectCoverView.swift
//  TeamLongHair
//
//  프로젝트 카드 커버. 링크 파비콘이 있으면 모자이크, 없으면 제목 색조 모노그램.
//

import AppKit
import SwiftUI

struct ProjectCoverView: View {
    let project: Project

    var body: some View {
        // NSImage로 실제 디코드되는 파비콘만 유효로 취급한다.
        let usable = project.mosaicFavicons().filter { NSImage(data: $0) != nil }
        Group {
            if usable.isEmpty {
                MonogramCover(title: project.title)
            } else {
                FaviconMosaic(favicons: usable)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 제목 색조 2톤 그라데이션 + 가운데 첫 글자.
struct MonogramCover: View {
    let title: String

    var body: some View {
        let hue = ProjectCardFormatting.stableHue(for: title)
        LinearGradient(
            colors: [Color(hue: hue, saturation: 0.55, brightness: 0.82),
                     Color(hue: hue, saturation: 0.72, brightness: 0.58)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        .overlay {
            Text(ProjectCardFormatting.monogram(for: title))
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

/// 파비콘 타일 격자. 커버 높이에 맞춰 적응형으로 채우고 넘치면 클립된다.
struct FaviconMosaic: View {
    let favicons: [Data]

    private let columns = [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(favicons.enumerated()), id: \.offset) { _, data in
                if let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .aspectRatio(1, contentMode: .fit)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.gray050)
    }
}
```

- [ ] **Step 2: 파일 등록**

Run:
```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Home ProjectCoverView.swift
```
Expected: `Added ProjectCoverView.swift to group Home`

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Home/ProjectCoverView.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add ProjectCoverView with favicon mosaic and monogram fallback"
```

---

### Task 4: 카드 재구성 + 빈 상태 + 헤더 (ProjectGallery, HomeView)

커버를 카드에 붙이고 메타·hover·메뉴 한글화·빈 상태를 구성한다. HomeView는 헤더 색과 createProject 콜백을 넘긴다.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Home/ProjectGallery.swift`
- Modify: `TeamLongHair/TeamLongHair/Home/HomeView.swift`

**Interfaces:**
- Consumes: `ProjectCoverView(project:)`(Task 3), `ProjectCardFormatting.relativeEditLabel(from:now:)`(Task 1), `Project.totalLinkCount`(Task 2), 기존 `AddProjectButtonStyle`(HomeView), `defaultButtonStyle`(ProjectGallery), `Project.updateTitle(newTitle:)`.
- Produces: `ProjectGallery`에 `createProject: () -> Void` 파라미터 추가.

- [ ] **Step 1: ProjectGallery.swift 전체 교체**

`TeamLongHair/TeamLongHair/Home/ProjectGallery.swift` 전체를 교체:

```swift
//
//  ProjectGallery.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import SwiftUI

struct ProjectGallery: View {
    var projects: [Project]
    let openProject: (Project) -> Void
    let deleteProject: (Project) -> Void
    let createProject: () -> Void

    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var editingProject: Project? = nil
    @State private var hoveredProjectID: UUID? = nil

    var body: some View {
        if projects.isEmpty {
            emptyState
        } else {
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20)], spacing: 24) {
                ForEach(projects) { project in
                    card(project)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    @ViewBuilder
    private func card(_ project: Project) -> some View {
        let isHovered = hoveredProjectID == project.id
        VStack(alignment: .leading, spacing: 8) {
            Button {
                openProject(project)
            } label: {
                ProjectCoverView(project: project)
            }
            .buttonStyle(defaultButtonStyle())

            if isEditing && project.id == editingProject?.id {
                TextField("이름 입력", text: $editingTitle) {
                    project.updateTitle(newTitle: editingTitle)
                    isEditing = false
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(project.title)
                    .foregroundStyle(.primary)
                    .font(.system(size: 16))
                    .lineLimit(1)
            }

            Text(metaText(project))
                .foregroundStyle(.tertiary)
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color.gray.opacity(0.08) : Color.clear)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            if hovering { hoveredProjectID = project.id }
            else if hoveredProjectID == project.id { hoveredProjectID = nil }
        }
        .contextMenu {
            Button("이름 변경") {
                editingTitle = project.title
                editingProject = project
                isEditing = true
            }
            Button("삭제", role: .destructive) {
                deleteProject(project)
            }
            .keyboardShortcut(.delete)
        }
    }

    private func metaText(_ project: Project) -> String {
        let rel = ProjectCardFormatting.relativeEditLabel(from: project.lastEditDate, now: Date())
        return "\(project.pages.count)페이지 · \(project.totalLinkCount)링크 · \(rel)"
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.on.square.dashed")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("아직 프로젝트가 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            Text("새 프로젝트를 만들어 탭을 모아보세요")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Button {
                createProject()
            } label: {
                Text("새 프로젝트 생성")
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(AddProjectButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// TODO: 이후에 rebase 받고 Util 폴더로 뺄 예정
struct defaultButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
```

- [ ] **Step 2: HomeView.swift — 헤더 색 + createProject 전달**

`TeamLongHair/TeamLongHair/Home/HomeView.swift`에서 두 곳을 수정한다.

(a) 44–46행의 헤더 색:
```swift
                Text("프로젝트")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.secondary)
```
를
```swift
                Text("프로젝트")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
```
로.

(b) 65–70행의 `ProjectGallery(...)` 호출에 `createProject` 인자를 추가:
```swift
            ProjectGallery(projects: projects) { project in
                selectedProject = project
            } deleteProject: { project in
                if selectedProject?.id == project.id { selectedProject = nil }
                deleteProject(project)
            }
```
를
```swift
            ProjectGallery(projects: projects, openProject: { project in
                selectedProject = project
            }, deleteProject: { project in
                if selectedProject?.id == project.id { selectedProject = nil }
                deleteProject(project)
            }, createProject: {
                addProject(Project(title: "Untitled \(projects.count + 1)"))
            })
```
로 교체한다. **인자 순서는 반드시 `ProjectGallery`의 저장 프로퍼티 선언 순서(`projects, openProject, deleteProject, createProject`)와 일치해야 한다** — Swift memberwise initializer는 레이블이 있어도 인자 재정렬을 허용하지 않는다. 트레일링 클로저 형태 대신 위처럼 모두 레이블 인자로 명시한다.

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 수동 QA(참고 — GUI 실행 불가)**

정적으로 확인: 카드가 `ProjectCoverView`를 커버로 쓰고, 메타가 `relativeEditLabel`/`totalLinkCount`를 쓰며, hover 상태·컨텍스트 메뉴 한글(이름 변경/삭제)·빈 상태가 배선됐는지. 실기기 QA는 Task 종료 후 사용자 이관: 파비콘 있는/없는 프로젝트 커버, 메타 정확성, hover, 빈 상태, 라이트/다크 대비.

- [ ] **Step 5: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Home/ProjectGallery.swift \
        TeamLongHair/TeamLongHair/Home/HomeView.swift
git commit -m "feat: Redesign project cards with cover, meta, hover, empty state"
```

---

## 실행 순서/의존성 요약

1. **Task 1** — 순수 포맷팅(색조/모노그램/상대날짜), 완전 TDD.
2. **Task 2** — Project 확장(개수/파비콘).
3. **Task 3** — ProjectCoverView(모자이크/모노그램).
4. **Task 4** — 카드 재구성 + 빈 상태 + 헤더 + createProject 배선.

각 태스크는 빌드 성공(Task 1은 로직 테스트 통과)으로 게이트한다. SwiftUI/SwiftData/이미지 경로(Task 2–4)는 자동 테스트가 불가하므로 빌드 + 수동 QA로 검증한다. 전체 완료 후 사용자 실기기 QA: 파비콘 모자이크(host 중복 없이), 모노그램 색(재시작에도 동일), 메타 "N페이지·M링크·오늘/어제/N일 전 편집", hover, 한글 메뉴, 빈 상태, 라이트/다크 대비.
