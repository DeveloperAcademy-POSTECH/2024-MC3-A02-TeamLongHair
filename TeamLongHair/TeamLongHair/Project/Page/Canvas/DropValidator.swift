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
