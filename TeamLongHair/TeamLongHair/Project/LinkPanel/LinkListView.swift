//
//  LinkListView.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 8/7/24.
//

import SwiftUI

struct LinkListView: View {
    // Link는 SwiftData @Model(참조 타입)이라 표시 목적의 순회는 Binding이 필요 없다.
    // 캔버스와 동일하게 sortIndex 기준(sortedSubLinks)으로 순서를 맞춘다.
    var links: [Link]
    @Binding var selectedLink: Link?
    /// 링크 클릭 시 캔버스가 해당 노드로 이동하도록 전달하는 요청.
    @Binding var focusRequest: UUID?
    /// 링크 삭제 핸들러(부모에서 페이지/컨텍스트를 알기에 위임한다).
    var onDelete: (Link) -> Void
    /// 트리 깊이(들여쓰기용). 노드 연결 구조를 사이드바에서도 계층으로 보여준다.
    var depth: Int = 0

    var body: some View {
        ForEach(links) { link in
            if selectedLink == link {
                linkListItemStyle(link, isSelected: true)
                    .buttonStyle(selectedButtonStyle())
            } else {
                linkListItemStyle(link, isSelected: false)
                    .buttonStyle(defaultButtonStyle())
            }
            if !link.subLinks.isEmpty {
                LinkListView(links: link.sortedSubLinks, selectedLink: $selectedLink, focusRequest: $focusRequest, onDelete: onDelete, depth: depth + 1)
            }
        }
    }

    private func linkListItemStyle(_ link: Link, isSelected: Bool) -> some View {
        Button {
            selectedLink = link
            focusRequest = link.id
        } label: {
            HStack(spacing: 6) {
                if depth > 0 {
                    // 계층 표시: 깊이만큼 들여쓰고 자식임을 나타내는 선/점
                    Rectangle()
                        .fill(.gray300)
                        .frame(width: 1, height: 14)
                        .padding(.leading, CGFloat(depth - 1) * 14 + 4)
                }
                Text(link.detail.title)
                    .foregroundColor(isSelected ? .lbPrimary : .lbTertiary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        }
        .contextMenu {
            Button { link.openInBrowser() } label: {
                Label("브라우저에서 열기", systemImage: "safari")
            }
            Button(role: .destructive) { onDelete(link) } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}
