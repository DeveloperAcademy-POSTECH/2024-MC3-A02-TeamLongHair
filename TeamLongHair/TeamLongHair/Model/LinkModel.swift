//
//  LinkModel.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import SwiftData
import SwiftUI

@Model
final class Link {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var detail: LinkDetail // Link 객체 삭제하면, 가지고 있던 디테일 객체도 같이 삭제.
    @Relationship(deleteRule: .cascade) var subLinks: [Link] // link 객체 삭제하면, 가지고 있던 서브링크 객체도 같이 삭제.
    var sortIndex: Int = 0  // SwiftData to-many는 순서 미보장 → 형제 순서의 단일 출처

    init(detail: LinkDetail, sortIndex: Int = 0) {
        self.id = UUID()
        self.detail = detail
        self.subLinks = []
        self.sortIndex = sortIndex
    }
}

@Model
final class LinkDetail {
    var URL: String
    var title: String
    var tags: [String]
    var desc: String
    var color: IconColor
    var savedDate: Date = Date.now
    var pageDescription: String = ""
    @Attribute(.externalStorage) var faviconData: Data? = nil
    @Attribute(.externalStorage) var thumbnailData: Data? = nil

    init(URL: String, title: String) {
        self.URL = URL
        self.title = title
        self.tags = []
        self.desc = ""
        self.color = .gray
        self.savedDate = .now
    }
}

extension Link {
    var sortedSubLinks: [Link] {
        subLinks.sorted { $0.sortIndex < $1.sortIndex }
    }

    var layoutNode: LayoutNode {
        LayoutNode(id: id, children: sortedSubLinks.map(\.layoutNode))
    }
}
