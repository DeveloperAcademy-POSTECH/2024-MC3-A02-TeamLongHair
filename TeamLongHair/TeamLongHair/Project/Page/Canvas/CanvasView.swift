//
//  CanvasView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI
import SwiftData

struct CanvasView: View {
    // 컴포넌트 크기
    @State var sizeOfNode: CGFloat = 100
    // 줌값 유지를 위한 변수
    @State var lastScaleValue: CGFloat = 1.0
    @Binding var selectedPage: Page
    @Environment(\.modelContext) var context
    @State var draggedLink: Link?
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // 수평으로 한 번 그려주기
                ForEach(Array(zip(selectedPage.links.indices, $selectedPage.links)), id: \.0) { index, $link in
                    HStack(alignment: .top, spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            // 맨 위 가로선 그리는 방법 변경
                            // 왜냐하면 하위 링크가 늘어났을 때 선이 끝까지 안 그려지는 버그가 있었어서
                            if let last = selectedPage.links.last {
                                if last.id != $link.id {
                                    VStack(spacing: 0) {
                                        Spacer()
                                            .frame(height: 118 * (sizeOfNode / 244) * 0.5)
                                        Rectangle()
                                            .frame(minWidth: 244 * 2 * (sizeOfNode / 244), maxWidth: .infinity, maxHeight: 1)
                                    }
                                    .dropDestination(for: String.self) { items, location in
                                        moveLink(links: &selectedPage.links, id: items.first!)
                                        if let draggedLink {
                                            selectedPage.links.insert(draggedLink, at: index)
                                        }
                                        return true
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                // 디버깅용 버튼
//                                Button("add") {
//                                    $link.subLinks.wrappedValue.append(.init(detail: .init(URL: "", title: "1")))
//                                }
//                                Button("del") {
//                                    $link.subLinks.wrappedValue.removeLast()
//                                }
                                LinkNode(sizeOfNode: $sizeOfNode, link: $link)
                                    .draggable($link.id.uuidString)
                                    .dropDestination(for: String.self) { items, location in
                                        moveLink(links: &selectedPage.links, id: items.first!)
                                        if let draggedLink {
                                            $link.subLinks.wrappedValue.append(draggedLink)
                                        }
                                        return true
                                    }
                                // 수직으로 반복해서 그려주기
                                if !$link.subLinks.wrappedValue.isEmpty {
                                    DrawNodes(sizeOfNode: $sizeOfNode, selectedPage: $selectedPage, links: $link.subLinks)
                                }
                            }
                        }
                    }
                }
            }
            // 창을 늘려도 그래프가 유지됐으면 좋겠어서 고정
            .fixedSize()
            .padding(50)
        }
        // 이거 하면 뷰가 그려지지 않은 빈 공간에서도 제스처를 인식한대요
        .contentShape(Rectangle())
        // 줌 제스처
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    let delta = value.magnification / self.lastScaleValue
                    self.lastScaleValue = value.magnification
                    let newScale = self.sizeOfNode * delta
                    
                    if newScale < 500 && newScale > 25 {
                        self.sizeOfNode = newScale
                    }
                    
                }
                .onEnded { val in
                    self.lastScaleValue = 1.0
                }
        )
        // 줌 비율
        .overlay(alignment: .bottomTrailing) {
            HStack {
                // 디버깅용 버튼
//                Button("add") {
//                    selectedPage.links.append(.init(detail: .init(URL: "", title: "0")))
//                    try? context.save()
//
//                }
//                
//                Button("del") {
//                    selectedPage.links.removeLast()
//                    try? context.save()
//                }
                Text(Image(systemName: "plus.magnifyingglass"))
                Text("\(sizeOfNode * (1 / 50) * 100)%")
            }
        }
    }
    
    func moveLink(links: inout [Link], id: String) {
        for link in links {
            if link.id.uuidString == id {
                draggedLink = link
                links.removeAll(where: { $0.id.uuidString == id })
            }
            moveLink(links: &link.subLinks, id: id)
        }
    }
}

struct DrawNodes: View {
    @Binding var sizeOfNode: CGFloat

    @Binding var selectedPage: Page
    
    @Binding var links: [Link]
    
    @State var draggedLink: Link?
    
    var body: some View {
        ForEach(Array(zip(links.indices, $links)), id: \.0) { index, $link in
            HStack(alignment: .top, spacing: 0) {
                ZStack {
                    Spacer()
                        .frame(width:  (122 + 32)  * (sizeOfNode / 244), height: (118 + 120) * (sizeOfNode / 244))
                    HStack {
                        Spacer()
                            .frame(width: 244 * (sizeOfNode / 244) / 2)
                        Rectangle()
                            .frame(width: 32 * (sizeOfNode / 244), height: 1)
                    }
                }
                .dropDestination(for: String.self) { items, location in
                    moveLink(links: &selectedPage.links, id: items.first!)
                    if let draggedLink {
                        links.insert(draggedLink, at: index)
                    }
                    return true
                }
                VStack(alignment: .leading, spacing: 0) {
                    // 디버깅용 버튼
//                    Button("add") {
//                        $link.subLinks.wrappedValue.append(.init(detail: .init(URL: "", title: "-1")))
//                    }
//                    Button("del") {
//                        $link.subLinks.wrappedValue.removeLast()
//                    }
                    LinkNode(sizeOfNode: $sizeOfNode, link: $link)
                        .padding(.top, 60 * (sizeOfNode / 244))
                        .padding(.trailing, 20 * (sizeOfNode / 244))
                        .draggable($link.id.uuidString)
                        .dropDestination(for: String.self) { items, location in
                            moveLink(links: &selectedPage.links, id: items.first!)
                            if let draggedLink {
                                $link.subLinks.wrappedValue.append(draggedLink)
                            }
                            return true
                        }
                    
                    if !$link.subLinks.wrappedValue.isEmpty {
                        DrawNodes(sizeOfNode: $sizeOfNode, selectedPage: $selectedPage, links: $link.subLinks)
                    }
                }
            }
            .overlay(alignment: .leading) {
                if link.id != $links.last?.id {
                    Spacer()
                        .frame(width: 244  * (sizeOfNode / 244))
                    Rectangle()
                        .frame(width: 1)
                } else {
                    Spacer()
                        .frame(width: 244  * (sizeOfNode / 244))
                    VStack {
                        Rectangle()
                            .frame(width: 1, height: ((118 / 2) + 60) * (sizeOfNode / 244))
                        Spacer()
                    }
                }
            }
        }
    }
    
    func moveLink(links: inout [Link], id: String) {
        for link in links {
            if link.id.uuidString == id {
                draggedLink = link
                links.removeAll(where: { $0.id.uuidString == id })
            }
            moveLink(links: &link.subLinks, id: id)
        }
    }
    
}

//#Preview {
//    CanvasView()
//}
