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
                Text("\(Int((magnification * 100).rounded()))%")
            }
            .padding(12)
        }
        .onAppear { CanvasViewModel(page: selectedPage).normalizeSortIndices() }
        .onChange(of: selectedPage) {
            CanvasViewModel(page: selectedPage).normalizeSortIndices()
        }
    }
}

struct CanvasContentView: View {
    var page: Page
    @Binding var selectedLink: Link?

    /// 노드 드래그 이동은 SwiftUI DragGesture로 직접 처리한다.
    /// (.draggable/.dropDestination은 NavigationSplitView 안에서 히트 좌표가
    ///  사이드바 너비만큼 어긋나는 버그가 있어 사용하지 않는다.)
    private static let canvasSpace = "canvasSpace"
    @State private var draggingID: UUID?
    @State private var dragTranslation: CGSize = .zero

    var body: some View {
        let layout = TreeLayout.compute(roots: page.layoutRoots)
        ZStack(alignment: .topLeading) {
            edges(layout: layout)
            ForEach(page.allLinks, id: \.id) { link in
                nodeView(for: link, layout: layout)
            }
        }
        .frame(width: max(layout.contentSize.width, CanvasMetrics.minContentWidth),
               height: max(layout.contentSize.height, CanvasMetrics.minContentHeight))
        .contentShape(Rectangle())
        .coordinateSpace(.named(Self.canvasSpace))
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: layout.positions)
    }

    private func nodeView(for link: Link, layout: TreeLayoutResult) -> some View {
        let pos = layout.positions[link.id] ?? .zero
        let isDragging = draggingID == link.id
        return LinkNode(link: link, isSelected: link.id == selectedLink?.id)
            .frame(width: CanvasMetrics.nodeWidth, height: CanvasMetrics.nodeHeight)
            .contentShape(Rectangle())
            .onTapGesture { selectedLink = link }
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .named(Self.canvasSpace))
                    .onChanged { value in
                        draggingID = link.id
                        dragTranslation = value.translation
                    }
                    .onEnded { value in
                        finishDrag(draggedID: link.id, dropLocation: value.location, layout: layout)
                    }
            )
            .position(x: pos.x + CanvasMetrics.nodeWidth / 2,
                      y: pos.y + CanvasMetrics.nodeHeight / 2)
            .offset(isDragging ? dragTranslation : .zero)
            .zIndex(isDragging ? 1 : 0)
    }

    /// 드롭 지점(캔버스 좌표)에 있는 노드를 찾아 재부모화하고,
    /// 빈 공간이면 루트로 승격한다. 드래그 상태는 항상 초기화.
    private func finishDrag(draggedID: UUID, dropLocation: CGPoint, layout: TreeLayoutResult) {
        defer {
            draggingID = nil
            dragTranslation = .zero
        }
        let vm = CanvasViewModel(page: page)
        if let targetID = nodeID(at: dropLocation, layout: layout, excluding: draggedID) {
            _ = vm.moveLink(draggedIDString: draggedID.uuidString, onto: targetID)
        } else {
            _ = vm.makeRoot(draggedIDString: draggedID.uuidString)
        }
    }

    /// 주어진 지점을 포함하는 노드의 id (dragged 자신은 제외).
    private func nodeID(at point: CGPoint, layout: TreeLayoutResult, excluding: UUID) -> UUID? {
        for (id, pos) in layout.positions where id != excluding {
            let frame = CGRect(x: pos.x, y: pos.y,
                               width: CanvasMetrics.nodeWidth, height: CanvasMetrics.nodeHeight)
            if frame.contains(point) { return id }
        }
        return nil
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
