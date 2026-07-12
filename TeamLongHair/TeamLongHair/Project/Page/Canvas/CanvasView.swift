//
//  CanvasView.swift
//  TeamLongHair
//

import SwiftData
import SwiftUI

struct CanvasView: View {
    @Binding var selectedPage: Page
    @Binding var selectedLink: Link?

    // 줌/팬은 순수 SwiftUI로 처리한다. NSScrollView 배율은 SwiftUI 제스처 좌표에
    // 반영되지 않아 히트 위치가 배율만큼 어긋났다. scaleEffect는 SwiftUI가 변환을
    // 알고 있으므로 모든 제스처/히트테스트가 배율과 무관하게 정확하다.
    @State private var baseZoom: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1
    @State private var basePan: CGSize = .zero
    @GestureState private var dragPan: CGSize = .zero

    private let minZoom: CGFloat = 0.25
    private let maxZoom: CGFloat = 3.0

    private var zoom: CGFloat { min(max(baseZoom * pinch, minZoom), maxZoom) }
    private var pan: CGSize {
        CGSize(width: basePan.width + dragPan.width,
               height: basePan.height + dragPan.height)
    }

    var body: some View {
        // GeometryReader로 캔버스를 뷰포트 크기에 고정한다. 이렇게 하지 않으면
        // CanvasContentView의 큰 고유 크기(트리 전체 폭)가 상위로 전파되어 detail
        // 열이 콘텐츠 폭만큼 넓어지고 오른쪽 인스펙터가 화면 밖으로 밀려 잘린다.
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.canvas
                    .gesture(panGesture)
                CanvasContentView(page: selectedPage, selectedLink: $selectedLink)
                    .scaleEffect(zoom, anchor: .topLeading)
                    .offset(pan)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
            .simultaneousGesture(magnifyGesture)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Text(Image(systemName: "plus.magnifyingglass"))
                Text("\(Int((zoom * 100).rounded()))%")
            }
            .padding(12)
        }
        .onAppear { CanvasViewModel(page: selectedPage).normalizeSortIndices() }
        .onChange(of: selectedPage) {
            CanvasViewModel(page: selectedPage).normalizeSortIndices()
        }
    }

    /// 빈 캔버스 배경을 드래그하면 화면을 이동(팬)한다.
    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragPan) { value, state, _ in state = value.translation }
            .onEnded { value in
                basePan.width += value.translation.width
                basePan.height += value.translation.height
            }
    }

    /// 핀치로 확대/축소.
    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in state = value.magnification }
            .onEnded { value in
                baseZoom = min(max(baseZoom * value.magnification, minZoom), maxZoom)
            }
    }
}

struct CanvasContentView: View {
    var page: Page
    @Binding var selectedLink: Link?

    /// 노드 이동은 SwiftUI DragGesture로 직접 처리한다. 드롭 위치와 노드 프레임을
    /// 모두 이 명명 좌표공간(콘텐츠 좌표계)에서 비교하므로 줌/팬과 무관하게 정확하다.
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

    /// 드롭 지점(콘텐츠 좌표)에 있는 노드로 재부모화하고, 빈 공간이면 루트로 승격.
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
                                   with: .color(.gray700), lineWidth: 1.5)
                    drawEdges(from: child)
                }
            }
            for root in page.sortedLinks {
                drawEdges(from: root)
            }
        }
        .allowsHitTesting(false)
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
