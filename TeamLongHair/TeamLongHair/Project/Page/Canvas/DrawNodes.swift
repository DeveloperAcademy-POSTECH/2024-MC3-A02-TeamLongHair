//
//  DrawNodes.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 8/5/24.
//

import SwiftUI

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
