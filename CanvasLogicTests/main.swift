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

// MARK: - DropValidator tests

do {
    // 트리:  root1 ─ mid ─ leaf   /   root2
    let leaf = LayoutNode(id: UUID(), children: [])
    let mid = LayoutNode(id: UUID(), children: [leaf])       // mid 서브트리 높이 = 2
    let root1 = LayoutNode(id: UUID(), children: [mid])      // root1 서브트리 높이 = 3
    let root2 = LayoutNode(id: UUID(), children: [])
    let roots = [root1, root2]

    expect(!DropValidator.canDrop(dragged: root2.id, onto: root2.id, roots: roots), "자기 자신에게 드롭 금지")
    expect(!DropValidator.canDrop(dragged: root1.id, onto: leaf.id, roots: roots), "자기 자손에게 드롭 금지 (사이클)")
    expect(!DropValidator.canDrop(dragged: root1.id, onto: mid.id, roots: roots), "자기 직속 자식에게 드롭 금지 (사이클)")
    // 깊이 제한 없음: 임의 깊이로 자유롭게 중첩 가능
    expect(DropValidator.canDrop(dragged: root2.id, onto: leaf.id, roots: roots), "리프에 드롭해 더 깊게 중첩 허용 (깊이 무제한)")
    expect(DropValidator.canDrop(dragged: root2.id, onto: mid.id, roots: roots), "중간 노드에 드롭 허용")
    expect(DropValidator.canDrop(dragged: root1.id, onto: root2.id, roots: roots), "높은 서브트리도 다른 루트로 이동 허용")
    expect(!DropValidator.canDrop(dragged: UUID(), onto: root2.id, roots: roots), "미존재 dragged 금지")
    expect(!DropValidator.canDrop(dragged: root2.id, onto: UUID(), roots: roots), "미존재 target 금지")
}

// MARK: - LinkMetadataParsing tests

expect(LinkMetadataParsing.normalizedURL(from: "example.com")?.absoluteString == "https://example.com",
       "스킴 없으면 https 보정")
expect(LinkMetadataParsing.normalizedURL(from: "https://a.com/x")?.absoluteString == "https://a.com/x",
       "기존 스킴 유지")
expect(LinkMetadataParsing.normalizedURL(from: "   ") == nil, "공백만이면 nil")
expect(LinkMetadataParsing.normalizedURL(from: "no scheme with spaces") == nil, "공백 포함 무효 URL은 nil")

expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta property=\"og:description\" content=\"Hello world\">") == "Hello world",
       "og:description 추출")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta name=\"description\" content=\"Desc here\">") == "Desc here",
       "meta description 추출")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta name=\"description\" content=\"A &amp; B\">") == "A & B",
       "HTML 엔티티 디코드")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<html><body>nothing</body></html>") == nil,
       "설명 없으면 nil")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta name=\"description\" content=\"A > B\">") == "A > B",
       "content 안의 > 도 보존")

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

// MARK: - HotKeyModifiers tests
do {
    let command: UInt = 1 << 20
    let shift: UInt = 1 << 17
    let option: UInt = 1 << 19
    let control: UInt = 1 << 18
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: 0), 0, "수정자 없음 → 0")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: command), 256, "⌘ → cmdKey 256")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: control), 4096, "⌃ → controlKey 4096")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: shift), 512, "⇧ → shiftKey 512")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: option), 2048, "⌥ → optionKey 2048")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: command | control), 4352, "⌘⌃ → 4352")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: command | shift), 768, "⌘⇧ → 768")
}

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

if failures > 0 { print("\(failures) FAILURES"); exit(1) }
print("ALL TESTS PASSED")
