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
        .onAppear { CanvasViewModel(page: selectedPage).normalizeSortIndices() }
        .onChange(of: selectedPage) {
            CanvasViewModel(page: selectedPage).normalizeSortIndices()
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
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first else { return false }
            return CanvasViewModel(page: page).makeRoot(draggedIDString: idString)
        }
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
            .draggable(link.id.uuidString)
            .dropDestination(for: String.self) { items, _ in
                guard let idString = items.first else { return false }
                return CanvasViewModel(page: page).moveLink(draggedIDString: idString,
                                                            onto: link.id)
            }
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
