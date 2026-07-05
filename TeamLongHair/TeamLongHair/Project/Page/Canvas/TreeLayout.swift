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
    static let minContentWidth: CGFloat = 800
    static let minContentHeight: CGFloat = 600

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
