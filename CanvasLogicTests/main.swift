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
    expect(!DropValidator.canDrop(dragged: root1.id, onto: leaf.id, roots: roots), "자기 자손에게 드롭 금지")
    expect(DropValidator.canDrop(dragged: root2.id, onto: mid.id, roots: roots), "리프를 깊이2에 드롭 = 결과깊이 3 허용")
    expect(!DropValidator.canDrop(dragged: root2.id, onto: leaf.id, roots: roots), "리프를 깊이3에 드롭 = 결과깊이 4 금지")
    expect(DropValidator.canDrop(dragged: mid.id, onto: root2.id, roots: roots), "높이2 서브트리 + 루트(깊이1) = 3 허용")
    expect(!DropValidator.canDrop(dragged: root1.id, onto: root2.id, roots: roots), "높이3 서브트리 + 루트(깊이1) = 4 금지")
    expect(!DropValidator.canDrop(dragged: UUID(), onto: root2.id, roots: roots), "미존재 dragged 금지")
    expect(!DropValidator.canDrop(dragged: root2.id, onto: UUID(), roots: roots), "미존재 target 금지")
}

if failures > 0 { print("\(failures) FAILURES"); exit(1) }
print("ALL TESTS PASSED")
