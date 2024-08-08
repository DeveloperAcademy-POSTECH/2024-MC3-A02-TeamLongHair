//
//  CanvasView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftData
import SwiftUI

struct CanvasView: View {
    @Binding var selectedPage: Page
    @Binding var selectedLink: Link?
    
    // 컴포넌트 크기
    @State var sizeOfNode: CGFloat = 180
    // 줌값 유지를 위한 변수
    @State var lastScaleValue: CGFloat = 1.0
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
                                    ZStack {
                                        Spacer()
                                            .frame(height: 118 * (sizeOfNode / 244))
                                        Rectangle()
                                            .frame(minWidth: 244 * 2 * (sizeOfNode / 244), maxWidth: .infinity, maxHeight: 1)
                                            .foregroundStyle(.gray700)
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
                                if link.id == selectedLink?.id {
                                    LinkNode(sizeOfNode: $sizeOfNode, link: $link, isSelected: true)
                                        .onTapGesture {
                                            selectedLink = link
                                        }
                                        .draggable($link.id.uuidString)
                                        .dropDestination(for: String.self) { items, location in
                                            moveLink(links: &selectedPage.links, id: items.first!)
                                            if let draggedLink {
                                                $link.subLinks.wrappedValue.append(draggedLink)
                                            }
                                            return true
                                        }
                                } else {
                                    LinkNode(sizeOfNode: $sizeOfNode, link: $link, isSelected: false)
                                        .onTapGesture {
                                            selectedLink = link
                                        }
                                        .draggable($link.id.uuidString)
                                        .dropDestination(for: String.self) { items, location in
                                            moveLink(links: &selectedPage.links, id: items.first!)
                                            if let draggedLink {
                                                $link.subLinks.wrappedValue.append(draggedLink)
                                            }
                                            return true
                                        }
                                }
                                // 수직으로 반복해서 그려주기
                                if !$link.subLinks.wrappedValue.isEmpty {
                                    DrawNodes(sizeOfNode: $sizeOfNode, selectedPage: $selectedPage, links: $link.subLinks, selectedLink: $selectedLink)
                                }
                            }
                        }
                    }
                }
            }
            // 창을 늘려도 그래프가 유지됐으면 좋겠어서 고정
            .fixedSize()
            .padding(150)
        }
        .background(.canvas)
        // 이거 하면 뷰가 그려지지 않은 빈 공간에서도 제스처를 인식한대요
        .contentShape(Rectangle())
        // 줌 제스처
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    let delta = value.magnification / self.lastScaleValue
                    self.lastScaleValue = value.magnification
                    let newScale = self.sizeOfNode * delta
                    
                    if newScale < 540 && newScale > 90 {
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
                Text(Image(systemName: "plus.magnifyingglass"))
                Text("\(sizeOfNode * (1 / 180) * 100)%")
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
