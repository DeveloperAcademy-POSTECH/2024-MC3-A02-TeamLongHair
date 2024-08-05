//
//  CanvasView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftData
import SwiftUI

struct CanvasView: View {
    // 컴포넌트 크기
    @State var sizeOfNode: CGFloat = 180
    // 줌값 유지를 위한 변수
    @State var lastScaleValue: CGFloat = 1.0
    @Environment(\.modelContext) var context
    
    @Binding var selectedPage: Page
    @State var draggedLink: Link?
    @State var links: [Link] = []
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // 수평으로 한 번 그려주기
                ForEach(Array(zip(links.indices, $links)), id: \.0) { index, $link in
                    HStack(alignment: .top, spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            if link.id != links[links.count - 1].id {
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
                            VStack(alignment: .leading, spacing: 0) {
                                LinkNode(sizeOfNode: $sizeOfNode, link: $link)
                                    .draggable($link.id.uuidString)
                                    .dropDestination(for: String.self) { items, location in
                                        moveLink(links: &selectedPage.links, id: items.first!)
                                        if let draggedLink {
                                            link.subLinks.append(draggedLink)
                                        }
                                        return true
                                    }
                                // 수직으로 반복해서 그려주기
                                if !link.subLinks.isEmpty {
                                    @State var subLinks = link.subLinks.sorted(by: { $0.index < $1.index })
                                    
                                    DrawNodes(sizeOfNode: $sizeOfNode, selectedPage: $selectedPage, links: $subLinks)
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
                Button("add") {
                    selectedPage.links.append(.init(detail: .init(URL: "", title: "\(selectedPage.links.count)"), index: selectedPage.links.count))
                    try? context.save()

                }
                Button("del") {
                    selectedPage.links.removeAll(where: { $0 == links.last })
                    try? context.save()
                }
                Text(Image(systemName: "plus.magnifyingglass"))
                Text("\(sizeOfNode * (1 / 50) * 100)%")
            }
        }
        .background(.bgPrimary)
        .onAppear {
            links = selectedPage.links.sorted(by: { $0.index < $1.index })
        }
        .onChange(of: selectedPage.links) {
            links = selectedPage.links.sorted(by: { $0.index < $1.index })
        }
    }
    
    func moveLink(links: inout [Link], id: String) {
        for link in links {
            print(link.index)
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
