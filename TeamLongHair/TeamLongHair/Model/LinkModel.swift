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
    
    init(detail: LinkDetail) {
        self.id = UUID()
        self.detail = detail
        self.subLinks = []
    }
}

@Model
final class LinkDetail {
    var URL: String
    var title: String
    var tags: [String]
    var desc: String
    var code: String
    var color: IconColor
    var icon: Icon
    
    init(URL: String, title: String) {
        self.URL = URL
        self.title = title
        self.tags = []
        self.desc = ""
        self.code = ""
        self.color = .gray
        self.icon = .Document
    }
}
