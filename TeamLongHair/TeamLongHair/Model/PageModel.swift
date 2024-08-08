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
