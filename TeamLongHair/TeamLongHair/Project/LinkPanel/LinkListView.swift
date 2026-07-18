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
    /// 접힌(자식 숨김) 링크 id 집합. 최상위에서 소유하고 재귀로 공유한다.
    @Binding var collapsed: Set<UUID>
    /// 링크 삭제 핸들러(부모에서 페이지/컨텍스트를 알기에 위임한다).
    var onDelete: (Link) -> Void
    /// 트리 깊이(들여쓰기용).
    var depth: Int = 0

    private let indentPerLevel: CGFloat = 16

    var body: some View {
        ForEach(links) { link in
            row(link)
            if !link.subLinks.isEmpty && !collapsed.contains(link.id) {
                LinkListView(links: link.sortedSubLinks,
                             selectedLink: $selectedLink,
                             focusRequest: $focusRequest,
                             collapsed: $collapsed,
                             onDelete: onDelete,
                             depth: depth + 1)
            }
        }
    }

    @ViewBuilder
    private func row(_ link: Link) -> some View {
        let isSelected = selectedLink == link
        let hasChildren = !link.subLinks.isEmpty
        let isCollapsed = collapsed.contains(link.id)

        HStack(spacing: 4) {
            // 깊이만큼 들여쓰기
            if depth > 0 {
                Color.clear.frame(width: CGFloat(depth) * indentPerLevel)
            }
            // 자식이 있으면 접기/펼치기 삼각형, 없으면 정렬용 빈 칸
            if hasChildren {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.lbTertiary)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
                    .onTapGesture { toggle(link) }
            } else {
                Color.clear.frame(width: 16, height: 16)
            }

            Text(link.detail.title)
                .foregroundColor(isSelected ? .lbPrimary : .lbTertiary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6).fill(.bgSecondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedLink = link
            focusRequest = link.id
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

    private func toggle(_ link: Link) {
        if collapsed.contains(link.id) {
            collapsed.remove(link.id)
        } else {
            collapsed.insert(link.id)
        }
    }
}
