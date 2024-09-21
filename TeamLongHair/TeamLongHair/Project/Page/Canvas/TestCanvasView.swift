//
//  TestCancasView.swift
//  TeamLongHair
//
//  Created by Damin on 9/14/24.
//

import SwiftUI

struct TestCanvasView: View {
    @State private var nodes: [Node] = [
        Node(position: CGPoint(x: 200, y: 200)),
                Node(position: CGPoint(x: 300, y: 200)),
                Node(position: CGPoint(x: 400, y: 200))
    ]
    @State private var connections: [Connection] = []
    @State private var totalZoom = 1.0
    @State private var currentZoom = 0.0
    @State private var zoomableOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.green
            ZoomableView(currentZoom: $currentZoom,totalZoom: $totalZoom, zoomableOffset: $zoomableOffset) {
                GeometryReader { geometry in
                    ZStack {
                        Color.white
                        // 연결선
                        ForEach(connections) { connection in
                            ConnectionLine(from: connection.from.position, to: connection.to.position)
                        }
                        HStack {
                            // 노드
                            ForEach(nodes) { node in
                                NodeView(node: node, totalZoom: $totalZoom, currentZoom: $currentZoom)
                                // 드래그 가능
                                    .draggable(node.id.uuidString)
                                // 드롭 가능
                                    .dropDestination(for: String.self) { dropNodeIDStrings, _ in
                                        if let droppedIDString = dropNodeIDStrings.first,
                                           let fromNode = nodes.first(where: { $0.id.uuidString == droppedIDString }),
                                           fromNode.id != node.id {
                                            addConnection(from: fromNode, to: node)
                                            return true
                                        }
                                        return false
                                    }
                            }
                        }
                        
                    }
                    
                    VStack {
                        Spacer()
                        Button(action: {
                            addRandomNode(in: geometry.size)
                        }) {
                            Text("Add Random Node")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            
        }
    }
    
    private func addConnection(from: Node, to: Node) {
        let newConnection = Connection(from: from, to: to)
        if !connections.contains(where: { $0.from.id == from.id && $0.to.id == to.id }) {
            connections.append(newConnection)
        }
    }
    
    private func addRandomNode(in size: CGSize) {
        let randomX = CGFloat.random(in: 0...size.width)
        let randomY = CGFloat.random(in: 0...size.height)
        let newNode = Node(position: CGPoint(x: randomX, y: randomY))
        nodes.append(newNode)
    }
}

struct NodeView: View {
    let node: Node
    @Binding var totalZoom: Double
    @Binding var currentZoom: Double
    var body: some View {
            Circle()
                .fill(Color.blue)
                .frame(width: 50 * (totalZoom + currentZoom), height: 50 * (totalZoom + currentZoom))
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
            content
                .scaleEffect(totalZoom + currentZoom)
                .offset(zoomableOffset)
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

struct Node: Identifiable {
    let id = UUID()
    var position: CGPoint
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
