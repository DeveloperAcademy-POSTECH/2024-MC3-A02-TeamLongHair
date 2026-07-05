//
//  PageModel.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import Foundation
import SwiftData

@Model
final class Page {
    @Attribute(.unique) var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade) var links: [Link] // page 삭제하면, 가지고 있던 link 객체 전부 삭제.

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.links = []
    }

    func updatePageTitle(newTitle: String) {
        self.title = newTitle
    }
}

extension Page {
    var sortedLinks: [Link] {
        links.sorted { $0.sortIndex < $1.sortIndex }
    }

    var layoutRoots: [LayoutNode] {
        sortedLinks.map(\.layoutNode)
    }

    /// 정렬된 DFS 순서로 페이지의 모든 링크 평탄화
    var allLinks: [Link] {
        func flatten(_ links: [Link]) -> [Link] {
            links.flatMap { [$0] + flatten($0.sortedSubLinks) }
        }
        return flatten(sortedLinks)
    }
}
