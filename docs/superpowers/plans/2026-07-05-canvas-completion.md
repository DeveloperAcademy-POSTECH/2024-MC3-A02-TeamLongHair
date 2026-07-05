# 노드맵 캔버스 완성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** NSScrollView 기반 줌/팬 캔버스 + 자동 트리 레이아웃 + 안전한 드래그&드롭 재부모화 + 브라우저 탭 자동 수집을 완성한다.

**Architecture:** 줌/팬은 `NSScrollView(allowsMagnification)`를 `NSViewRepresentable`로 래핑해 OS에 위임한다. 노드 좌표는 순수 함수 `TreeLayout`이 계산하고, 뷰(`CanvasContentView`)는 계산된 좌표에 그리기만 한다. 드롭 검증은 순수 함수 `DropValidator`가 스냅샷(`LayoutNode`) 기반으로 수행하고, SwiftData 변경은 `CanvasViewModel`이 검증 통과 후에만 실행한다.

**Tech Stack:** SwiftUI + AppKit(NSScrollView/NSHostingView), SwiftData, NSAppleScript. 테스트는 `swiftc`로 순수 로직 파일 + 테스트 main을 직접 컴파일해 실행 (Xcode 테스트 타깃 없음 — pbxproj 수술을 피하기 위한 의도적 선택).

**Spec:** `docs/superpowers/specs/2026-07-05-canvas-completion-design.md`

## Global Constraints

- 브랜치: `feat/canvas-completion` (base `dev`). 모든 커밋은 이 브랜치에.
- macOS 배포 타깃 14.1, Xcode 26.2, objectVersion 56 pbxproj (구식 — 새 파일은 반드시 `scripts/xcodeproj_add.rb`로 등록).
- 캔버스 상수는 `CanvasMetrics` 한 곳에만: nodeWidth 244, nodeHeight 118, horizontalGap 80, verticalGap 40, padding 150.
- 줌 배율 0.25 ~ 3.0.
- 최대 트리 깊이 3 (루트 = 깊이 1).
- 드롭 페이로드는 `Link.id.uuidString` (String) — 기존 방식 유지.
- 빌드 확인 명령 (모든 태스크 공통, 이하 "**빌드 확인**"으로 지칭):
  ```bash
  cd /Users/damin/Desktop/AppleDeveloperAcademy/MC3/2024-MC3-A02-TeamLongHair && \
  xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair \
    -configuration Debug -derivedDataPath build build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
  ```
  기대 출력: `** BUILD SUCCEEDED **`
- 로직 테스트 명령 (이하 "**로직 테스트**"): `bash scripts/run_canvas_tests.sh` → 기대 출력 마지막 줄 `ALL TESTS PASSED`
- 앱 실행 (수동 QA): `open build/Build/Products/Debug/TeamLongHair.app`

---

### Task 1: 베이스라인 빌드 + pbxproj 헬퍼 스크립트

구식 pbxproj에 파일을 추가/제거하는 헬퍼를 만들고, 더미 파일 왕복(추가→빌드→제거→빌드)으로 검증한다. 이후 모든 태스크가 이 헬퍼에 의존한다.

**Files:**
- Create: `scripts/xcodeproj_add.rb`
- Create: `scripts/xcodeproj_remove.rb`

**Interfaces:**
- Produces: `ruby scripts/xcodeproj_add.rb <pbxproj경로> <그룹이름> <파일이름>` — 디스크에 이미 존재하는 파일을 앱 타깃 소스로 등록
- Produces: `ruby scripts/xcodeproj_remove.rb <pbxproj경로> <파일이름>` — 파일명이 포함된 모든 pbxproj 라인 제거 (파일명이 프로젝트 내 유일할 때만 사용)

- [ ] **Step 1: 베이스라인 빌드 확인**

**빌드 확인** 명령 실행. 기대: `** BUILD SUCCEEDED **`. 실패하면 오류를 먼저 해결하고 진행 (서명 오류면 이미 CODE_SIGNING_ALLOWED=NO 포함되어 있으니 다른 원인 조사).

- [ ] **Step 2: 추가 스크립트 작성**

`scripts/xcodeproj_add.rb`:

```ruby
#!/usr/bin/env ruby
# Usage: ruby scripts/xcodeproj_add.rb <project.pbxproj> <group_name> <file.swift>
# 파일은 이미 해당 그룹의 폴더에 디스크로 존재해야 한다.
require 'securerandom'

pbxproj, group_name, file_name = ARGV
abort "usage: xcodeproj_add.rb <pbxproj> <group_name> <file.swift>" unless pbxproj && group_name && file_name

text = File.read(pbxproj)
abort "#{file_name} already in project" if text.include?("/* #{file_name} */")

uuid_ref = SecureRandom.hex(12).upcase
uuid_build = SecureRandom.hex(12).upcase

build_line = "\t\t#{uuid_build} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{uuid_ref} /* #{file_name} */; };\n"
text.sub!(/(\/\* Begin PBXBuildFile section \*\/\n)/) { $1 + build_line } or abort "PBXBuildFile section not found"

ref_line = "\t\t#{uuid_ref} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file_name}; sourceTree = \"<group>\"; };\n"
text.sub!(/(\/\* Begin PBXFileReference section \*\/\n)/) { $1 + ref_line } or abort "PBXFileReference section not found"

group_re = /(\/\* #{Regexp.escape(group_name)} \*\/ = \{\s*isa = PBXGroup;\s*children = \(\n)/
text.sub!(group_re) { $1 + "\t\t\t\t#{uuid_ref} /* #{file_name} */,\n" } or abort "group #{group_name} not found"

src_re = /(isa = PBXSourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \(\n)/
text.sub!(src_re) { $1 + "\t\t\t\t#{uuid_build} /* #{file_name} in Sources */,\n" } or abort "Sources build phase not found"

File.write(pbxproj, text)
puts "Added #{file_name} to group #{group_name}"
```

- [ ] **Step 3: 제거 스크립트 작성**

`scripts/xcodeproj_remove.rb`:

```ruby
#!/usr/bin/env ruby
# Usage: ruby scripts/xcodeproj_remove.rb <project.pbxproj> <file.swift>
# 주의: 파일명이 등장하는 모든 라인을 제거하므로 프로젝트 내에서 유일한 파일명에만 사용.
pbxproj, file_name = ARGV
abort "usage: xcodeproj_remove.rb <pbxproj> <file.swift>" unless pbxproj && file_name

text = File.read(pbxproj)
kept = text.lines.reject { |l| l.include?(file_name) }
removed = text.lines.size - kept.size
abort "#{file_name} not found in project" if removed.zero?
File.write(pbxproj, kept.join)
puts "Removed #{removed} lines for #{file_name}"
```

- [ ] **Step 4: 왕복 검증**

```bash
cat > TeamLongHair/TeamLongHair/Utils/PbxprojSmokeTest.swift <<'EOF'
// pbxproj helper smoke test — will be removed
enum PbxprojSmokeTest { static let ok = true }
EOF
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils PbxprojSmokeTest.swift
```
그다음 **빌드 확인** (SUCCEEDED — 그리고 빌드 로그에 `PbxprojSmokeTest.swift` 컴파일이 포함되는지 `xcodebuild ... build 2>&1 | grep PbxprojSmokeTest`로 확인. 포함 안 됐으면 헬퍼가 잘못된 것이므로 수정).

```bash
ruby scripts/xcodeproj_remove.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj PbxprojSmokeTest.swift
rm TeamLongHair/TeamLongHair/Utils/PbxprojSmokeTest.swift
```
다시 **빌드 확인** (SUCCEEDED).

- [ ] **Step 5: 커밋**

```bash
git add scripts/ && git commit -m "chore: Add pbxproj add/remove helper scripts

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: TreeLayout — 자동 트리 레이아웃 (TDD)

**Files:**
- Create: `TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift`
- Create: `CanvasLogicTests/main.swift` (테스트 러너 겸 테스트)
- Create: `scripts/run_canvas_tests.sh`

**Interfaces:**
- Produces:
  ```swift
  struct LayoutNode: Identifiable, Equatable { let id: UUID; var children: [LayoutNode] }
  enum CanvasMetrics { nodeWidth/nodeHeight/horizontalGap/verticalGap/padding: CGFloat, rowPitch/columnPitch: CGFloat }
  struct TreeLayoutResult: Equatable { var positions: [UUID: CGPoint]; var contentSize: CGSize }
  enum TreeLayout { static func compute(roots: [LayoutNode]) -> TreeLayoutResult }
  ```
- `positions`의 좌표는 각 노드의 **좌상단(top-left)**. 부모의 y = 첫 자식의 y. 리프마다 한 행. x = padding + (깊이-1) × columnPitch.

- [ ] **Step 1: 테스트 러너 스크립트 작성**

`scripts/run_canvas_tests.sh`:

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/canvas_logic_tests"
swiftc -o "$OUT" \
  TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift \
  CanvasLogicTests/main.swift
"$OUT"
```

`chmod +x scripts/run_canvas_tests.sh`

- [ ] **Step 2: 실패하는 테스트 작성**

`CanvasLogicTests/main.swift`:

```swift
// swiftc 기반 경량 테스트 러너. Xcode 테스트 타깃 없이 순수 로직을 검증한다.
import CoreGraphics
import Foundation

var failures = 0
func expect(_ cond: Bool, _ msg: String, line: Int = #line) {
    if cond { print("PASS: \(msg)") } else { failures += 1; print("FAIL: \(msg) (main.swift:\(line))") }
}
func expectEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String, line: Int = #line) {
    expect(a == b, "\(msg) — got \(a), expected \(b)", line: line)
}

// MARK: - TreeLayout tests

let P = CanvasMetrics.padding
let CP = CanvasMetrics.columnPitch
let RP = CanvasMetrics.rowPitch

do { // 단일 노드
    let n = LayoutNode(id: UUID(), children: [])
    let r = TreeLayout.compute(roots: [n])
    expectEqual(r.positions[n.id], CGPoint(x: P, y: P), "단일 노드는 (padding, padding)")
    expectEqual(r.contentSize, CGSize(width: 2 * P + CanvasMetrics.nodeWidth,
                                      height: 2 * P + CanvasMetrics.nodeHeight), "단일 노드 콘텐츠 크기")
}

do { // 부모-자식: 자식은 오른쪽 열, 부모 y == 첫 자식 y
    let c = LayoutNode(id: UUID(), children: [])
    let p = LayoutNode(id: UUID(), children: [c])
    let r = TreeLayout.compute(roots: [p])
    expectEqual(r.positions[p.id], CGPoint(x: P, y: P), "부모 위치")
    expectEqual(r.positions[c.id], CGPoint(x: P + CP, y: P), "자식은 같은 행, 다음 열")
}

do { // 루트 2개: 두 번째 루트는 다음 행
    let a = LayoutNode(id: UUID(), children: [])
    let b = LayoutNode(id: UUID(), children: [])
    let r = TreeLayout.compute(roots: [a, b])
    expectEqual(r.positions[b.id], CGPoint(x: P, y: P + RP), "두 번째 루트는 다음 행")
    expectEqual(r.contentSize.height, 2 * P + RP + CanvasMetrics.nodeHeight, "2행 콘텐츠 높이")
}

do { // 자식 2개: 첫째는 부모와 같은 행, 둘째는 다음 행. 순서 보존.
    let c1 = LayoutNode(id: UUID(), children: [])
    let c2 = LayoutNode(id: UUID(), children: [])
    let p = LayoutNode(id: UUID(), children: [c1, c2])
    let r = TreeLayout.compute(roots: [p])
    expectEqual(r.positions[p.id]!.y, r.positions[c1.id]!.y, "부모 y == 첫 자식 y")
    expectEqual(r.positions[c2.id], CGPoint(x: P + CP, y: P + RP), "둘째 자식은 다음 행")
}

do { // 깊이 3 체인: 한 행, 열만 증가
    let g = LayoutNode(id: UUID(), children: [])
    let c = LayoutNode(id: UUID(), children: [g])
    let p = LayoutNode(id: UUID(), children: [c])
    let r = TreeLayout.compute(roots: [p])
    expectEqual(r.positions[g.id], CGPoint(x: P + 2 * CP, y: P), "깊이 3은 세 번째 열")
    expectEqual(r.contentSize.width, 2 * P + 2 * CP + CanvasMetrics.nodeWidth, "3열 콘텐츠 너비")
}

do { // 빈 입력
    let r = TreeLayout.compute(roots: [])
    expect(r.positions.isEmpty, "빈 입력은 빈 결과")
}

do { // 복합: 루트A(자식2, 첫째가 자식1 보유) + 루트B → 행 배정 확인
    let a11 = LayoutNode(id: UUID(), children: [])
    let a1 = LayoutNode(id: UUID(), children: [a11])
    let a2 = LayoutNode(id: UUID(), children: [])
    let a = LayoutNode(id: UUID(), children: [a1, a2])
    let b = LayoutNode(id: UUID(), children: [])
    let r = TreeLayout.compute(roots: [a, b])
    expectEqual(r.positions[a.id]!.y, P, "A는 1행")
    expectEqual(r.positions[a11.id]!.y, P, "A-1-1도 1행 (첫 자식 체인)")
    expectEqual(r.positions[a2.id]!.y, P + RP, "A-2는 2행")
    expectEqual(r.positions[b.id]!.y, P + 2 * RP, "B는 3행")
}

if failures > 0 { print("\(failures) FAILURES"); exit(1) }
print("ALL TESTS PASSED")
```

- [ ] **Step 3: 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: swiftc 컴파일 에러 (`cannot find 'CanvasMetrics' in scope` 등) — 구현 파일이 아직 없으므로.

- [ ] **Step 4: 구현**

`TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift`:

```swift
//
//  TreeLayout.swift
//  TeamLongHair
//
//  순수 레이아웃 계산. SwiftUI/SwiftData에 의존하지 않는다 (swiftc 단독 테스트 대상).
//

import CoreGraphics
import Foundation

/// Link 트리의 경량 스냅샷. 레이아웃/드롭 검증은 이 타입 위에서만 동작한다.
struct LayoutNode: Identifiable, Equatable {
    let id: UUID
    var children: [LayoutNode]

    init(id: UUID = UUID(), children: [LayoutNode] = []) {
        self.id = id
        self.children = children
    }
}

/// 캔버스 치수 상수의 단일 출처.
enum CanvasMetrics {
    static let nodeWidth: CGFloat = 244
    static let nodeHeight: CGFloat = 118
    static let horizontalGap: CGFloat = 80
    static let verticalGap: CGFloat = 40
    static let padding: CGFloat = 150

    static var rowPitch: CGFloat { nodeHeight + verticalGap }
    static var columnPitch: CGFloat { nodeWidth + horizontalGap }
}

struct TreeLayoutResult: Equatable {
    /// 각 노드의 좌상단 좌표
    var positions: [UUID: CGPoint]
    var contentSize: CGSize
}

enum TreeLayout {
    /// 리프마다 한 행을 차지하고, 부모는 첫 자식과 같은 행에 놓는 tidy tree.
    static func compute(roots: [LayoutNode]) -> TreeLayoutResult {
        var positions: [UUID: CGPoint] = [:]
        var nextRow = 0
        var maxDepth = 0

        // 반환값: 이 서브트리에서 이 노드가 배정받은 행
        func assign(_ node: LayoutNode, depth: Int) -> Int {
            maxDepth = max(maxDepth, depth)
            let row: Int
            if node.children.isEmpty {
                row = nextRow
                nextRow += 1
            } else {
                let childRows = node.children.map { assign($0, depth: depth + 1) }
                row = childRows[0]
            }
            positions[node.id] = CGPoint(
                x: CanvasMetrics.padding + CGFloat(depth) * CanvasMetrics.columnPitch,
                y: CanvasMetrics.padding + CGFloat(row) * CanvasMetrics.rowPitch
            )
            return row
        }

        for root in roots {
            _ = assign(root, depth: 0)
        }

        guard nextRow > 0 else {
            return TreeLayoutResult(positions: [:], contentSize: .zero)
        }
        let contentSize = CGSize(
            width: 2 * CanvasMetrics.padding + CGFloat(maxDepth) * CanvasMetrics.columnPitch + CanvasMetrics.nodeWidth,
            height: 2 * CanvasMetrics.padding + CGFloat(nextRow - 1) * CanvasMetrics.rowPitch + CanvasMetrics.nodeHeight
        )
        return TreeLayoutResult(positions: positions, contentSize: contentSize)
    }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: 모든 PASS, 마지막 줄 `ALL TESTS PASSED`

- [ ] **Step 6: 앱 타깃에 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Canvas TreeLayout.swift
```
**빌드 확인** (SUCCEEDED).

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift CanvasLogicTests/ scripts/run_canvas_tests.sh TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add TreeLayout pure layout engine with swiftc-based tests

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: DropValidator — 드롭 검증 (TDD)

**Files:**
- Create: `TeamLongHair/TeamLongHair/Project/Page/Canvas/DropValidator.swift`
- Modify: `CanvasLogicTests/main.swift` (테스트 추가 — `if failures > 0` 줄 **앞에** 삽입)
- Modify: `scripts/run_canvas_tests.sh` (컴파일 대상에 DropValidator.swift 추가)

**Interfaces:**
- Consumes: `LayoutNode` (Task 2)
- Produces:
  ```swift
  enum DropValidator {
      static let maxDepth = 3
      static func canDrop(dragged: UUID, onto target: UUID, roots: [LayoutNode]) -> Bool
      static func find(_ id: UUID, in roots: [LayoutNode]) -> LayoutNode?
      static func depth(of id: UUID, in roots: [LayoutNode]) -> Int?   // 루트 = 1
      static func height(of node: LayoutNode) -> Int                    // 리프 = 1
  }
  ```
- 규칙: 자기 자신 금지, 자기 자손 금지, `target깊이 + dragged서브트리높이 > maxDepth` 금지, 미존재 ID 금지.

- [ ] **Step 1: 러너에 파일 추가**

`scripts/run_canvas_tests.sh`의 swiftc 인자에 한 줄 추가:

```bash
  TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift \
  TeamLongHair/TeamLongHair/Project/Page/Canvas/DropValidator.swift \
  CanvasLogicTests/main.swift
```

- [ ] **Step 2: 실패하는 테스트 작성**

`CanvasLogicTests/main.swift`의 `if failures > 0` 앞에 추가:

```swift
// MARK: - DropValidator tests

do {
    // 트리:  root1 ─ mid ─ leaf   /   root2
    let leaf = LayoutNode(id: UUID(), children: [])
    let mid = LayoutNode(id: UUID(), children: [leaf])       // mid 서브트리 높이 = 2
    let root1 = LayoutNode(id: UUID(), children: [mid])      // root1 서브트리 높이 = 3
    let root2 = LayoutNode(id: UUID(), children: [])
    let roots = [root1, root2]

    expect(!DropValidator.canDrop(dragged: root2.id, onto: root2.id, roots: roots), "자기 자신에게 드롭 금지")
    expect(!DropValidator.canDrop(dragged: root1.id, onto: leaf.id, roots: roots), "자기 자손에게 드롭 금지")
    expect(DropValidator.canDrop(dragged: root2.id, onto: mid.id, roots: roots), "리프를 깊이2에 드롭 = 결과깊이 3 허용")
    expect(!DropValidator.canDrop(dragged: root2.id, onto: leaf.id, roots: roots), "리프를 깊이3에 드롭 = 결과깊이 4 금지")
    expect(DropValidator.canDrop(dragged: mid.id, onto: root2.id, roots: roots), "높이2 서브트리 + 루트(깊이1) = 3 허용")
    expect(!DropValidator.canDrop(dragged: root1.id, onto: root2.id, roots: roots), "높이3 서브트리 + 루트(깊이1) = 4 금지")
    expect(!DropValidator.canDrop(dragged: UUID(), onto: root2.id, roots: roots), "미존재 dragged 금지")
    expect(!DropValidator.canDrop(dragged: root2.id, onto: UUID(), roots: roots), "미존재 target 금지")
}
```

- [ ] **Step 3: 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: 컴파일 에러 (`cannot find 'DropValidator' in scope`)

- [ ] **Step 4: 구현**

`TeamLongHair/TeamLongHair/Project/Page/Canvas/DropValidator.swift`:

```swift
//
//  DropValidator.swift
//  TeamLongHair
//
//  드롭 가능 여부를 스냅샷(LayoutNode) 기반으로 검증하는 순수 로직.
//  SwiftData 변경 전에 반드시 이 검증을 통과해야 한다.
//

import Foundation

enum DropValidator {
    /// 루트 = 깊이 1. 결과 트리의 어떤 노드도 이 깊이를 넘을 수 없다.
    static let maxDepth = 3

    static func canDrop(dragged: UUID, onto target: UUID, roots: [LayoutNode]) -> Bool {
        guard dragged != target else { return false }
        guard let draggedNode = find(dragged, in: roots) else { return false }
        // target이 dragged의 자손이면 사이클 발생 → 금지
        guard find(target, in: draggedNode.children) == nil else { return false }
        guard let targetDepth = depth(of: target, in: roots) else { return false }
        return targetDepth + height(of: draggedNode) <= maxDepth
    }

    static func find(_ id: UUID, in roots: [LayoutNode]) -> LayoutNode? {
        for node in roots {
            if node.id == id { return node }
            if let found = find(id, in: node.children) { return found }
        }
        return nil
    }

    static func depth(of id: UUID, in roots: [LayoutNode]) -> Int? {
        for node in roots {
            if node.id == id { return 1 }
            if let sub = depth(of: id, in: node.children) { return sub + 1 }
        }
        return nil
    }

    static func height(of node: LayoutNode) -> Int {
        1 + (node.children.map(height(of:)).max() ?? 0)
    }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: `ALL TESTS PASSED`

- [ ] **Step 6: 앱 타깃 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Canvas DropValidator.swift
```
**빌드 확인** (SUCCEEDED).

- [ ] **Step 7: 커밋**

```bash
git add -A && git commit -m "feat: Add DropValidator with depth/cycle rules

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Link.sortIndex + 스냅샷 변환

SwiftData to-many 관계는 순서를 보장하지 않으므로 형제 순서를 `sortIndex`로 저장하고, `Link`/`Page` → `LayoutNode` 변환을 추가한다.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Model/LinkModel.swift`
- Modify: `TeamLongHair/TeamLongHair/Model/PageModel.swift`
- Modify: `TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift:113-116` (생성 시 sortIndex 부여)

**Interfaces:**
- Consumes: `LayoutNode` (Task 2)
- Produces:
  ```swift
  // Link
  var sortIndex: Int                       // 신규 저장 프로퍼티 (기본 0)
  var sortedSubLinks: [Link]               // sortIndex 오름차순
  var layoutNode: LayoutNode               // 재귀 스냅샷
  // Page
  var sortedLinks: [Link]                  // 루트들 sortIndex 오름차순
  var layoutRoots: [LayoutNode]
  var allLinks: [Link]                     // 정렬된 DFS 평탄화 (캔버스 ForEach용)
  ```

- [ ] **Step 1: LinkModel.swift 수정**

`Link` 클래스에 저장 프로퍼티와 init 라인 추가, 파일 하단에 extension 추가:

```swift
@Model
final class Link {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var detail: LinkDetail
    @Relationship(deleteRule: .cascade) var subLinks: [Link]
    var sortIndex: Int = 0  // SwiftData to-many는 순서 미보장 → 형제 순서의 단일 출처

    init(detail: LinkDetail, sortIndex: Int = 0) {
        self.id = UUID()
        self.detail = detail
        self.subLinks = []
        self.sortIndex = sortIndex
    }
}

extension Link {
    var sortedSubLinks: [Link] {
        subLinks.sorted { $0.sortIndex < $1.sortIndex }
    }

    var layoutNode: LayoutNode {
        LayoutNode(id: id, children: sortedSubLinks.map(\.layoutNode))
    }
}
```

(`LinkDetail`은 그대로 유지)

- [ ] **Step 2: PageModel.swift에 extension 추가**

파일 하단에:

```swift
extension Page {
    var sortedLinks: [Link] {
        links.sorted { $0.sortIndex < $1.sortIndex }
    }

    var layoutRoots: [LayoutNode] {
        sortedLinks.map(\.layoutNode)
    }

    /// 정렬된 DFS 순서로 페이지의 모든 링크 평탄화
    var allLinks: [Link] {
        func flatten(_ links: [Link]) -> [Link] {
            links.flatMap { [$0] + flatten($0.sortedSubLinks) }
        }
        return flatten(sortedLinks)
    }
}
```

- [ ] **Step 3: 생성 지점에 sortIndex 부여**

`FloatingPanelView.swift`의 저장 로직 (114-116행 부근) 변경:

```swift
let newLinkDetail = LinkDetail(URL: panelURLText, title: panelTitleText)
let targetPage = projects[projectIndex].pages[pageIndex]
let newLink = Link(detail: newLinkDetail,
                   sortIndex: (targetPage.sortedLinks.last?.sortIndex ?? -1) + 1)
targetPage.links.append(newLink)
```

- [ ] **Step 4: 빌드 확인 + 커밋**

**빌드 확인** (SUCCEEDED).

```bash
git add -A && git commit -m "feat: Add Link.sortIndex and LayoutNode snapshot conversion

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: ZoomableScrollView — NSScrollView 래퍼

**Files:**
- Create: `TeamLongHair/TeamLongHair/Project/Page/Canvas/ZoomableScrollView.swift`

**Interfaces:**
- Produces:
  ```swift
  struct ZoomableScrollView<Content: View>: NSViewRepresentable {
      init(magnification: Binding<CGFloat>, @ViewBuilder content: @escaping () -> Content)
  }
  ```
- 핀치 줌(0.25~3.0)·팬·관성은 NSScrollView가 처리. `magnification` 바인딩은 읽기 전용 표시용(줌 % 라벨).

- [ ] **Step 1: 구현**

```swift
//
//  ZoomableScrollView.swift
//  TeamLongHair
//
//  NSScrollView의 네이티브 magnification으로 피그마식 줌/팬을 제공한다.
//  줌 중심점·관성·제스처 충돌 처리는 전부 AppKit에 위임.
//

import AppKit
import SwiftUI

struct ZoomableScrollView<Content: View>: NSViewRepresentable {
    @Binding var magnification: CGFloat
    @ViewBuilder var content: () -> Content

    init(magnification: Binding<CGFloat>, @ViewBuilder content: @escaping () -> Content) {
        self._magnification = magnification
        self.content = content
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.25
        scrollView.maxMagnification = 3.0
        scrollView.drawsBackground = false

        let hostingView = NSHostingView(rootView: content())
        hostingView.sizingOptions = [.intrinsicContentSize]
        scrollView.documentView = hostingView

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let hostingView = scrollView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(magnification: $magnification)
    }

    final class Coordinator: NSObject {
        @Binding var magnification: CGFloat
        weak var scrollView: NSScrollView?

        init(magnification: Binding<CGFloat>) {
            self._magnification = magnification
        }

        @objc func boundsDidChange() {
            guard let scrollView else { return }
            let current = scrollView.magnification
            if abs(magnification - current) > 0.001 {
                // 뷰 업데이트 중 상태 변경 경고를 피하기 위해 다음 런루프에서 반영
                DispatchQueue.main.async { self.magnification = current }
            }
        }

        deinit { NotificationCenter.default.removeObserver(self) }
    }
}
```

- [ ] **Step 2: 앱 타깃 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Canvas ZoomableScrollView.swift
```
**빌드 확인** (SUCCEEDED).

- [ ] **Step 3: 커밋**

```bash
git add -A && git commit -m "feat: Add ZoomableScrollView backed by NSScrollView magnification

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: CanvasView 재작성 — 정적 렌더 (M1)

노드를 계산된 좌표에 배치하고 연결선을 Canvas Path로 그린다. 드래그&드롭은 Task 7. `DrawNodes.swift`는 삭제.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasView.swift` (전체 재작성)
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` (Binding 제거, 고정 크기)
- Delete: `TeamLongHair/TeamLongHair/Project/Page/Canvas/DrawNodes.swift`

**Interfaces:**
- Consumes: `TreeLayout`, `CanvasMetrics`, `TreeLayoutResult` (Task 2), `Page.layoutRoots/allLinks/sortedLinks`, `Link.sortedSubLinks` (Task 4), `ZoomableScrollView` (Task 5)
- Produces: `CanvasView(selectedPage: Binding<Page>, selectedLink: Binding<Link?>)` — 기존 시그니처 유지 (ProjectView 수정 불필요). 내부 뷰 `CanvasContentView(page:selectedLink:)`.

- [ ] **Step 1: LinkNode.swift 수정**

프로퍼티를 다음으로 교체 (body와 tagView는 그대로 — `link.detail...` 접근은 변경 없이 동작):

```swift
struct LinkNode: View {
    var link: Link
    var sizeOfNode: CGFloat = CanvasMetrics.nodeWidth
    var isSelected: Bool
    // body 이하 기존 그대로
```

Preview 교체:

```swift
#Preview {
    LinkNode(link: .init(detail: .init(URL: "", title: "2")), isSelected: true)
}
```

- [ ] **Step 2: CanvasView.swift 전체 재작성**

```swift
//
//  CanvasView.swift
//  TeamLongHair
//

import SwiftData
import SwiftUI

struct CanvasView: View {
    @Binding var selectedPage: Page
    @Binding var selectedLink: Link?

    @State private var magnification: CGFloat = 1.0

    var body: some View {
        ZoomableScrollView(magnification: $magnification) {
            CanvasContentView(page: selectedPage, selectedLink: $selectedLink)
        }
        .background(.canvas)
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Text(Image(systemName: "plus.magnifyingglass"))
                Text("\(Int(magnification * 100))%")
            }
            .padding(12)
        }
    }
}

struct CanvasContentView: View {
    var page: Page
    @Binding var selectedLink: Link?

    var body: some View {
        let layout = TreeLayout.compute(roots: page.layoutRoots)
        ZStack(alignment: .topLeading) {
            edges(layout: layout)
            ForEach(page.allLinks, id: \.id) { link in
                nodeView(for: link, layout: layout)
            }
        }
        .frame(width: max(layout.contentSize.width, 800),
               height: max(layout.contentSize.height, 600))
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: layout.positions)
    }

    private func nodeView(for link: Link, layout: TreeLayoutResult) -> some View {
        let pos = layout.positions[link.id] ?? .zero
        return LinkNode(link: link, isSelected: link.id == selectedLink?.id)
            .frame(width: CanvasMetrics.nodeWidth, height: CanvasMetrics.nodeHeight)
            .contentShape(Rectangle())
            .onTapGesture { selectedLink = link }
            .position(x: pos.x + CanvasMetrics.nodeWidth / 2,
                      y: pos.y + CanvasMetrics.nodeHeight / 2)
    }

    private func edges(layout: TreeLayoutResult) -> some View {
        Canvas { context, _ in
            func drawEdges(from parent: Link) {
                guard let parentPos = layout.positions[parent.id] else { return }
                for child in parent.sortedSubLinks {
                    guard let childPos = layout.positions[child.id] else { continue }
                    let from = CGPoint(x: parentPos.x + CanvasMetrics.nodeWidth,
                                       y: parentPos.y + CanvasMetrics.nodeHeight / 2)
                    let to = CGPoint(x: childPos.x,
                                     y: childPos.y + CanvasMetrics.nodeHeight / 2)
                    context.stroke(Self.edgePath(from: from, to: to),
                                   with: .color(.gray700), lineWidth: 1)
                    drawEdges(from: child)
                }
            }
            for root in page.sortedLinks {
                drawEdges(from: root)
            }
        }
    }

    /// 부모 오른쪽 가장자리 → 자식 왼쪽 가장자리를 잇는 둥근 ㄱ자 경로
    static func edgePath(from p: CGPoint, to c: CGPoint, cornerRadius r: CGFloat = 8) -> Path {
        var path = Path()
        path.move(to: p)
        guard abs(c.y - p.y) > 0.5 else {
            path.addLine(to: c)
            return path
        }
        let midX = (p.x + c.x) / 2
        let dir: CGFloat = c.y > p.y ? 1 : -1
        path.addLine(to: CGPoint(x: midX - r, y: p.y))
        path.addQuadCurve(to: CGPoint(x: midX, y: p.y + r * dir),
                          control: CGPoint(x: midX, y: p.y))
        path.addLine(to: CGPoint(x: midX, y: c.y - r * dir))
        path.addQuadCurve(to: CGPoint(x: midX + r, y: c.y),
                          control: CGPoint(x: midX, y: c.y))
        path.addLine(to: c)
        return path
    }
}
```

- [ ] **Step 3: DrawNodes.swift 삭제**

```bash
ruby scripts/xcodeproj_remove.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj DrawNodes.swift
git rm TeamLongHair/TeamLongHair/Project/Page/Canvas/DrawNodes.swift
```

- [ ] **Step 4: 빌드 + 수동 QA (M1 검증)**

**빌드 확인** (SUCCEEDED) 후 `open build/Build/Products/Debug/TeamLongHair.app`:
- 프로젝트 생성 → 플로팅 패널(⌘⇧G)로 링크 2~3개 저장 → 프로젝트 열기
- 노드들이 세로로 배치되고, 핀치 줌이 커서 중심으로 부드럽게 동작하는지
- 두 손가락 스크롤로 팬 + 관성이 동작하는지
- 노드 클릭 시 인스펙터(DetailPanel)가 열리는지
- 줌 % 라벨이 갱신되는지

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: Rewrite CanvasView with computed layout and Canvas edges

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: 드래그&드롭 재부모화 (M2)

**Files:**
- Create: `TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasViewModel.swift`
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/CanvasView.swift` (draggable/dropDestination 연결, normalize 호출)

**Interfaces:**
- Consumes: `DropValidator` (Task 3), `Page.layoutRoots/sortedLinks`, `Link.sortedSubLinks` (Task 4)
- Produces:
  ```swift
  struct CanvasViewModel {
      let page: Page
      func moveLink(draggedIDString: String, onto targetID: UUID) -> Bool  // 검증 → 원자적 이동
      func makeRoot(draggedIDString: String) -> Bool                       // 빈 캔버스 드롭 → 루트로
      func normalizeSortIndices()                                          // 레거시 데이터 sortIndex 부여
  }
  ```

- [ ] **Step 1: CanvasViewModel.swift 작성**

```swift
//
//  CanvasViewModel.swift
//  TeamLongHair
//
//  캔버스의 SwiftData 변경(재부모화)을 담당. 검증(DropValidator) 통과 후에만 변경한다.
//

import Foundation

struct CanvasViewModel {
    let page: Page

    /// 검증 통과 시에만 제거+삽입을 수행한다. 실패 시 트리는 변경되지 않는다.
    func moveLink(draggedIDString: String, onto targetID: UUID) -> Bool {
        guard let draggedID = UUID(uuidString: draggedIDString),
              DropValidator.canDrop(dragged: draggedID, onto: targetID, roots: page.layoutRoots),
              let dragged = findLink(id: draggedID),
              let target = findLink(id: targetID)
        else { return false }

        detach(dragged)
        dragged.sortIndex = (target.sortedSubLinks.last?.sortIndex ?? -1) + 1
        target.subLinks.append(dragged)
        return true
    }

    /// 빈 캔버스에 드롭: 루트로 승격
    func makeRoot(draggedIDString: String) -> Bool {
        guard let draggedID = UUID(uuidString: draggedIDString),
              let dragged = findLink(id: draggedID),
              !page.links.contains(where: { $0.id == draggedID })  // 이미 루트면 무시
        else { return false }

        detach(dragged)
        dragged.sortIndex = (page.sortedLinks.last?.sortIndex ?? -1) + 1
        page.links.append(dragged)
        return true
    }

    /// 레거시 데이터(sortIndex 전부 0)에 형제 순서를 부여한다.
    func normalizeSortIndices() {
        func normalize(_ links: [Link]) {
            if links.count > 1, Set(links.map(\.sortIndex)).count != links.count {
                for (index, link) in links.enumerated() {
                    link.sortIndex = index
                }
            }
            for link in links {
                normalize(link.subLinks)
            }
        }
        normalize(page.links)
    }

    private func findLink(id: UUID) -> Link? {
        func find(in links: [Link]) -> Link? {
            for link in links {
                if link.id == id { return link }
                if let found = find(in: link.subLinks) { return found }
            }
            return nil
        }
        return find(in: page.links)
    }

    /// 현재 부모(페이지 루트 배열 또는 부모 링크)에서 분리
    private func detach(_ link: Link) {
        if page.links.contains(where: { $0.id == link.id }) {
            page.links.removeAll { $0.id == link.id }
            return
        }
        func removeFromSubtree(_ parent: Link) -> Bool {
            if parent.subLinks.contains(where: { $0.id == link.id }) {
                parent.subLinks.removeAll { $0.id == link.id }
                return true
            }
            return parent.subLinks.contains { removeFromSubtree($0) }
        }
        for root in page.links where removeFromSubtree(root) { return }
    }
}
```

- [ ] **Step 2: CanvasView.swift에 연결**

`CanvasContentView.nodeView`의 `.onTapGesture` 아래에 추가:

```swift
            .draggable(link.id.uuidString)
            .dropDestination(for: String.self) { items, _ in
                guard let idString = items.first else { return false }
                return CanvasViewModel(page: page).moveLink(draggedIDString: idString,
                                                            onto: link.id)
            }
```

`CanvasContentView` body의 `.contentShape(Rectangle())` 아래(`.animation` 위)에 배경 드롭 추가:

```swift
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first else { return false }
            return CanvasViewModel(page: page).makeRoot(draggedIDString: idString)
        }
```

`CanvasView` body의 `.overlay` 아래에 normalize 호출 추가:

```swift
        .onAppear { CanvasViewModel(page: selectedPage).normalizeSortIndices() }
        .onChange(of: selectedPage) {
            CanvasViewModel(page: selectedPage).normalizeSortIndices()
        }
```

- [ ] **Step 3: 빌드 + 수동 QA (M2 검증)**

**빌드 확인** (SUCCEEDED) 후 앱 실행:
- 노드 A를 노드 B에 드롭 → A가 B의 자식이 되고 레이아웃이 애니메이션으로 재정렬
- 자기 자손에게 드롭 → 아무 변화 없음 (노드 유실 없음 — 핵심 버그 수정 확인)
- 깊이 3 노드에 드롭 → 거부됨
- 자식 노드를 빈 캔버스 영역에 드롭 → 루트로 승격
- 루트 노드를 빈 캔버스에 드롭 → 변화 없음
- 앱 재시작 → 형제 순서 유지 (sortIndex 동작 확인)

- [ ] **Step 4: 커밋**

```bash
git add -A && git commit -m "feat: Add validated drag-and-drop reparenting to canvas

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: 브라우저 탭 자동 수집 (M3)

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/BrowserTabReader.swift`
- Modify: `TeamLongHair/TeamLongHair/Utils/AppState.swift` (캡처 시점 연결)
- Modify: `TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift` (프리필)
- Modify: `TeamLongHair/TeamLongHair/TeamLongHair.entitlements` (샌드박스 해제)
- Modify: `TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj` (Info.plist 키 — 두 빌드 설정 모두)

**Interfaces:**
- Consumes: `AppState.isPanelPresented` 토글 지점 (AppState.swift 50-54행, 76-79행)
- Produces:
  ```swift
  enum BrowserTabReader {
      struct TabInfo: Equatable { let url: String; let title: String }
      static func readActiveTab() -> TabInfo?   // 프론트 앱이 지원 브라우저가 아니면 nil
  }
  // AppState 추가 프로퍼티
  var pendingTabInfo: BrowserTabReader.TabInfo?
  ```
- **중요한 타이밍**: 패널 present 시 `NSApp.activate`가 호출되어 우리 앱이 프론트가 되므로, 캡처는 반드시 **isPanelPresented 토글 직전**(브라우저가 아직 프론트일 때) 실행해야 한다.

- [ ] **Step 1: BrowserTabReader.swift 작성**

```swift
//
//  BrowserTabReader.swift
//  TeamLongHair
//
//  프론트모스트 브라우저의 활성 탭 URL/제목을 AppleScript로 읽는다.
//  실패(미지원 브라우저·권한 거부)하면 nil — 수동 입력이 폴백.
//

import AppKit

enum BrowserTabReader {
    struct TabInfo: Equatable {
        let url: String
        let title: String
    }

    private static let safariBundleIDs: Set<String> = ["com.apple.Safari"]
    private static let chromiumBundleIDs: Set<String> = [
        "com.google.Chrome",
        "company.thebrowser.Browser", // Arc
        "com.naver.whale",
    ]

    static func readActiveTab() -> TabInfo? {
        guard let frontmost = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontmost.bundleIdentifier
        else { return nil }

        let source: String
        if safariBundleIDs.contains(bundleID) {
            source = """
            tell application id "\(bundleID)"
                set theURL to URL of front document
                set theTitle to name of front document
                return theURL & "\\n" & theTitle
            end tell
            """
        } else if chromiumBundleIDs.contains(bundleID) {
            source = """
            tell application id "\(bundleID)"
                set theURL to URL of active tab of front window
                set theTitle to title of active tab of front window
                return theURL & "\\n" & theTitle
            end tell
            """
        } else {
            return nil
        }

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            debugPrint("BrowserTabReader error:", errorInfo)
            return nil
        }
        guard let combined = result.stringValue else { return nil }
        let parts = combined.components(separatedBy: "\n")
        guard parts.count >= 2, !parts[0].isEmpty else { return nil }
        return TabInfo(url: parts[0], title: parts[1...].joined(separator: " "))
    }
}
```

- [ ] **Step 2: AppState.swift 수정**

프로퍼티 추가 (`var shouldSaveDataToggle` 아래):

```swift
    var pendingTabInfo: BrowserTabReader.TabInfo?
```

`checkLocalEventIsKeyShortcut`의 단축키 매칭 블록(50-54행)과 `checkGlobalEventIsKeyShortcut`의 매칭 블록(76-79행)에서, `isPanelPresented.toggle()` **직전**에 캡처 추가 — 두 곳 모두 동일 패턴:

```swift
        if event.keyCode == keyShortcut.keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == keyShortcut.modifierFlags.intersection(.deviceIndependentFlagsMask) {
            if !isPanelPresented {
                // 패널이 열리며 우리 앱이 활성화되기 전에, 브라우저가 프론트인 지금 캡처
                pendingTabInfo = BrowserTabReader.readActiveTab()
            }
            isPanelPresented.toggle()
            ...
        }
```

- [ ] **Step 3: FloatingPanelView.swift 프리필**

기존 `.onChange(of: appState.shouldSaveDataToggle)` 아래에 추가:

```swift
        .onChange(of: appState.isPanelPresented) { _, isPresented in
            guard isPresented, let tab = appState.pendingTabInfo else { return }
            if panelURLText.isEmpty { panelURLText = tab.url }
            if panelTitleText.isEmpty { panelTitleText = tab.title }
            appState.pendingTabInfo = nil
        }
```

- [ ] **Step 4: 샌드박스 해제 + Info.plist 키**

`TeamLongHair/TeamLongHair/TeamLongHair.entitlements`에서 `com.apple.security.app-sandbox`를 `<false/>`로 변경 (개인용 빌드 — AppleScript로 브라우저 제어에 필요).

`project.pbxproj`의 두 빌드 설정 모두에서 `INFOPLIST_KEY_NSHumanReadableCopyright = "";` 라인(486행, 513행 부근) 아래에 추가:

```
				INFOPLIST_KEY_NSAppleEventsUsageDescription = "현재 브라우저 탭의 주소와 제목을 자동으로 입력하기 위해 필요합니다.";
```

- [ ] **Step 5: 빌드 + 수동 QA (M3 검증)**

**빌드 확인** (SUCCEEDED) 후 앱 실행:
- Safari에서 아무 페이지 열고 ⌘⇧G → 패널에 URL/제목이 미리 채워지는지 (최초 1회 자동화 권한 프롬프트 허용)
- Chrome에서도 동일 확인
- Finder가 프론트일 때 ⌘⇧G → 빈 필드 (조용한 폴백)
- 저장(Enter) → 캔버스에 새 노드가 루트로 추가되는지

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "feat: Prefill floating panel with active browser tab via AppleScript

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: 마무리 정리 + 전체 QA (M4)

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Project/LinkPanel/LinkListView.swift` (정렬 순서 적용)
- Modify: 잔여 참조 정리 (grep 결과에 따라)

- [ ] **Step 1: 사이드바 정렬 적용**

`LinkListView.swift`에서 `$link.subLinks`를 순회하는 부분(23-24행 부근)이 정렬 없이 도는 것을 확인하고, 캔버스와 순서가 일치하도록 `sortedSubLinks` 기반으로 표시되게 수정한다. (Binding 순회 구조라면 표시 순서만 `sortIndex` 정렬로 바꾸는 최소 수정 — 파일을 읽고 기존 패턴에 맞춰 적용.)

- [ ] **Step 2: 잔여 참조/죽은 코드 정리**

```bash
grep -rn "DrawNodes\|sizeOfNode\|lastScaleValue\|draggedLink" TeamLongHair/TeamLongHair --include="*.swift"
```
- `DrawNodes` 참조가 남아있으면 제거
- `LinkNode.sizeOfNode`는 기본값 인자로 유지 (사용처 확인만)
- 그 외 재작성으로 죽은 심볼 제거

- [ ] **Step 3: 로직 테스트 + 빌드 최종 확인**

**로직 테스트** (`ALL TESTS PASSED`) + **빌드 확인** (SUCCEEDED).

- [ ] **Step 4: 전체 흐름 수동 QA**

1. 앱 실행 → 새 프로젝트 생성
2. Safari/Chrome에서 ⌘⇧G로 링크 5개 이상 저장 (서로 다른 페이지 몇 개 포함)
3. 프로젝트 열기 → 노드맵 확인: 줌/팬 부드러움, 연결선 정확성
4. 드래그로 3단계 트리 구성 → 재시작 후 구조·순서 유지 확인
5. 노드 선택 → 인스펙터에서 태그/메모/색상/아이콘 편집 → 노드에 반영 확인
6. 노드 100개 페이지에서 줌/팬 성능 확인 (프리즈 없어야 함)

- [ ] **Step 5: 최종 커밋 + 푸시**

```bash
git add -A && git commit -m "chore: Sort sidebar links and clean up dead canvas code

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -u origin feat/canvas-completion
```

---

## Self-Review 결과

- **스펙 커버리지**: 줌/팬(T5,6), 자동 레이아웃(T2,6), 재부모화+원자성(T3,7), sortIndex(T4), 탭 수집(T8), 사이드바/정리(T9) — 스펙의 모든 요구사항에 태스크 존재. 스펙의 "M4 진입점 복원"은 dev 브랜치 기반이라 불필요해 제외됨(스펙 참고 섹션에 기록됨).
- **플레이스홀더**: 없음. Task 9 Step 1만 "파일을 읽고 기존 패턴에 맞춰" — LinkListView 전문이 확인되지 않아 의도적으로 남긴 최소 지시.
- **타입 일관성**: `LayoutNode`/`CanvasMetrics`/`TreeLayoutResult`(T2) ↔ T3,4,6 사용처 일치. `CanvasViewModel` 시그니처(T7) ↔ T7 Step 2 호출부 일치. `TabInfo`(T8) ↔ AppState/FloatingPanelView 사용처 일치.
