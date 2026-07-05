//
//  DropValidator.swift
//  TeamLongHair
//
//  드롭 가능 여부를 스냅샷(LayoutNode) 기반으로 검증하는 순수 로직.
//  SwiftData 변경 전에 반드시 이 검증을 통과해야 한다.
//

import Foundation

enum DropValidator {
    /// 깊이 제한은 없다. 임의 깊이로 자유롭게 중첩할 수 있고,
    /// 오직 사이클(자기 자신·자기 자손에게 드롭)만 금지한다.
    static func canDrop(dragged: UUID, onto target: UUID, roots: [LayoutNode]) -> Bool {
        guard dragged != target else { return false }
        guard let draggedNode = find(dragged, in: roots) else { return false }
        // target이 존재해야 하고, dragged의 자손이면 사이클이 되므로 금지
        guard find(target, in: roots) != nil else { return false }
        guard find(target, in: draggedNode.children) == nil else { return false }
        return true
    }

    static func find(_ id: UUID, in roots: [LayoutNode]) -> LayoutNode? {
        for node in roots {
            if node.id == id { return node }
            if let found = find(id, in: node.children) { return found }
        }
        return nil
    }
}
