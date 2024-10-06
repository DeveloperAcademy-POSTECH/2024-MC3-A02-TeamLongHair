//
//  TestCancasView.swift
//  TeamLongHair
//
//  Created by Damin on 9/14/24.
//

import SwiftUI

@Observable
class TestCanvasViewModel {
    var nodes: [Node] = [
        Node(),
        Node(),
        Node()
    ]
    
    func removeNode(droppedIDString: String, nodes: inout [Node]) -> Node? {
        for (idx, node) in nodes.enumerated() {
            if node.id.uuidString == droppedIDString {
                let dropNode = nodes.remove(at: idx)
                return dropNode
            } else if let dropNode = removeNode(droppedIDString: droppedIDString, nodes: &nodes[idx].subNodes) {
                return dropNode
            }
        }
        return nil  // 노드를 찾지 못했을 경우 nil 반환
    }
    
    func addNode(dropNode: Node, toNode: Node, toAddNodes: inout [Node]) {
//        for node in toAddNodes {
//            if node.id.uuidString == toNode.id.uuidString {
//                toAddNodes.append(dropNode)
//            } else {
//                addNode(dropNode: dropNode, toNode: toNode, toAddNodes: &toAddNodes)
//            }
//        }
        var isNodeAdded = false
        // 1차 노드에 넣었을때 2차로 들어감
        for (idx,node) in toAddNodes.enumerated() {
            if node.id.uuidString == toNode.id.uuidString {
                toAddNodes[idx].subNodes.append(dropNode)
                debugPrint("toNodeAddedName-1", toAddNodes[idx].title)
                debugPrint("dropNodeName", dropNode.title)
                isNodeAdded = true
            }
        }
        
        // 2차 노드에 넣었을때 3차로 들어감
        if !isNodeAdded {
            for idx in toAddNodes.indices {
                for (idx2,node2) in toAddNodes[idx].subNodes.enumerated() {
                    if node2.id.uuidString == toNode.id.uuidString {
                        toAddNodes[idx].subNodes[idx2].subNodes.append(dropNode)
                        debugPrint("toNodeAddedName-2", toAddNodes[idx])
                        debugPrint("dropNodeName", dropNode.title)
                        isNodeAdded = true
                    }
                }
            }
        }
    }
}

struct TestCanvasView: View {
    @State private var canvasVM = TestCanvasViewModel()
    @State private var connections: [Connection] = []
    @State private var totalZoom = 1.0
    @State private var currentZoom = 0.0
    @State private var zoomableOffset: CGSize = .zero
        
    // 그리드 항목의 높이를 정의
    let gridItems = [GridItem(.fixed(100))]  // 고정된 높이의 그리드
    @State private var maxVGridHeight: CGFloat = 100
    var body: some View {
        ZStack {
            Color.green
            ZoomableView(currentZoom: $currentZoom,totalZoom: $totalZoom, zoomableOffset: $zoomableOffset) {
                ZStack {
                    Color.white
                        GeometryReader { geo in
                            LazyHGrid(rows: gridItems) {
                                // 노드
                                ForEach(canvasVM.nodes, id: \.id) { toNode in
                                    VStack(spacing: 0) {
                                        let nodeSize = calculateNodeSize(containerWidth: geo.size.width, numberOfNodes: canvasVM.nodes.count)
                                        GeometryReader { vgrdiGeo in
                                            makeLazyVGrid(toNode: toNode, nodeSize: nodeSize)
                                                .onAppear {
                                                    maxVGridHeight = maxVGridHeight < vgrdiGeo.size.height ? vgrdiGeo.size.height : maxVGridHeight
                                                }
                                        }
                                    }
                                    .frame(minWidth: 100, minHeight: maxVGridHeight)
                                    .background(.blue)
                                }
                            }
                            //LazyHGrid
                            .background(.green)
                        
                       
                    }
      
                    
                }
                
                
                VStack {
                    Spacer()
                    Button{
                        addRandomNode()
                    }label:{
                        Text("Add Random Node")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .contentShape(Rectangle())
            
        }
    }
    
    @ViewBuilder
    private func makeLazyVGrid(toNode: Node, nodeSize: CGFloat) -> some View {
        // V1
        LazyVGrid(columns: gridItems) {
            NodeView(node: toNode, nodeSize: nodeSize, canvasVM: canvasVM, totalZoom: $totalZoom, currentZoom: $currentZoom)
            
            // 노드의 하위 노드들도 동일한 그리드로 표시
            if !toNode.subNodes.isEmpty {
                // V2
                LazyVGrid(columns: gridItems) {
                    ForEach(toNode.subNodes, id: \.id) { childNode in
                        NodeView(node: childNode, nodeSize: nodeSize, canvasVM: canvasVM, totalZoom: $totalZoom, currentZoom: $currentZoom)
                        
                        if !childNode.subNodes.isEmpty {
                            // V3
                            LazyVGrid(columns: gridItems) {
                                ForEach(childNode.subNodes, id: \.id) { childNode2 in
                                    NodeView(node: childNode2, nodeSize: nodeSize, canvasVM: canvasVM, totalZoom: $totalZoom, currentZoom: $currentZoom)
                                }
                            }
                            //VGrid-3
                            .background(.cyan)
                        }
                    }
                }
                //VGrid-2
                .background(.red)
            }
            
        }
        //VGrid-1
        .background(.orange)
        .onAppear {
            debugPrint("toNode", toNode.title)
        }
    }
    
    private func calculateNodeSize(containerWidth: CGFloat, numberOfNodes: Int) -> CGFloat {
        let baseSize: CGFloat = 50.0  // 노드의 기본 크기
        let maxVisibleNodes = Int(containerWidth / (baseSize + 20))  // 화면에 들어갈 수 있는 최대 노드 수
        let scaleFactor = min(1.0, CGFloat(maxVisibleNodes) / CGFloat(numberOfNodes))
        let nodeSize = baseSize * scaleFactor
        return nodeSize
    }
    
    private func addConnection(from: Node, to: Node) {
        let newConnection = Connection(from: from, to: to)
        if !connections.contains(where: { $0.from.id == from.id && $0.to.id == to.id }) {
            connections.append(newConnection)
        }
    }
    
    private func addRandomNode() {
        let newNode = Node()
        canvasVM.nodes.append(newNode)
    }
}

struct NodeView: View {
    var node: Node
    let nodeSize: CGFloat
    @Bindable var canvasVM: TestCanvasViewModel
    @Binding var totalZoom: Double
    @Binding var currentZoom: Double
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .overlay {
                Text(node.title)
                    .font(.caption)
                    .foregroundStyle(.black)
            }
            .frame(width: nodeSize * (totalZoom + currentZoom), height: nodeSize * (totalZoom + currentZoom))
            .background(.yellow)
        // 드래그 가능
            .draggable(node.id.uuidString) {
                Circle()
                    .fill(.blue)
                    .frame(width: 50*totalZoom, height: 50*totalZoom)
                    .scaleEffect(totalZoom)
                // 이게 있어야 줌인 줌아웃에 맞게 preview 크기 동적 변경 가능
                    .containerRelativeFrame(.horizontal)
                    .containerRelativeFrame(.vertical)
            }
        // 드롭 가능
            .dropDestination(for: String.self) { dropNodeIDStrings, _ in
                if let droppedIDString = dropNodeIDStrings.first {
                    let destinationNode = node
                    if droppedIDString != destinationNode.id.uuidString {
                        guard let dropNode = canvasVM.removeNode(droppedIDString: droppedIDString, nodes: &canvasVM.nodes) else {
                            return false
                        }
                        debugPrint("droppedIDString",droppedIDString)
                        debugPrint("destinationNode",destinationNode.id.uuidString)
                        
                        
                        canvasVM.addNode(dropNode: dropNode, toNode: node, toAddNodes: &canvasVM.nodes)
                    }
                    return true
                }
                return false
            }
    }
}


struct ZoomableView<Content: View>: View {
    let content: Content
    @State private var lastOffset: CGSize = .zero
    
    // 최소, 최대 스케일 값 설정
    let minScale: CGFloat = 1.0
    let maxScale: CGFloat = 5.0
    @Binding var currentZoom: Double
    @Binding var totalZoom: Double
    @Binding var zoomableOffset: CGSize
    
    init(currentZoom: Binding<Double>, totalZoom: Binding<Double>, zoomableOffset: Binding<CGSize>, @ViewBuilder content: () -> Content) {
        self._currentZoom = currentZoom
        self._totalZoom = totalZoom
        self._zoomableOffset = zoomableOffset
        self.content = content()
    }
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let scale = totalZoom + currentZoom
            ZStack {
                content
                    .scaleEffect(scale)
                    .frame(width: size.width, height: size.height)
                //                    .offset(x: zoomableOffset.width + (size.width * (scale - 1)) / 2, y: zoomableOffset.height + (size.height * (scale - 1)) / 2)
                    .offset(x: zoomableOffset.width, y: zoomableOffset.height)
            }
            
            .gesture(
                SimultaneousGesture(
                    // MagnifyGesture for Zoom
                    MagnifyGesture()
                        .onChanged { value in
                            let tempCurrentZoom = value.magnification - 1
                            if (tempCurrentZoom + totalZoom) > 0.95 {
                                currentZoom = tempCurrentZoom
                            }
                        }
                        .onEnded { value in
                            let previousZoom = totalZoom
                            let newTotalZoom = totalZoom + currentZoom
                            totalZoom = min(max(newTotalZoom, minScale), maxScale)
                            currentZoom = 0
                            
                            // 축소 시 오프셋 비율 조정
                            let scaleRatio = totalZoom / previousZoom
                            let newOffset = CGSize(width: zoomableOffset.width * scaleRatio, height: zoomableOffset.height * scaleRatio)
                            
                            // 축소되면 offset을 재조정하여 화면 밖으로 나가지 않도록 함
                            zoomableOffset = calculateLimitedOffset(geoSize: size, newOffset: newOffset)
                            lastOffset = zoomableOffset
                        },
                    
                    // DragGesture for Panning
                    DragGesture()
                        .onChanged { value in
                            // 새로운 offset 계산 (현재 드래그 위치 + 이전 드래그 위치)
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            // offset을 현재 줌에 맞게 적용
                            zoomableOffset = calculateLimitedOffset(geoSize: geo.size, newOffset: newOffset)
                        }
                        .onEnded { value in
                            lastOffset = zoomableOffset
                        }
                )
            )
        }
    }
    
    private func calculateLimitedOffset(geoSize: CGSize, newOffset: CGSize) -> CGSize {
        // 줌을 반영한 크기 계산
        let scaledWidth = geoSize.width * totalZoom
        let scaledHeight = geoSize.height * totalZoom
        
        // 줌을 적용한 화면 밖으로 나가지 않도록 최대/최소 오프셋 계산
        let maxOffsetX = (scaledWidth - geoSize.width) / 2
        let maxOffsetY = (scaledHeight - geoSize.height) / 2
        
        // 제한된 오프셋 계산 (노드들이 화면 밖으로 나가지 않도록)
        let limitedOffsetX = max(min(newOffset.width, maxOffsetX), -maxOffsetX)
        let limitedOffsetY = max(min(newOffset.height, maxOffsetY), -maxOffsetY)
        
        return CGSize(width: limitedOffsetX, height: limitedOffsetY)
    }
}

struct Node: Identifiable, Equatable {
    var id: UUID
    var title: String
    var subNodes: [Node]
        
    init(id: UUID = UUID(), title: String = "", subNodes: [Node] = []) {
        self.id = id
        self.title = "\(id.uuidString.prefix(3))"
        self.subNodes = subNodes
    }
    
}

struct Connection: Identifiable {
    let id = UUID()
    let from: Node
    let to: Node
}

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
    }
}


#Preview {
    TestCanvasView()
}
