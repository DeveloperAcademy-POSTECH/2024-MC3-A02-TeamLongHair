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
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            ZoomableView {
                GeometryReader { geometry in
                    ZStack {
                        Color.white
                        ZStack {
                            // 연결선
                            ForEach(connections) { connection in
                                ConnectionLine(from: connection.from.position, to: connection.to.position)
                            }
                            
                            // 노드
                            ForEach(nodes) { node in
                                NodeView(node: node, onDragChanged: { newPosition in
                                    if let index = nodes.firstIndex(where: { $0.id == node.id }) {
                                        nodes[index].position = newPosition
                                    }
                                })
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


struct ZoomableView<Content: View>: View {
    let content: Content
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
//                SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale *= delta
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
        )
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

struct NodeView: View {
    let node: Node
    let onDragChanged: (CGPoint) -> Void
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 50, height: 50)
            .position(node.position)
    }
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
