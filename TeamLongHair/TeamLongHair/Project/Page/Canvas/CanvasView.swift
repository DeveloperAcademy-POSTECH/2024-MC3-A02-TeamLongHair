//
//  CanvasView.swift
//  TeamLongHair
//

import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// 콘텐츠 좌표의 한 점을 포함하는 노드 id(excluding은 제외, 없으면 nil).
/// 뷰와 CanvasDropDelegate가 공유한다.
private func canvasNodeID(at point: CGPoint, in layout: TreeLayoutResult, excluding: UUID?) -> UUID? {
    for (id, pos) in layout.positions where id != excluding {
        let frame = CGRect(x: pos.x, y: pos.y,
                           width: CanvasMetrics.nodeWidth, height: CanvasMetrics.nodeHeight)
        if frame.contains(point) { return id }
    }
    return nil
}

/// 페이지 트리에서 id로 Link를 찾는다.
private func canvasFindLink(_ id: UUID, in links: [Link]) -> Link? {
    for link in links {
        if link.id == id { return link }
        if let found = canvasFindLink(id, in: link.subLinks) { return found }
    }
    return nil
}

struct CanvasView: View {
    @Binding var selectedPage: Page
    @Binding var selectedLink: Link?
    /// 리스트에서 링크를 클릭하면 이 값이 세팅되고, 캔버스가 해당 노드를 중앙으로 이동시킨다.
    @Binding var focusRequest: UUID?

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
            let layout = TreeLayout.compute(roots: selectedPage.layoutRoots)
            ZStack(alignment: .topLeading) {
                Color.canvas
                    .gesture(panGesture)
                CanvasContentView(page: selectedPage, selectedLink: $selectedLink, focusRequest: $focusRequest, layout: layout)
                    .scaleEffect(zoom, anchor: .topLeading)
                    .offset(pan)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
            .simultaneousGesture(magnifyGesture)
            .onChange(of: focusRequest) { _, request in
                centerOnNode(request, layout: layout, viewport: geo.size)
            }
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

    /// 지정한 노드가 뷰포트 중앙에 오도록 팬을 애니메이션으로 이동시킨다.
    private func centerOnNode(_ id: UUID?, layout: TreeLayoutResult, viewport: CGSize) {
        guard let id, let pos = layout.positions[id] else { return }
        let nodeCenter = CGPoint(x: pos.x + CanvasMetrics.nodeWidth / 2,
                                 y: pos.y + CanvasMetrics.nodeHeight / 2)
        // 화면 위치 = nodeCenter * zoom + pan (scaleEffect anchor .topLeading + offset)
        // 이 위치를 뷰포트 중앙으로 맞추는 pan 값을 역산한다.
        let target = CGSize(width: viewport.width / 2 - nodeCenter.x * baseZoom,
                            height: viewport.height / 2 - nodeCenter.y * baseZoom)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            basePan = target
        }
        focusRequest = nil
    }
}

struct CanvasContentView: View {
    var page: Page
    @Binding var selectedLink: Link?
    /// 노드를 클릭하면 이 값을 세팅해 캔버스가 해당 노드를 중앙으로 이동시킨다(리스트 클릭과 동일).
    @Binding var focusRequest: UUID?
    var layout: TreeLayoutResult

    @Environment(\.modelContext) private var context

    /// 노드 이동은 SwiftUI DragGesture로 직접 처리한다. 드롭 위치와 노드 프레임을
    /// 모두 이 명명 좌표공간(콘텐츠 좌표계)에서 비교하므로 줌/팬과 무관하게 정확하다.
    private static let canvasSpace = "canvasSpace"
    @State private var draggingID: UUID?
    @State private var dragTranslation: CGSize = .zero
    /// 드래그 중 커서 아래의 유효한 부모 후보(강조 표시 대상).
    @State private var dropTargetID: UUID?

    var body: some View {
        // 드래그 중인 노드의 서브트리(자기 + 모든 자손). 이 노드들과 그 사이 연결선을
        // 함께 오프셋해서 하위 트리가 드래그를 따라 통째로 움직이게 한다.
        let movingSubtree = draggingID.map { subtreeIDs(of: $0) } ?? []
        ZStack(alignment: .topLeading) {
            edges(layout: layout, movingSubtree: movingSubtree)
            ForEach(page.allLinks, id: \.id) { link in
                nodeView(for: link, layout: layout, movingSubtree: movingSubtree)
            }
        }
        .frame(width: max(layout.contentSize.width, CanvasMetrics.minContentWidth),
               height: max(layout.contentSize.height, CanvasMetrics.minContentHeight))
        .coordinateSpace(.named(Self.canvasSpace))
        .onDrop(of: [.url, .text], delegate: CanvasDropDelegate(page: page, layout: layout, dropTargetID: $dropTargetID))
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: layout.positions)
        .onChange(of: page.id) {
            // 페이지 전환 시 드래그 상태가 남아 노드가 어긋나 보이는 것을 방지
            draggingID = nil
            dragTranslation = .zero
            dropTargetID = nil
        }
    }

    private func nodeView(for link: Link, layout: TreeLayoutResult, movingSubtree: Set<UUID>) -> some View {
        let pos = layout.positions[link.id] ?? .zero
        let isDragging = movingSubtree.contains(link.id)
        return LinkNode(link: link,
                        isSelected: link.id == selectedLink?.id,
                        isDropTarget: dropTargetID == link.id)
            .frame(width: CanvasMetrics.nodeWidth, height: CanvasMetrics.nodeHeight)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { link.openInBrowser() }
            .onTapGesture {
                selectedLink = link
                // 리스트에서 클릭했을 때처럼 뷰포트를 이 노드 중심으로 이동시킨다.
                focusRequest = link.id
            }
            .contextMenu {
                Button { link.openInBrowser() } label: {
                    Label("브라우저에서 열기", systemImage: "safari")
                }
                Button(role: .destructive) { deleteNode(link) } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .named(Self.canvasSpace))
                    .onChanged { value in
                        draggingID = link.id
                        dragTranslation = value.translation
                        // 커서 아래의 유효한 부모 후보를 찾아 강조 대상으로 표시
                        if let candidate = nodeID(at: value.location, layout: layout, excluding: link.id),
                           DropValidator.canDrop(dragged: link.id, onto: candidate, roots: page.layoutRoots) {
                            dropTargetID = candidate
                        } else {
                            dropTargetID = nil
                        }
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
            dropTargetID = nil
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
        canvasNodeID(at: point, in: layout, excluding: excluding)
    }

    private func edges(layout: TreeLayoutResult, movingSubtree: Set<UUID>) -> some View {
        let t = dragTranslation
        return Canvas { context, _ in
            func drawEdges(from parent: Link) {
                guard let parentPos = layout.positions[parent.id] else { return }
                // 서브트리에 속한 끝점은 드래그 오프셋을 반영한다. 서브트리 내부 연결선은
                // 양끝이 함께 움직여 통째로 따라오고, 드래그 노드의 부모→노드 연결선은
                // 한쪽만 움직여 늘어난다.
                let pOff = movingSubtree.contains(parent.id) ? t : .zero
                for child in parent.sortedSubLinks {
                    guard let childPos = layout.positions[child.id] else { continue }
                    let cOff = movingSubtree.contains(child.id) ? t : .zero
                    let from = CGPoint(x: parentPos.x + CanvasMetrics.nodeWidth + pOff.width,
                                       y: parentPos.y + CanvasMetrics.nodeHeight / 2 + pOff.height)
                    let to = CGPoint(x: childPos.x + cOff.width,
                                     y: childPos.y + CanvasMetrics.nodeHeight / 2 + cOff.height)
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

    /// 노드와 그 서브트리를 삭제한다. 선택된 링크가 삭제 대상에 포함되면 선택 해제.
    private func deleteNode(_ link: Link) {
        let vm = CanvasViewModel(page: page)
        if let selected = selectedLink?.id, vm.subtreeIDs(of: link.id).contains(selected) {
            selectedLink = nil
        }
        vm.deleteLink(id: link.id, context: context)
    }

    /// 주어진 노드와 그 모든 자손의 id 집합.
    private func subtreeIDs(of id: UUID) -> Set<UUID> {
        guard let root = findLink(id, in: page.links) else { return [] }
        var result: Set<UUID> = []
        func collect(_ link: Link) {
            result.insert(link.id)
            link.subLinks.forEach(collect)
        }
        collect(root)
        return result
    }

    private func findLink(_ id: UUID, in links: [Link]) -> Link? {
        for link in links {
            if link.id == id { return link }
            if let found = findLink(id, in: link.subLinks) { return found }
        }
        return nil
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

/// 브라우저 탭(URL) 외부 드롭을 캔버스에서 받는다. DropInfo.location은 CanvasContentView의
/// 로컬 좌표(=콘텐츠 좌표)라 layout.positions와 같은 좌표계다.
struct CanvasDropDelegate: DropDelegate {
    let page: Page
    let layout: TreeLayoutResult
    @Binding var dropTargetID: UUID?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropTargetID = canvasNodeID(at: info.location, in: layout, excluding: nil)
        return DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) { dropTargetID = nil }

    func performDrop(info: DropInfo) -> Bool {
        let parentID = canvasNodeID(at: info.location, in: layout, excluding: nil)
        let providers = info.itemProviders(for: [.url, .text])
        let page = self.page
        DroppedURLLoader.load(from: providers) { urls in
            guard !urls.isEmpty else { return }
            let parent = parentID.flatMap { canvasFindLink($0, in: page.links) }
            let count = LinkIngest.addLinks(urls, to: page, parent: parent)
            AppState.shared.lastIngest = IngestReceipt(count: count, targetName: page.title)
        }
        dropTargetID = nil
        return !providers.isEmpty
    }
}
